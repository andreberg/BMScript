//
//  ScriptRunner.h
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

#import <Cocoa/Cocoa.h>
#import "BMScript.h"

enum {
    SRBlockingExecutionMode = 0,
    SRNonBlockingExecutionMode
};
typedef NSUInteger SRExecutionMode;


@interface ScriptRunner : NSObject <BMScriptDelegateProtocol> {
    id script;
    NSString * results;
    TerminationStatus status;
    BOOL taskHasEnded;
    // delegation methods
    BOOL shouldSetResultCalled;
    BOOL shouldSetScriptCalled;
    BOOL willSetResultCalled;
    BOOL willSetScriptCalled;
}

- (void) run;
- (void) taskFinished:(NSNotification *)aNotification;
- (NSString *) debugDescription;

- (id) initWithExecutionMode:(SRExecutionMode)mode; /* designated initializer */

@property (retain) id script;
@property (copy) NSString * results;
@property (assign) TerminationStatus status;
@property (assign) BOOL taskHasEnded;
@property (assign) BOOL shouldSetResultCalled;
@property (assign) BOOL shouldSetScriptCalled;
@property (assign) BOOL willSetResultCalled;
@property (assign) BOOL willSetScriptCalled;

@end

/// @endcond
