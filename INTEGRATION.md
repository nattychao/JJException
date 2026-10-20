# 接入 Yehwang iOS 项目

本 fork 与上游 0.2.13 的 API 完全兼容：现有 `AppDelegate+AvoidCrash.m` 一行都不用改
就能编译通过。下面是最小改动和最稳妥的接入顺序。

---

## 一、最小接入（1 处改动）

### Podfile

```ruby
# 原来：
# pod 'JJException', '~> 0.2.13'

pod 'JJException', :git => 'https://github.com/nattychao/JJException', :branch => 'master'
```

然后：

```bash
pod install
```

> 建议同时把部署目标确认在 15.0：podspec 里的 `ios.deployment_target` 已从 8.0 提到 15.0，
> Xcode 27 不接受更低的值。

---

## 二、配置层面的三个决定

`AppDelegate+AvoidCrash.m` 里的 `JJExceptionConfig` **不需要改**即可运行。下面三项是
可选的增量，按需决定。

### 1. 要不要开 KVC 守卫（推荐开）

这是本 fork 新增的 category（`JJExceptionGuardKVCCrash`），上游完全没有。它覆盖：

- `setValue:forKey:` nil key / 不存在的属性
- `setValue:forKeyPath:` nil keyPath
- `setValuesForKeysWithDictionary:` 含未知 key
- 字典 `setValue:forKey:` nil key

项目里 `setValue:forKey:` 有 39 处调用（绝大多数是给 `NSMutableURLRequest`
设 header，属于合法用法，守卫不会误报）。这类崩溃在 KVC 使用较多的页面很常见。

开启方式：在现有 category 组合上或一个 `JJExceptionGuardKVCCrash`：

```objc
JJExceptionGuardCategory category = JJExceptionGuardUnrecognizedSelector
    | JJExceptionGuardDictionaryContainer
    | JJExceptionGuardArrayContainer
    | JJExceptionGuardNSNotificationCenter
    | JJExceptionGuardNSStringContainer
    | JJExceptionGuardKVCCrash;      // ← 新增
```

同时建议在 `nameForGuardCategory:` 里补一条，让 Crashlytics 分组可读：

```objc
case JJExceptionGuardKVCCrash:              return @"KVCCrash";
```

### 2. KVO 守卫的门控可以保留

`AppDelegate+AvoidCrash.m` 现在这段：

```objc
if (@available(iOS 18.0, *)) {
    // iOS18+：不加入该 category
} else {
    category |= JJExceptionGuardKVOCrash;
}
```

**建议原样保留。** fork 里已经修掉了 iOS 18 双重释放 `NSKeyValueObservationInfo`
的问题（issue #147），理论上可以全系统开启；但你们线上 iOS 18+ 用户占绝大多数，
保持现状的收益是：确保 fork 新旧行为在这部分**完全一致**，把回归面压到最小。

### 3. NSTimer 守卫继续关闭

`AppDelegate+AvoidCrash.m` 里那一大段注释已经写清楚原因，fork 也把实现重写成了
"只校验入参、不改所有权语义"。但它对你们**没有收益**（原库那版只会破坏 SDK），
继续不开。

---

## 三、接入顺序建议（降低回归风险）

考虑到原库线上稳定运行多年，建议分两步，而不是一次性替换所有 category。

### 第一步：只换库，配置不变

- 改 Podfile + `pod install`
- `JJExceptionConfig` 一个字都不改（Array / Dictionary / String / UnrecognizedSelector /
  NotificationCenter，KVO 仅 18 以下，NSTimer 关闭）
- 这一步的差异全部是**内部实现修复**：
  - range 回绕（14 处）
  - `NSConstantArray` 覆盖
  - `CFSet` / `NSCountedSet` 覆盖
  - swizzle 空指针 / 幂等 / 并发
  - 通知中心清错对象
  - `@try` 兜底
- 观察一两个版本，看 Crashlytics 里 `com.Yehwang.JJException` 这个 domain 的
  non-fatal 有没有异常变化

### 第二步：按需开启 KVC

- 加 `JJExceptionGuardKVCCrash`
- 补 `nameForGuardCategory:` 的分支
- 观察 KVC 类 non-fatal 的量

---

## 四、验证清单

接入后建议在测试机上确认这几件事（都不需要额外写代码）：

| 检查项 | 预期 |
|---|---|
| 冷启动 | 不崩（这是最重要的一条；fork 已验证部分链接场景也不崩） |
| 数组越界日志 | Crashlytics 里能看到，且 `Error Place:` 指出 App 内的方法名 |
| `nameForGuardCategory:` | 每个 category 都有可读名字，没有落到 `Unknown` |
| 关闭守卫后的行为 | 非法调用照常崩溃（这一点没变） |

已有的 demo 工程（桌面 `JJExceptionDemo`）可以直接对着 fork 源码跑全量验证，
覆盖 45 个崩溃点、20 组对抗输入、10 项压力测试。

---

## 五、如果出现问题怎么回退

fork 与上游 API 完全一致，回退只需把 Podfile 改回：

```ruby
pod 'JJException', '~> 0.2.13'
```

`pod install` 后即恢复原库。业务代码零改动，因为两边的公开接口相同。

---

## 六、已知限制（不随接入改变）

1. **unrecognized selector 的返回值**：运行时无法得知不存在方法的真实签名，
   大结构体返回值是未定义内容。守卫只保证进程存活并上报。这类上报必须当 bug 修。
2. **`stopGuardException` 之后**：就是原始 Foundation 行为，非法调用会崩。这是语义。
3. **iOS 15–17 未实机验证**：本机只有 iOS 18.6 / 27.0 / 27.1 运行时。
   代码层面部署目标是 15.0、所有新 API 都有 `@available` 保护，且三个运行时上
   具体类名完全一致，但这两个大版本的实测覆盖是空白。
