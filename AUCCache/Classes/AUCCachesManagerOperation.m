//
//  AUCCachesManagerOperation.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import "AUCCachesManagerOperation.h"
#import "AUCInternalMacros.h"

@implementation AUCCachesManagerOperation {
    dispatch_semaphore_t _pendingCountLock;
}

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;
@synthesize pendingCount = _pendingCount;
- (instancetype)init {
    if (self = [super init]) {
        _pendingCountLock = dispatch_semaphore_create(1);
        _pendingCount = 0;
    }
    return self;
}

- (void)beginWithTotalCount:(NSUInteger)totalCount {
    self.executing = YES;
    self.finished = NO;
    _pendingCount = totalCount;
}

- (NSUInteger)pendingCount {
    AUC_DISPATCH_SEMAPHORE_LOCK(_pendingCountLock);
    NSUInteger pendingCount = _pendingCount;
    AUC_DISPATCH_SEMAPHORE_UNLOCK(_pendingCountLock);
    return pendingCount;
}

- (void)completeOne {
    AUC_DISPATCH_SEMAPHORE_LOCK(_pendingCountLock);
    _pendingCount = _pendingCount > 0 ? _pendingCount - 1 : 0;
    AUC_DISPATCH_SEMAPHORE_UNLOCK(_pendingCountLock);
}

- (void)cancel {
    self.cancelled = YES;
    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    AUC_DISPATCH_SEMAPHORE_LOCK(_pendingCountLock);
    _pendingCount = 0;
    AUC_DISPATCH_SEMAPHORE_UNLOCK(_pendingCountLock);
}

/// 手动跟踪 NSOperation 的状态部分, 手动触发 KVO 监听, 回调给上层
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setCancelled:(BOOL)cancelled {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
}

@end
