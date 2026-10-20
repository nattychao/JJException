# nattychao/JJException fork — 相对上游 0.2.13 的修复与优化

上游仓库：<https://github.com/jezzmemo/JJException>（最后发版 0.2.13，2022-12，之后无代码提交）
本 fork：<https://github.com/nattychao/JJException>（版本号 0.2.14）

本文件只记录**与上游源码的差异**和**为什么这样改**。每一条都对应上游源码里可以指到行的问题，
并在 iOS 18.6 / iOS 27.1 两个模拟器上实测过（见文末测试方法）。

---

## 0. 一句话概括

上游的守卫思路（在异常发生的那一刻拦下来、上报、让 App 继续跑）是有效的，但实现里有几类问题会让它
**在最需要它的时候失效**，甚至**自己成为崩溃源**：

- 整数回绕让越界检查失效（最严重：守卫以为拦住了，实际没拦住）
- 没有覆盖 `NSConstantArray`（现代数组字面量的真实运行时类）
- KVO 守卫在 iOS 18 上会双重释放 Foundation 的 `NSKeyValueObservationInfo`
- NSTimer 守卫改变所有权语义，破坏第三方 SDK
- 多次 `start/stop` 会把 swizzle 换回去，守卫静默失效
- 上报路径本身没有重入保护，可能在回调里递归到栈溢出

---

## 1. 崩溃 / 稳定性修复

### 1.1 Swizzle 核心：空指针、幂等、并发、类型编码

文件：`JJException/Source/Swizzle/NSObject+SwizzleHook.m`

| 上游问题 | 后果 | 本 fork 的改法 |
|---|---|---|
| `class_getClassMethod` / `class_getInstanceMethod` 返回 NULL 时直接 `method_getImplementation(originalMethod)` | 系统某次更新删掉任一 selector，**App 启动即崩** | 所有 Method / IMP / 类型编码先判空，缺失就安静跳过 |
| swizzle 没有幂等保护 | `stopGuardException` 后再 `startGuardException` 会**再交换一次**，等于把守卫换回去了。上游 issue #54 的"反复开关闪退"同源 | 用 `(Class, SEL)` 集合 + 递归锁保证**每个 selector 只交换一次** |
| `@synchronized(class)` 只保护了"检查 + 打标记"，真正的 swizzle 在锁外 | 两个线程同时给同一个类装 dealloc 钩子，第二个拿到的 old IMP 是第一个的钩子 → dealloc **递归调用自己 → 栈溢出** | 检查与交换整体加锁 |
| `class_addMethod(..., method_getTypeEncoding(dealloc))` 在 `dealloc == NULL` 分支传入 **NULL 类型编码** | 给没有自定义 dealloc 的类加了一个类型编码为空的方法，运行时行为未定义 | 回退到 `NSObject` 的 dealloc 类型编码；仍取不到就放弃 |
| 对类簇具体类 `class_replaceMethod` 时可能改到父类共享的 IMP | 会污染同族其他类 | 先 `class_addMethod` 给目标类一份自己的钩子，再做交换 |
| 先 swizzle 父类、再 swizzle 继承该方法的子类时，子类拿到的是父类**已换成钩子**的 IMP | 子类会被静默绕过（实测 hookCount=0），守卫对子类完全不生效 | 检测"本类未实现 + 祖先已 swizzle"时直接跳过，靠继承复用祖先的钩子；两种顺序都实测恰好调用 1 次 |
| `class_copyMethodList` 未判空就 `free` | 分配失败时 `free(NULL)`（无害但不严谨） | 判空后再释放 |

### 1.2 整数回绕：越界检查在最该生效时失效（最严重）

文件：`NSArray+ArrayHook.m`、`NSMutableArray+MutableArrayHook.m`、`NSString+StringHook.m`、
`NSMutableString+MutableStringHook.m`、`NSAttributedString+AttributedStringHook.m`、
`NSMutableAttributedString+MutableAttributedStringHook.m`（共 14 处）

上游写法：

```objc
if (range.location + range.length <= self.count) { ... }   // 无符号加法会回绕
```

`NSRange.location` 是 `NSUInteger`。`NSMakeRange(NSUIntegerMax - 1, 5)` 相加后回绕成 `3`，
对 count 为 3 的数组来说"检查通过"，于是**原样转发给 Foundation**：

