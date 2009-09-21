//
//  TaskObserver.h
//  BMScriptTest
//
//  Created by Andre Berg on 21.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
/// @cond

#import <Cocoa/Cocoa.h>
#import "BMScript.h"

@interface TaskObserver : NSObject <BMScriptLanguageProtocol> {
    NSString * bgResults;
    TerminationStatus bgStatus;
    BOOL taskHasEnded;
    BOOL shouldSetLastResultCalled;
    BOOL shouldSetScriptCalled;
}

- (void) taskFinished:(NSNotification *)aNotification;
- (void) checkTaskHasFinished:(id)obj;

- (NSString *) debugDescription;

- (NSString *)bgResults;
- (void)setBgResults:(NSString *)newBgResults;
- (TerminationStatus)bgStatus;
- (void)setBgStatus:(TerminationStatus)newBgStatus;
- (BOOL)taskHasEnded;
- (void)setTaskHasEnded:(BOOL)flag;
- (BOOL)shouldSetLastResultCalled;
- (void)setShouldSetLastResultCalled:(BOOL)flag;
- (BOOL)shouldSetScriptCalled;
- (void)setShouldSetScriptCalled:(BOOL)flag;

@end

/// @endcond
