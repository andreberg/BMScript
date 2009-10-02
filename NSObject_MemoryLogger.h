//
//  NSObject_MemoryLogger.h
//  BMScriptTest
//
//  Created by Andre Berg on 02.10.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  NOTE: The source code for the whole category is from
//  a German book on Objective-2.0 and iPhone programming.
//  ISBN: 978-3-8266-5966-9

#import <Cocoa/Cocoa.h>

@interface NSObject(MemoryLogger) 
- (id) startLogging; 
- (id) stopLogging; 
@end