- 数组：抛 `NSRangeException`，App 崩
- 字符串 `substringWithRange:`：只打一条系统警告，然后**返回一个错误的子串**（实测返回 `"w"`）——
  它不崩，但把脏数据交给了业务代码，比崩溃更难排查

修复：新增 `JJExceptionRange.h`，统一用"先比 location 再相减"：

```objc
static inline BOOL JJExceptionIsValidRange(NSRange range, NSUInteger length) {
    if (range.location == NSNotFound) return NO;
    if (range.location > length) return NO;
    return range.length <= (length - range.location);   // 不会下溢
}
```

### 1.3 数组字面量完全没有被守卫覆盖

文件：`NSArray+ArrayHook.m`

iOS 的数组字面量在**元素全是常量**时（`@[@"a", @"b"]`、`@[@1, @2]`）运行时类是
**`NSConstantArray`**，不是 `__NSArrayI`。上游只 hook 了 `__NSArray0/__NSArrayI/
__NSSingleObjectArrayI/__NSArrayI_Transfer/__NSFrozenArrayM/__NSArrayReversed`，**没有
`NSConstantArray`**，于是这类数组越界完全不拦（实测会抛 `NSRangeException`）。

修复：补上 `NSConstantArray` 的 `objectAtIndex:` / `objectAtIndexedSubscript:` / `subarrayWithRange:`。

同时删掉了对 `__NSCFArray` 的 8 行 swizzle：该类在现代运行时已不存在（CFArray 桥接回来实测是
`__NSArrayM`），这些调用是无效开销。

### 1.4 KVO 守卫：iOS 18 上双重释放 Foundation 的 observationInfo

文件：`NSObject+KVOCrash.m`（整文件重写）

崩溃栈（上游 issue #147，2025-04 提出，至今无回应）：

```
-[NSKeyValueObservationInfo dealloc]
-[NSObject(NSKeyValueObserverRegistration) _removeObserver:forProperty:]
-[NSObject removeObserver:forKeyPath:]
-[KVOObjectContainer cleanKVOData]
__jj_swizzleDeallocIfNeeded_block_invoke_3
_Block_release
```

根因：上游在**被观察者自己的 dealloc 里**回头调 Foundation 的 `removeObserver`。而 iOS 18 的
`NSKVONotifying_*` 把原类 dealloc 包在 `__NSKVOPerformWithDeallocatingObservable` 里执行，
这个临界区内 Foundation 正持有 observationInfo，再删一次就会重复释放，最后跳到空指针。

同版本里 `-[NSKeyValueObservance _initWithObserver:...]` 已经改用 `objc_initWeakOrNil`
弱存 observer（带 `_observerIsWeak` 标记），**observer 先死本来就不会崩**，所以这个守卫在
iOS 18+ 收益为零。

上游还有这些记账问题：

| 上游问题 | 后果 |
|---|---|
| "我是被观察者"和"我是观察者"两套容器用**同一个 associated object key** | 第二次 `objc_setAssociatedObject` 覆盖第一次，前一批登记丢失 |
| `observer` / `whichObject` 是 `assign` 裸指针（MRC） | 对象释放后是悬空指针，`if (item.observer)` 判断不出来 |
| `cleanKVOData` 持锁调用 Foundation | 回调里重入 KVO 会死锁 |
| 去重只看 `(observer, keyPath)`，丢掉 context；`remove...context:` 把 context 丢掉 | 同一 observer 用不同 context 注册两次时账本对不上 |
| 先清 `resultItem` 的字段再 `removeObject:` | hash 已变，删除失败，僵尸条目累积 |
| `NSMutableSet` 存记录 + `dispatch_semaphore` 保护 | 记录本身没实现可比较的 identity，去重靠 `isEqual` 语义，容易误判 |

本 fork 的改法：

- 一个容器，用 `observerRole` 标记角色，双角色不再互相覆盖
- observer / subject 都通过 `JJWeakObjectBox`（ARC 编译的小类）**弱持有**，对象死了自动变 nil
- 锁只保护账本，**绝不在持锁时调用 Foundation**
- iOS 18+ **不在被观察者 dealloc 里碰 Foundation**（交给系统）；iOS 15~17 保留清理
- 每次 add 成功后才记账，remove 精确消费一条，add/remove 严格配对
- 所有 Foundation 调用包 `@try`，失败走 `JJExceptionGuardKVOCrash` 上报而不是崩
- dealloc 里的清理全部 `@try` 包住，**dealloc 永不抛异常**

