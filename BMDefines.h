//
//  BMDefines.h
//  BMScriptTest
//
//  Created by Andre Berg on 27.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>


/*!
 * @defined BM_DEBUG_RETAIN_INITIALIZE
 * 
 * @abstract 
 * ￼Defines a macro which supplies replacement methods for -[retain] and -[release].
 * 
 * @discussion ￼
 * This macro is normally used in a global context (e.g. outside main) and followed by BM_DEBUG_RETAIN_SWIZZLE(className) in a local context, which then actually registers the replacement for the Class 'className' with the runtime.
 */
#define BM_DEBUG_RETAIN_INITIALIZE \
    IMP oldRetain;\
    IMP oldRelease;\
    id newRetain(id self, SEL _cmd) {\
        NSUInteger rc = [self retainCount];\
        NSLog(@"%s[0x%x]: retain, rc = %d -> %d",\
        class_getName([self class]), self, rc, rc + 1);\
        return (*oldRetain)(self, _cmd);\
    }\
    void newRelease(id self, SEL _cmd) {\
        NSUInteger rc = [self retainCount];\
        NSLog(@"%s[0x%x]: retain, rc = %d -> %d", \
        class_getName([self class]), self, rc, rc - 1);\
        (*oldRetain)(self, _cmd);\
    }

/*!
 * @defined BM_DEBUG_RETAIN_INITIALIZE
 * 
 * @abstract 
 * ￼Swizzles (or replaces) the methods defined by BM_DEBUG_RETAIN_INITIALIZE for className.
 * 
 * @discussion ￼
 * This macro is normally used in a (function) local scope, provided a BM_DEBUG_RETAIN_INITIALIZE declaration at the beginning of the file (in global context). BM_DEBUG_RETAIN_SWIZZLE(className) then actually registers the replacements defined by BM_DEBUG_RETAIN_INITIALIZE for the Class 'className' with the runtime.
 *
 * @param description A string specifying the date.
 */
#define BM_DEBUG_RETAIN_SWIZZLE(className) \
    oldRetain = class_getMethodImplementation((className), @selector(retain));\
    class_replaceMethod((className), @selector(retain), (IMP)&newRetain, "@@:");\
    oldRelease = class_getMethodImplementation((className), @selector(release));\
    class_replaceMethod((className), @selector(release), (IMP)&newRelease, "v@:");

