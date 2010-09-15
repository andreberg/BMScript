//
//  BMScriptBareBonesTest.m
//  BMScriptTest
//
//  Created by Andre Berg on 29.09.09.
//  Copyright 2008 Berg Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Foundation/Foundation.h>

#include <unistd.h>
#include <objc/objc-auto.h>

#import "BMScript.h"
#import "BMDefines.h"

#import "ScriptRunner.h"

#ifdef __OBJC_GC__
    #define DEBUG_GC_ENABLED 1
#else
    #define DEBUG_GC_ENABLED 0
#endif

#ifndef DEBUG
    #define DEBUG 0
#endif 

int main (int argc, const char * argv[]) {
#pragma unused(argc, argv)
    
    #ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
        // start gc thread
        objc_startCollectorThread();
    #endif
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    ScriptRunner * scriptRunner1 = [[ScriptRunner alloc] initWithExecutionMode:SRBlockingExecutionMode];
    [scriptRunner1 run];

    ScriptRunner * scriptRunner2 = [[ScriptRunner alloc] initWithExecutionMode:SRNonBlockingExecutionMode];
    [scriptRunner2 run];

    BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"test test" options:nil]; // options:nil == BMSynthesizeOptions(@"/bin/echo", @"")
    [script1 execute];
    
    NSLog(@"script1 result = '%@'\n", [[script1 lastResult] quotedString]);

    [script1 release], script1 = nil;
    
    NSLog(@"scriptRunner1 results = '%@'", [[scriptRunner1 results] quotedString]);
    NSLog(@"scriptRunner2 results = '%@'", [[scriptRunner2 results] quotedString]);
    
    [scriptRunner1 release], scriptRunner1 = nil;
    [scriptRunner2 release], scriptRunner2 = nil;
    
    [pool drain];
    
    #ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
        objc_collect(OBJC_COLLECT_IF_NEEDED);
    #endif
    
    puts("Press return to exit...");
    getchar();
    
    return EXIT_SUCCESS;
}