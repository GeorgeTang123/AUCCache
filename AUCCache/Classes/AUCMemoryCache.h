//
//  AUCMemoryCache.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AUCProtocolsDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class AUCCacheConfig;
@interface AUCMemoryCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType> <AUCMemoryCacheProtocol>

@property (nonatomic, strong, nonnull, readonly) AUCCacheConfig *config;

@end

NS_ASSUME_NONNULL_END
