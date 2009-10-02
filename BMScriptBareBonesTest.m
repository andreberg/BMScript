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


#include <unistd.h>
#import <Foundation/Foundation.h>
#import <objc/objc-auto.h>

#import "BMScript.h"
#import "BMRubyScript.h"
#import "BMDefines.h"

#import "ScriptRunner.h"
#import "BMAtomic.h"
#import "NSObject_MemoryLogger.h"

int main (int argc, const char * argv[]) {
    #pragma unused(argc, argv)
    
    // start gc thread
    objc_startCollectorThread();
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    ScriptRunner * scriptRunner1 = [[ScriptRunner alloc] initWithExecutionMode:SRBlockingExecutionMode];
    if (DEBUG && !objc_collectingEnabled()) [scriptRunner1 startLogging];
    [scriptRunner1 run];
    
    ScriptRunner * scriptRunner2 = [[ScriptRunner alloc] initWithExecutionMode:SRNonBlockingExecutionMode];
    if (DEBUG && !objc_collectingEnabled()) [scriptRunner2 startLogging];
    [scriptRunner2 run];

    BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"\"test test\"" options:nil]; // options:nil == BMSynthesizeOptions(@"/bin/echo", @"")
    if (DEBUG && !objc_collectingEnabled()) [script1 startLogging];
    [script1 execute];
    
    NSLog(@"script1 result = '%@'\n", [[script1 lastResult] quote]);

    [script1 release], script1 = nil;
    
    NSLog(@"scriptRunner1 results = '%@'", [[scriptRunner1 results] quote]);
    NSLog(@"scriptRunner2 results = '%@'", [[scriptRunner2 results] quote]);
    
    [scriptRunner1 release], scriptRunner1 = nil;
    [scriptRunner2 release], scriptRunner2 = nil;
    
    [pool drain];
    
    if (DEBUG) {
        if (!objc_collectingEnabled()) {
            [scriptRunner1 stopLogging];
            [scriptRunner2 stopLogging];
            [script1 stopLogging];
        }
        NSLog(@"Press return to exit...");
        getchar();
    }
    
    return 0;
}