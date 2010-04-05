//
//  ScriptRunner.m
//  BMScriptTest
//
//  Created by Andre Berg on 24.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
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

/// @cond HIDDEN

#import "ScriptRunner.h"

@implementation ScriptRunner

@synthesize script;
@synthesize results;
@synthesize status;
@synthesize taskHasEnded;
@synthesize shouldSetResultCalled;
@synthesize shouldSetScriptCalled;
@synthesize willSetResultCalled;
@synthesize willSetScriptCalled;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // need to tell BMScript that we no longer wish to be its delegate
    // since it only has a weak reference to us it may be sending messages
    // to the delegate property even after we deallocate
    [script setDelegate:nil];
    
    [script release], script = nil;
    [results release], results = nil;
    
    [super dealloc];
}

- (id) init { 
    return [self initWithExecutionMode:SRBlockingExecutionMode];
}


- (id) initWithExecutionMode:(SRExecutionMode)mode {
    self = [super init];
    if (self != nil) {
        if (mode == SRNonBlockingExecutionMode) {
            
            script = [[BMScript pythonScriptWithSource:@"print 3**100"] retain];
            
            [script setDelegate:self];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(taskFinished:) 
                                                         name:BMScriptTaskDidEndNotification 
                                                       object:script];
        }
        else {
            BMScript * aScript = [[BMScript alloc] initWithScriptSource:@"\"this is ScriptRunner\'s script calling...\"" 
                                                                options:BMSynthesizeOptions(@"/bin/echo", @"-n")];
            script = [aScript retain];
            [script setDelegate:self];
            [aScript release];
        }
        
        results = nil;
        status = BMScriptNotExecuted;
        
        taskHasEnded = NO;
        
        willSetResultCalled   = NO;
        willSetScriptCalled   = NO;
        shouldSetResultCalled = NO;
        shouldSetScriptCalled = NO;
    }
    return self;
}

- (void) taskFinished:(NSNotification *)aNotification {
    
    TerminationStatus stats = [[[aNotification userInfo] objectForKey:BMScriptNotificationTaskTerminationStatus] intValue];
    NSString * result = [[aNotification userInfo] objectForKey:BMScriptNotificationTaskResults];
    
    self.results = result;
    self.status = stats;
    self.taskHasEnded = YES;
    
    NSLog(@"Inside %s: task finished with status = %ld, result = '%@'\n", __PRETTY_FUNCTION__, status, [results quote]);
    NSLog(@"Inside %s\n%@", __PRETTY_FUNCTION__, [self debugDescription]);
}


- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@:\n"
                @"   taskHasEnded? %3s |    status = '%-32s' |   results = '%@',\n"
                @" willSetResultCalled?   %@\n"
                @" willSetScriptCalled?   %@\n"
                @" shouldSetResultCalled? %@\n"
                @" shouldSetScriptCalled? %@", 
                [self description], 
                [BMStringFromBOOL(taskHasEnded) UTF8String], [BMStringFromTerminationStatus(status) UTF8String], [results quote], 
                BMStringFromBOOL(willSetResultCalled), 
                BMStringFromBOOL(willSetScriptCalled), 
                BMStringFromBOOL(shouldSetResultCalled), 
                BMStringFromBOOL(shouldSetScriptCalled)];
}


- (void) run {
    NSError * err = nil;
    NSString * res = nil;
    self.status = [script executeAndReturnResult:&res error:&err];
    self.results = res;
    if (err) {
        NSLog(@"Inside %s: err = %@", __PRETTY_FUNCTION__, [err description]);
    }
    self.taskHasEnded = YES;
    NSLog(@"Inside %s\n%@", __PRETTY_FUNCTION__, [self debugDescription]);
}


// MARK: BMScript Delegate Methods

- (NSString *) willSetResult:(NSString *)aString {
    NSLog(@"%s called! aString = %@", __PRETTY_FUNCTION__, aString);
    self.willSetResultCalled = YES;
    return [NSString stringWithFormat:@"%@ CHANGED", aString];
}

- (NSString *) willSetScript:(NSString *)aScript {
    NSLog(@"%s called! aScript = %@", __PRETTY_FUNCTION__, aScript);
    self.willSetScriptCalled = YES;
    return aScript;
}

- (BOOL) shouldSetResult:(NSString *)aString {
    NSLog(@"%s called! aString = %@", __PRETTY_FUNCTION__, aString);
    self.shouldSetResultCalled = YES;
    return YES;
}

- (BOOL) shouldSetScript:(NSString *)aScript {
    NSLog(@"%s called! aScript = %@", __PRETTY_FUNCTION__, aScript);
    self.shouldSetScriptCalled = YES;
    return YES;
}

@end

/// @endcond 
