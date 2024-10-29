//
//  AUCAsyncBlockOperation.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// use 
@class AUCAsyncBlockOperation;
typedef void (^AUAsyncBlock)(AUCAsyncBlockOperation * __nonnull asyncOperation);
@interface AUCAsyncBlockOperation : NSOperation

- (nonnull instancetype)initWithBlock:(nonnull AUAsyncBlock)block;
+ (nonnull instancetype)blockOperationWithBlock:(nonnull AUAsyncBlock)block;
- (void)complete;

@end

NS_ASSUME_NONNULL_END
