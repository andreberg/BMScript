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


@interface ScriptRunner : NSObject <BMScriptDelegateProtocol> {
    
    BMScript * script;
    BMScript * bgScript;
    
    NSString * results;
    NSString * bgResults;
    
    TerminationStatus status;
    TerminationStatus bgStatus;
    
    BOOL taskHasEnded;
    BOOL bgTaskHasEnded;
    
    BOOL shouldSetResultCalled;
    BOOL shouldSetScriptCalled;
}

- (void) launch;
- (void) launchBackground;

- (void) bgTaskFinished:(NSNotification *)aNotification;
- (NSString *) debugDescription;

@property (retain) BMScript * script;
@property (retain) BMScript * bgScript;
@property (copy) NSString * results;
@property (copy) NSString * bgResults;
@property (assign) TerminationStatus status;
@property (assign) TerminationStatus bgStatus;
@property (assign) BOOL taskHasEnded;
@property (assign) BOOL bgTaskHasEnded;
@property (assign) BOOL shouldSetResultCalled;
@property (assign) BOOL shouldSetScriptCalled;

@end

/// @endcond
