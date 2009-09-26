//
//  ScriptRunner.h
//  BMScriptTest
//
//  Created by Andre Berg on 24.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  For license details see end of this file.
//  Short version: licensed under the MIT license.
//
/// @cond

#import <Cocoa/Cocoa.h>
#import "BMScript.h"


@interface ScriptRunner : NSObject <BMScriptDelegateProtocol> {
    
    BMScript * script;
    BMScript * bgScript;
    
    NSString * results;
    NSString * bgResults;
    
    TerminationStatus status;
    TerminationStatus bgStatus;
    
    BOOL taskHasEnded;
    BOOL bgTaskHasEnded;
    
    BOOL shouldSetLastResultCalled;
    BOOL shouldSetScriptCalled;
}

- (void) launch;
- (void) launchBackground;

- (void) bgTaskFinished:(NSNotification *)aNotification;
- (NSString *) debugDescription;

@property (nonatomic, retain) BMScript * script;
@property (nonatomic, retain) BMScript * bgScript;
@property (nonatomic, copy) NSString * results;
@property (nonatomic, copy) NSString * bgResults;
@property (nonatomic, assign) TerminationStatus status;
@property (nonatomic, assign) TerminationStatus bgStatus;
@property (nonatomic, assign) BOOL taskHasEnded;
@property (nonatomic, assign) BOOL bgTaskHasEnded;
@property (nonatomic, assign) BOOL shouldSetLastResultCalled;
@property (nonatomic, assign) BOOL shouldSetScriptCalled;

@end

/// @endcond

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