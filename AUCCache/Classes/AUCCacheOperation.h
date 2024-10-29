//
//  AUCCacheOperation.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/14.
//

#import <Foundation/Foundation.h>

@protocol AUCCacheOperation <NSObject>

- (void)cancel;

@end

NS_ASSUME_NONNULL_BEGIN

@interface NSOperation (AUCCacheOperation) <AUCCacheOperation>

@end

NS_ASSUME_NONNULL_END
