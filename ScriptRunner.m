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

#import "ScriptRunner.h"

@implementation ScriptRunner

@synthesize script;
@synthesize bgScript;
@synthesize results;
@synthesize bgResults;
@synthesize status;
@synthesize bgStatus;
@synthesize taskHasEnded;
@synthesize bgTaskHasEnded;
@synthesize shouldSetResultCalled;
@synthesize shouldSetScriptCalled;


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // need to tell BMScript that we no longer wish to be its delegate
    // since it only has a weak reference to us it may be sending messages
    // to the delegate property even after we deallocate
    script.delegate = nil;
    bgScript.delegate = nil;
    
    [script release], script = nil;
    [bgScript release], bgScript = nil;
    [results release], results = nil;
    [bgResults release], bgResults = nil;
    
    [super dealloc];
}

- (void) finalize {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    script.delegate = nil;
    bgScript.delegate = nil;
    
    [super finalize];
}


- (id) init {
    self = [super init];
    if (self != nil) {        
        //NSDictionary * opts = BMSynthesizeOptions(@"/bin/echo", @"");
        BMScript * aScript = [[BMScript alloc] initWithScriptSource:@"\"this is ScriptRunner\'s script calling...\"" 
                                                            options:BMSynthesizeOptions(@"/bin/echo", @"")];
        script = [aScript retain];
        [script setDelegate:self];
        [aScript release];
        
        bgScript = [[BMScript pythonScriptWithSource:@"print 3**100"] retain];
        [bgScript setDelegate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(bgTaskFinished:) 
                                                     name:BMScriptTaskDidEndNotification 
                                                   object:bgScript];

        results = nil;
        status = BMScriptNotExecutedTerminationStatus;
        
        bgResults = nil;
        bgStatus = BMScriptNotExecutedTerminationStatus;
        
        taskHasEnded = NO;
        bgTaskHasEnded = NO;
        
        shouldSetResultCalled = NO;
        shouldSetScriptCalled = NO;
        
    }
    return self;
}

- (void) bgTaskFinished:(NSNotification *)aNotification {
    
    TerminationStatus stats = [[[aNotification userInfo] objectForKey:BMScriptNotificationTaskTerminationStatus] intValue];
    NSString * result = [[aNotification userInfo] objectForKey:BMScriptNotificationTaskResults];
    
    self.bgResults = result;
    self.bgStatus = stats;
    self.bgTaskHasEnded = YES;
    
    NSLog(@"Inside %s: bgTask finished with bgStatus = %ld, bgResult = '%@'\n", __PRETTY_FUNCTION__, bgStatus, [bgResults quote]);
    NSLog(@"Inside %s\n%@", __PRETTY_FUNCTION__, [self debugDescription]);
}


- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@:\n"
                @"   taskHasEnded? %3s |    status = '%-32s' |   results = '%@',\n"
                @" bgTaskHasEnded? %3s |  bgStatus = '%-32s' | bgResults = '%@',\n"
                @" shouldSetResultCalled? %@\n"
                @" shouldSetScriptCalled? %@", 
                [self description], 
                [BMStringFromBOOL(taskHasEnded) UTF8String], [BMStringFromTerminationStatus(status) UTF8String], [results quote], 
                [BMStringFromBOOL(bgTaskHasEnded) UTF8String], [BMStringFromTerminationStatus(bgStatus) UTF8String], [bgResults quote], 
                BMStringFromBOOL(shouldSetResultCalled), BMStringFromBOOL(shouldSetScriptCalled)
            ];
}


- (void) launch {
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

- (void) launchBackground {
    [bgScript executeInBackgroundAndNotify];
}


// MARK: BMScript Delegate Methods

- (BOOL) shouldSetResult:(NSString *)aString {
    #pragma unused(aString)
    self.shouldSetResultCalled = YES;
    return YES;
}

- (BOOL) shouldSetScript:(NSString *)aScript {
    #pragma unused(aScript)
    self.shouldSetScriptCalled = YES;
    return YES;
}

@end
