//
//  JJWeakObjectBox.m
//  JJException
//

#import "JJWeakObjectBox.h"

@interface JJWeakObjectBox ()
@property (nonatomic, weak, nullable) id weakObject;
@end

@implementation JJWeakObjectBox

- (instancetype)initWithObject:(id)object {
    self = [super init];
    if (self) {
        _weakObject = object;
    }
    return self;
}

- (nullable id)object {
    return self.weakObject;
}

@end
