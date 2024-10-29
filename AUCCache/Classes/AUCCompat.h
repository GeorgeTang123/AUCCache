//
//  AUCCompat.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#ifndef AUCCompat_h
#define AUCCompat_h

#if TARGET_OS_IOS || TARGET_OS_TV
    #define AU_UIKIT 1
#else
    #define AU_UIKIT 0
#endif

#if TARGET_OS_OSX
    #define AU_OS_MAC 1
#else
    #define AU_OS_MAC 0
#endif


#if TARGET_OS_IOS
    #define AU_OS_IOS 1
#else
    #define AU_OS_IOS 0
#endif

#if TARGET_OS_TV
    #define AU_OS_TV 1
#else
    #define AU_OS_TV 0
#endif

#if TARGET_OS_WATCH
    #define AU_OS_WATCH 1
#else
    #define AU_OS_WATCH 0
#endif


#endif /* AUCCompat_h */
