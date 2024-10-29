//
//  AUCAsyncBlockOperation.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import "AUCAsyncBlockOperation.h"

@interface AUCAsyncBlockOperation ()

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, copy, nonnull) AUAsyncBlock executionBlock;

@end

@implementation AUCAsyncBlockOperation
@synthesize executing = _executing;
@synthesize finished = _finished;
- (nonnull instancetype)initWithBlock:(nonnull AUAsyncBlock)block {
    self = [super init];
    if (self) {
        self.executionBlock = block;
    }
    return self;
}

+ (nonnull instancetype)blockOperationWithBlock:(nonnull AUAsyncBlock)block {
    AUCAsyncBlockOperation *operation = [[AUCAsyncBlockOperation alloc] initWithBlock:block];
    return operation;
}

/// 复写 NSOperation 入口函数
- (void)start {
    if (self.isCancelled) {
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    self.executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    if (self.executionBlock) {
        self.executionBlock(self);
    } else {
        [self complete];
    }
}

- (void)cancel {
    [super cancel];
    [self complete];
}

/// 手动跟踪 NSOperation 的状态部分, 手动触发 KVO 监听, 回调给上层
- (void)complete {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.executing = NO;
    self.finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