### 1.5 NSTimer 守卫：把泄漏包装成了"防崩溃"，并破坏第三方 SDK

文件：`NSTimer+CleanTimer.m`（整文件重写）

上游做法是用 `TimerObject` 顶替真实 target，并弱持有它。问题是：

- NSTimer 按文档**强持有 target 直到 invalidate**，所以"target 已释放还收到消息"这种崩溃
  **本来就不存在**；上游防的是一个不存在的问题
- 它实际做的是把强引用换成弱引用，把 retain cycle（泄漏）变成 **target 提前释放 + 定时器被静默
  invalidate**
- 第三方 SDK（极光等）的 timer target 往往只被 timer 自己持有，被这么一改就提前释放、周期任务停摆。
  上游注释里"极光一直有这个问题"，真正原因就在这里
- 只 hook 了 `scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:`，且
  `repeats:NO` 直接放行；block 版、`timerWithTimeInterval:+addTimer:forMode:`、Swift Timer 全部绕过
- `timer.target` 被换成 `TimerObject`，外部按原类型访问会 unrecognized selector
- 回调硬编码 `objc_msgSend(target, selector, _timer)`，零参数 selector 属未定义行为

本 fork 的改法：**保留 Foundation 的所有权语义**，只拦真正会崩的入参：

- `selector == NULL` → 实测在 `CFRunLoopTimerCreate` 里 **SIGBUS**，且此时还没有可捕获的 ObjC 栈
- `target` 不实现 selector → 第一次 fire 时 unrecognized selector
- `target == nil` → 不会崩但永远不触发，属于调用方 bug，只上报
- 额外补 hook 了 `timerWithTimeInterval:target:selector:userInfo:repeats:`

### 1.6 NSNotificationCenter 守卫：清错了对象

文件：`NSNotificationCenter+ClearNotification.m`

上游固定用 `[[NSNotificationCenter defaultCenter] removeObserver:...]`，不管 observer 实际注册在
哪个 center。注册在自定义 center 上的 observer 永远清不掉，同时 defaultCenter 被要求移除一个它
从未持有的 observer。

本 fork：弱持有**真实的 center**，从注册的那个实例移除。另外补了 nil observer / NULL selector 的
显式上报。

> 说明：iOS 9 起 NSNotificationCenter 弱引用 observer 并自动注销，所以这个守卫属于**纵深防御**，
> 不是 App 唯一的保命手段。测试里能证明的是它不再帮倒忙 + 能上报明显错误的注册。

### 1.7 UnrecognizedSelector：伪造返回签名的风险已记录并收敛

文件：`NSObject+UnrecognizedSelectorHook.m`

上游对任何未知 selector 都返回固定签名 `"v@:@"`（void 返回、一个对象参数），然后吞掉消息。
问题是它**没有约束返回类型**：调用方若期待 BOOL / double / 结构体，读到的是返回寄存器里的残留值。
实测 32 字节结构体返回时拿到 `0x00000001012b4360 …` 这类**未初始化栈内容**——静默的数据污染。

本 fork 的改动（这条是**收敛 + 注释**，不是根治，因为 ObjC 运行时无法得知不存在方法的真实签名）：

- 只对**没有自定义转发**的类接管（仍覆写 `methodSignatureForSelector:` 的类保留自己的契约），
  避免破坏 NSProxy 一类的自定义 forwarding
- 每次接管都上报，让未知 selector 出现在日志里而不是悄悄改变程序行为
- 文件头明确写下"返回值未定义，这类上报必须当作真 bug 修"

### 1.8 上报路径的重入保护

文件：`JJExceptionProxy.m`

上游的 `handleCrashException:` 会拼字符串、取调用栈、调业务 delegate。如果这些动作本身又触发了
另一个守卫（比如 delegate 里做了越界 substring），就会**无限递归到栈溢出**。

本 fork：用线程本地标记做重入保护，同一线程同一时刻只处理一条上报；delegate 调用包 `@try`，
delegate 抛异常不会把已恢复的异常变成新崩溃。

---

## 2. 行为修正（避免误报 / 误伤）

