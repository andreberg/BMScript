//
//  ScriptRunner.m
//  BMScriptTest
//
//  Created by Andre Berg on 24.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  For license details see end of this file.
//  Short version: licensed under the MIT license.
//

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
@synthesize shouldSetLastResultCalled;
@synthesize shouldSetScriptCalled;


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [script release], script = nil;
    [bgScript release], bgScript = nil;
    [results release], results = nil;
    [bgResults release], bgResults = nil;
    
    [super dealloc];
}

- (id) init {
    self = [super init];
    if (self != nil) {
        
        NSDictionary * opts = BMSynthesizeOptions(@"/bin/echo", nil);
        script = [[BMScript alloc] initWithScriptSource:@"this is ScriptRunner's script calling..." options:opts];
        [script setDelegate:self];
        bgScript = [BMScript pythonScriptWithSource:@"print 3**100"];
        [bgScript setDelegate:self];
        
        results = nil;
        status = BMScriptNotExecutedTerminationStatus;
        
        bgResults = nil;
        bgStatus = BMScriptNotExecutedTerminationStatus;
        
        taskHasEnded = NO;
        bgTaskHasEnded = NO;
        
        shouldSetLastResultCalled = NO;
        shouldSetScriptCalled = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bgTaskFinished:) name:BMScriptTaskDidEndNotification object:nil];
    }
    return self;
}

- (void) bgTaskFinished:(NSNotification *)aNotification {
    
    TerminationStatus stats = [[[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskTerminationStatusKey] intValue];
    NSString * result = [[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskResultsKey];
    
    self.bgResults = result;
    self.bgStatus = stats;
    self.bgTaskHasEnded = YES;
    
    NSLog(@"Inside %s: bgTask finished with bgStatus = %ld, bgResult = '%@'", __PRETTY_FUNCTION__, self.bgStatus, [self.bgResults quote]);
    NSLog(@"Inside %s: [self debugDescription]: \n%@", __PRETTY_FUNCTION__, [self debugDescription]);
}


- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@: taskHasEnded? %@, status = '%@', results = '%@', bgTaskHasEnded? %@, bgStatus = '%@', bgResults = '%@', shouldSetLastResultCalled? %@, shouldSetScriptCalled? %@", 
            [self description], BMStringFromBOOL(taskHasEnded), BMStringFromTerminationStatus(status), [results quote], BMStringFromBOOL(bgTaskHasEnded), BMStringFromTerminationStatus(bgStatus), [bgResults quote], BMStringFromBOOL(shouldSetLastResultCalled), BMStringFromBOOL(shouldSetScriptCalled) ];
}


- (void) launch {
    NSError * err;
    self.status = [script executeAndReturnResult:&results error:&err];
    if (err) {
        NSLog(@"Inside %s: err = %@", __PRETTY_FUNCTION__, err);
    }
    self.taskHasEnded = YES;
}

- (void) launchBackground {
    [bgScript executeInBackgroundAndNotify];
}


// MARK: BMScript Delegate Methods

- (BOOL) shouldSetLastResult:(NSString *)aString {
    self.shouldSetLastResultCalled = YES;
    // NSLog(@"Inside %s aString = %@", __PRETTY_FUNCTION__, aString);
    return YES;
}

- (BOOL) shouldSetScript:(NSString *)aScript {
    self.shouldSetScriptCalled = YES;
    //NSLog(@"Inside %s", __PRETTY_FUNCTION__);
    return YES;
}

@end

/*
 * Copyright (c) 2009 Andre Berg (Berg Media)
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
