//
//  AUCDiskCache.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import <Foundation/Foundation.h>
#import "AUCProtocolsDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class AUCCacheConfig;
/// ``磁盘缓存``
@interface AUCDiskCache : NSObject <AUCDiskCacheProtocol>

@property (nonatomic, strong, nonnull, readonly) AUCCacheConfig *config;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// ``将缓存目录从旧位置移到新位置，完成后将删除旧位置。``
///
/// - Parameters:
///     - srcPath - 缓存目录的旧位置
///     - dstPath - 缓存目录的新位置
/// - Note: 如果旧位置不存在，则什么也不做。
/// - Note: 如果新位置不存在，则只移动目录。
/// - Note: 如果新位置确实存在，将移动并合并旧位置的文件。
/// - Note: 如果新位置确实存在，但不是一个目录，则将删除它并移动目录。
- (void)moveCacheDirectoryFromPath:(nonnull NSString *)srcPath toPath:(nonnull NSString *)dstPath;

@end

NS_ASSUME_NONNULL_END