| 文件 | 上游行为 | 本 fork |
|---|---|---|
| `NSMutableDictionary+...` | `dict[key] = nil` 被当成错误上报 | 这是文档化的"删除"语义，改为放行；只拦 nil key |
| `NSMutableAttributedString+...` | 零长度 range 一律按越界处理 | Foundation 实测容忍 `{99,0}`，改为放行，避免误报 |
| `NSArray+...` `arrayWithObjects:count:` / `NSDictionary+...` | `id objs[cnt]` 是**零长度 VLA**（C 未定义行为） | 改用 32 元素栈缓冲，超过才 malloc，并检查 malloc 失败 |
| `NSArray+...` `subarrayWithRange:` 越界但 location 合法 | 静默截断，不上报 | 仍截断，但**上报**，否则调用方的 bug 永远看不见 |
| `NSAttributedString` / `NSMutableSet` / `NSMutableSet` swizzle 入口 | `[X new]` 探针实例泄漏 | 改用 `alloc/init` 或 `[NSMutableSet set]`，不再泄漏 |

---

## 3. 新增能力：运行时可开关

文件：`JJException.h`（公共 API）、`JJExceptionProxy.h/.m`（实现）

上游的 `startGuardException` / `stopGuardException` 只在"关→开"时重新 swizzle；swizzle 本身
又是交换 IMP，所以 stop→start 会把守卫换回去。而且**没有任何办法单独开关某一个 category**。

本 fork：

- 所有钩子**只装一次**，永不卸载
- 每个 hook 入口先查 `JJExceptionGuardEnabled(category)`
- 于是 `configExceptionCategory:` 和 `stop/startGuardException` **立即生效**，
  不需要重启，也不会出现"开关一次就把守卫弄丢"
- 公开两个查询入口：

```objc
BOOL on = [JJException isGuardCategoryEnabled:JJExceptionGuardArrayContainer];
// 钩子内部用的 C 版本，避免高频消息派发：
// BOOL JJExceptionGuardEnabled(JJExceptionGuardCategory category);
```

- `stopGuardException` 上的 `deprecated` 标记已移除：本 fork 修掉了上游 #54 的反复开关崩溃

> 注意：`stopGuardException` 之后调用非法 API 会真的崩——那是"关闭防护"的正确含义，
> 不要用它来做 A/B 对比中的"安全态"。

---

## 3.1 构建 / 集成层面的修正

| 项目 | 上游 | 本 fork |
|---|---|---|
| `s.ios.deployment_target` | `"8.0"` | `"15.0"`。Xcode 27 直接拒绝 8.0（"supported deployment target versions is 15.0 to 27.1.x"），集成阶段就构建失败 |
| `s.osx/watchos/tvos.deployment_target` | 都声明了 | 注释掉，只声明 iOS（本 fork 未在其他平台验证） |
| `s.homepage` / `s.source` | 指向上游 | 指向本 fork |
| `MRC` subspec 依赖 | 缺 `DeallocBlock` | 补上。`NSObject+KVOCrash.m` 以 MRC 编译，clang 禁止在 MRC 文件里写 `__weak`，所以弱引用要通过 ARC 编译的 `JJWeakObjectBox` 实现 |

---

## 4. 已验证内容

环境：iOS 18.6（iPhone 16 Pro 模拟器）、iOS 27.1（iPhone Duo 模拟器），Xcode 27，arm64。

### 4.1 逐 category 崩溃点对照（41 个用例，ON / OFF 各跑一遍）

| Category | 用例数 | 守卫 ON | 守卫 OFF |
|---|---|---|---|
| Array / Set | 11 | 全部拦截，进程存活 | 11 例全部抛异常 |
| Dictionary | 4 | 全部拦截 | 4 例全部抛异常 |
| String / AttributedString | 9 | 8 拦截 + 1 按 Foundation 语义放行 | 7 抛异常 + 2 按设计无害 |
| Unrecognized Selector | 4 | 全部拦截 | 4 例全部抛异常 |
| KVO | 5 | 2 拦截 + 3 按设计无害 | 1 抛异常 + 4 无害 |
| NSTimer | 4 | 3 拦截 + 1 按设计无害 | 1 进程直接死（SIGBUS）+ 3 无害 |
| NotificationCenter | 4 | 2 拦截 + 2 按设计无害 | 全部无害（系统已弱引用 observer） |

汇总（两个系统结果完全一致）：**守卫 ON 时 41/41 进程存活，0 例异常逃逸；守卫 OFF 时 28 例
崩溃或抛异常、13 例按设计无害。**

### 4.2 压力测试（两系统各跑一遍，全部 PASS）

