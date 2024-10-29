#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AUCAsyncBlockOperation.h"
#import "AUCCache.h"
#import "AUCCacheCombine.h"
#import "AUCCacheConfig.h"
#import "AUCCacheDirectory.h"
#import "AUCCacheHelper.h"
#import "AUCCacheOperation.h"
#import "AUCCachesManager.h"
#import "AUCCachesManagerOperation.h"
#import "AUCCompat.h"
#import "AUCDeviceHelper.h"
#import "AUCDiskCache.h"
#import "AUCFileAttributeHelper.h"
#import "AUCInternalMacros.h"
#import "AUCMemoryCache.h"
#import "AUCMetamacros.h"
#import "AUCProtocolsDefine.h"
#import "AUCTypeDefines.h"

FOUNDATION_EXPORT double AUCCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char AUCCacheVersionString[];

