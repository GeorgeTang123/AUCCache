//
//  AUCCacheConfig.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import <Foundation/Foundation.h>
#import "AUCTypeDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// ``缓存配置类``
@interface AUCCacheConfig : NSObject <NSCopying>

@property (nonatomic, class, readonly, nonnull) AUCCacheConfig *defaultConfig;

/// 是否允许信息打印 默认不允许
@property (nonatomic, assign) BOOL logEnabled;

/// 当前 `AUServerConfig` 环境下的 `baseURL`, ``【全局缓存主要配置】`
@property (nonatomic, copy) NSString *baseURL;

/// 白名单 ``【全局缓存主要配置】``
/// - Note: 处于白名单内的`API`会作缓存处理，其余不处理
@property (nullable, copy, nonatomic) NSArray<NSString *> *whitelistAPIs;

/// 是否禁用 iCloud 备份
/// 
/// - Note: 默认值 - YES
@property (assign, nonatomic) BOOL shouldDisableICloud;

/// 是否使用内存缓存
///
/// - Note: 默认值 - YES
/// - Warning: 当禁用内存缓存时，弱内存缓存也将被禁用
@property (assign, nonatomic) BOOL shouldCacheInMemory;

/// 控制弱内存缓存的选项
/// 启用该选项后，`AUCCacheCombine`的内存缓存（memoryCache）将在数据存储到内存的同时使用 weak maptable（弱映射表） 来存储数据
/// 当内存警告被触发时，由于 weak maptable 并不对数据实例持有强引用，所以即使内存缓存本身被清除，一些被实时实例强持有的数据也可以再次恢复，以避免以后从磁盘缓存或网络重新查询
///
/// - Note: 默认值 - YES
@property (assign, nonatomic) BOOL shouldUseWeakMemoryCache;

/// 是否在应用程序进入后台时删除过期磁盘缓存数据
///
/// - Note: 默认值 - YES
@property (assign, nonatomic) BOOL shouldRemoveExpiredDataWhenEnterBackground;

/// 从磁盘读取缓存时的读取选项配置
///
/// - Note: 默认值为0 - 默认行为，可以将其设置为`NSDataReadingMappedIfSafe`以提高性能
@property (assign, nonatomic) NSDataReadingOptions diskCacheReadingOptions;

/// 将缓存写入磁盘时的写入选项配置
///
/// - Note: 默认为 `NSDataWritingAtomic`。可以将其设置为 `NSDataWritingWithoutOverwriting`，以防止覆盖现有文件
@property (assign, nonatomic) NSDataWritingOptions diskCacheWritingOptions;

/// 在磁盘缓存中保留数据的最长时间，单位为【秒】
///
/// - Note: 默认为  `1周`，设置为`负值意味着不会过期`，设置为`0表示在进行过期检查时删除所有缓存文件`
@property (assign, nonatomic) NSTimeInterval maxDiskAge;

/// 磁盘缓存的最大大小
///
/// - Note: 以字节为单位，默认为`0 - 即没有缓存大小限制`
@property (assign, nonatomic) NSUInteger maxDiskSize;

 /// 内存数据缓存的最大`总成本`，成本函数是内存中的字节数
///
/// - Note: 默认为`0 - 没有内存成本限制`
@property (assign, nonatomic) NSUInteger maxMemoryCost;

/// 内存数据缓存可容纳的最大数量
///
/// - Note: 默认为`0 - 没有内存数量限制`
@property (assign, nonatomic) NSUInteger maxMemoryCount;

/// 清除磁盘缓存时将检查缓存过期方式
///
/// - Note: 默认值为`AUCCacheConfigExpireTypeModificationDate`，根据【创建或修改缓存】作为过期依据
@property (assign, nonatomic) AUCCacheConfigExpireType diskCacheExpireType;
@property (strong, nonatomic, nullable) NSFileManager *fileManager;

/// 自定义内存缓存类。提供的类实例必须遵守 `AUCMemoryCacheProtocol` 协议才能使用
///
/// - Note: 默认为内置的 `AUCMemoryCache` 类
/// - Warning: 该值不支持动态更改。这意味着在缓存【启动后】对该值的进一步修改将不起作用
@property (assign, nonatomic, nonnull) Class memoryCacheClass;

/// 自定义磁盘缓存类。提供的类实例必须遵守 `AUCDiskCacheProtocol` 协议才能使用
///
/// - Note: 默认为内置的 `AUCDiskCache` 类
/// - Warning: 该值不支持动态更改。这意味着在缓存【启动后】对该值的进一步修改将不起作用
@property (assign ,nonatomic, nonnull) Class diskCacheClass;

@end

NS_ASSUME_NONNULL_END