- 20 线程 × 300 次非法调用，同时并发重配 category 12 次
- 50 次 `stop/start` 循环后守卫仍然有效（上游会在这里静默失效）
- 上报回调内部再次触发守卫：正确终止，不递归
- 12 线程 × 400 次容器滥用 + 字符串越界
- 8 线程 × 200 组 KVO 配对，交替让 observer / subject 先死
- 200 个 timer 创建 + 200 次 NULL selector 尝试
- 200 元素大容器的边界路径
- swizzle 父子类两种顺序（父先/子先），验证钩子对两者都恰好生效一次

### 4.3 为什么没有直接换成 RSSwizzle / Aspects

两个库都很成熟，但都不适合替代这里的 swizzle 核心。

**Aspects 1.4.1**：机制是给**每个实例**动态生成子类（`Xxx_Aspects_`）再替换 `class`，
属于 AOP hook 一个"调用点"，不是替换类方法本身。用它做全局守卫会给每个被 hook 的实例
建一个子类，内存和 `isKindOfClass:` 语义都会变，而且它对 `dealloc` 这类
"任何类都可能被 hook"的场景不适用。上游也已归档（archived），不适合作为新依赖。

**RSSwizzle 0.1.0**：核心 `swizzle()` 与我们的实现几乎是同构的（同样是
`imp_implementationWithBlock` + `class_replaceMethod` + 延迟取 original IMP），
没有额外能力可以"拿过来"。具体差异：

| 项 | RSSwizzle 0.1.0 | 本 fork |
|---|---|---|
| 并发锁 | `OSSpinLock`，iOS 10 起已废弃（编译器直接告警），且有优先级反转问题 | `NSRecursiveLock` |
| 父子类重复 hook | 提供 `RSSwizzleModeOncePerClassAndSuperclasses`，但**需要调用方主动指定**，默认 `Always` 会重复 hook | 自动识别祖先已 swizzle，无需参数 |
| 空实现类型检查 | 在 `NS_BLOCK_ASSERTIONS` 下**整段编译掉**，Release 不校验 | 显式判空，Release 同样生效 |
| 使用方式 | 宏 + 工厂 block，每个 hook 要写一遍完整函数签名 | 我们的钩子内部用 `objc_msgSend` 转发，一套模式覆盖所有 shape |
| 维护状态 | 最后提交 2019-09，Podfile 锁 0.1.0 | 本仓库 |

结论：**没有可搬的收益，还会引入一个新的停更依赖和一套基于已废弃 API 的锁。**
上面表格里唯一有价值的那条（父子类顺序），已经用自动化的方式补进了本 fork，
并用 demo 的压力测试覆盖（父先 / 子先两种顺序，各自必须恰好调用 1 次）。

---

## 5. 已知限制（不打算"修"的）

1. **UnrecognizedSelector 的返回值**：运行时无法得知不存在方法的真实签名，大结构体返回值仍是
   未定义内容。守卫只保证进程存活并上报。这类上报必须当作真 bug 处理。
2. **`stopGuardException` 之后就是原始 Foundation 行为**，非法调用会崩。这是语义，不是缺陷。
3. **KVO 守卫在 iOS 15~17 会安装 dealloc 钩子**（因为那些系统仍需在 dealloc 里清理）；
   iOS 18+ 完全跳过 dealloc 钩子，避免 #147。
4. **`NSConstantArray` 的补充只覆盖不可变字面量数组**；`@[...]` 里含变量时仍是
   `__NSArrayI/__NSSingleObjectArrayI`，上游已覆盖。

---

## 6. 如何自己复现验证

Demo 工程在桌面 `JJExceptionDemo/`（Objective-C，最低 iOS 15，直接引用本 fork 源码，
MRC 文件带 `-fno-objc-arc`，与 podspec 的 ARC 划分一致）。

```bash
# 全量跑一遍每个 category（打印 AUTOTEST 逐条结果）
xcrun simctl launch --console-pty <UDID> com.nattychao.JJExceptionDemo -JJAutoTest

# 单条用例，守卫开 / 关（OFF 可能杀死进程，属预期）
xcrun simctl launch --console-pty <UDID> com.nattychao.JJExceptionDemo -JJAutoTestOne 7
xcrun simctl launch --console-pty <UDID> com.nattychao.JJExceptionDemo -JJAutoTestOff 7

# 压力测试
xcrun simctl launch --console-pty <UDID> com.nattychao.JJExceptionDemo -JJStressTest
```

UI 里每个 category 一个开关，点任意用例会弹窗显示守卫实际拦到了什么（完整调用栈在控制台）。
