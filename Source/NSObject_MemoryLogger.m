//
//  NSObject_MemoryLogger.m
//  BMScriptTest
//
//  Created by Andre Berg on 02.10.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

/// @cond HIDDEN

#import "NSObject_MemoryLogger.h"

id MemoryLogger_retain(id self, SEL _cmd) { 
	NSUInteger rc = [self retainCount]; 
	NSLog(@"%@[0x%x]: retain, rc = %d -> %d (%d)", NSStringFromClass([self superclass]), self, rc, rc + 1, NSExtraRefCount(self)); 
	return [self _MemoryLogger_retain];
} 

void MemoryLogger_release(id self, SEL _cmd) {
	NSUInteger rc = [self retainCount]; 
	NSLog(@"%@[0x%x]: release, rc = %d -> %d (%d)", NSStringFromClass([self superclass]), self, rc, rc - 1, NSExtraRefCount(self)); 
	[self _MemoryLogger_release];
} 

id MemoryLogger_autorelease(id self, SEL _cmd) {
	NSUInteger rc = [self retainCount]; 
	NSLog(@"%@[0x%x]: autorelease, rc = %d (%d)", NSStringFromClass([self superclass]), self, rc, NSExtraRefCount(self)); 
	return [self _MemoryLogger_autorelease];
} 

void MemoryLogger_dealloc(id self, SEL _cmd) {
	NSLog(@"%@[0x%x]: dealloc", NSStringFromClass([self superclass]), self);
	[self _MemoryLogger_dealloc];
}


@implementation NSObject(MemoryLogger)

static NSMutableDictionary * loggedClasses = nil; 

- (id) startLogging { 
    Class class = [self class]; 
    // check if the object is already being tracked/logged
    if (class_getMethodImplementation(class, @selector(retain)) == (IMP) MemoryLogger_retain) return self;
    
    if (loggedClasses == nil) 
        loggedClasses = [[NSMutableDictionary alloc] init];
    
    // check if there's already a subclass for class  
    id newSubClass = [loggedClasses objectForKey:class]; 
    if (newSubClass == nil) {
        NSString * newClassName = [NSString stringWithFormat: @"_MemoryLogger_%s", class_getName(class)];
        newSubClass = objc_allocateClassPair(class, [newClassName UTF8String], 0);
        
        // read out old function implementations 
        IMP oldRetain = class_getMethodImplementation(class, @selector(retain)); 
        IMP oldRelease = class_getMethodImplementation(class, @selector(release)); 
        IMP oldAutorelease = class_getMethodImplementation(class, @selector(autorelease)); 
        IMP oldDealloc = class_getMethodImplementation(class, @selector(dealloc));
        
        // save new implementations 
        class_addMethod(newSubClass, @selector(_MemoryLogger_retain), oldRetain, "@@:");  
        class_addMethod(newSubClass, @selector(_MemoryLogger_release), oldRelease, "v@:"); 
        class_addMethod(newSubClass, @selector(_MemoryLogger_autorelease), oldAutorelease, "@@:"); 
        class_addMethod(newSubClass, @selector(_MemoryLogger_dealloc), oldDealloc, "v@:");
        class_addMethod(newSubClass, @selector(retain), (IMP) &MemoryLogger_retain, "@@:");
        class_addMethod(newSubClass, @selector(release), (IMP) &MemoryLogger_release, "v@:");
        class_addMethod(newSubClass, @selector(autorelease), (IMP) &MemoryLogger_autorelease, "@@:");
        class_addMethod(newSubClass, @selector(dealloc), (IMP) &MemoryLogger_dealloc, "v@:");
        
        objc_registerClassPair(newSubClass); 
        [loggedClasses setObject:newSubClass forKey:class];
    } 
    object_setClass(self, newSubClass); 
    return self;
}

- (id) stopLogging { 
    if (class_getMethodImplementation([self class], @selector(retain)) != (IMP) MemoryLogger_retain) 
        return self;
    object_setClass(self, [self superclass]); 
    return self;
}

@end

/// @endcond 