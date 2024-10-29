//
//  AUCInternalMacros.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#ifndef AUCInternalMacros_h
#define AUCInternalMacros_h

#import <Foundation/Foundation.h>
#import "AUCMetamacros.h"

#ifndef AUC_DISPATCH_SEMAPHORE_LOCK
#define AUC_DISPATCH_SEMAPHORE_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef AUC_DISPATCH_SEMAPHORE_UNLOCK
#define AUC_DISPATCH_SEMAPHORE_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif


#ifndef AUC_OPTIONS_CONTAINS
#define AUC_OPTIONS_CONTAINS(options, value) (((options) & (value)) == (value))
#endif


#ifndef weakify
#define weakify(...) \
auc_keywordify \
metamacro_foreach_cxt(auc_weakify_,, __weak, __VA_ARGS__)
#endif

#ifndef strongify
#define strongify(...) \
auc_keywordify \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach(auc_strongify_,, __VA_ARGS__) \
_Pragma("clang diagnostic pop")
#endif

#define auc_weakify_(INDEX, CONTEXT, VAR) \
CONTEXT __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR);

#define auc_strongify_(INDEX, VAR) \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);


#if DEBUG
#define auc_keywordify autoreleasepool {}
#else
#define auc_keywordify try {} @catch (...) {}
#endif

#define AUDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)

#endif /* AUCInternalMacros_h */
