//
//  TaskObserver.m
//  BMScriptTest
//
//  Created by Andre Berg on 21.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import "TaskObserver.h"
#import "BMScript.h"

//static BOOL s_taskHasEnded = NO;

@implementation TaskObserver 

- (void) taskFinished:(NSNotification *)aNotification {
    
    TerminationStatus status = [[[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskTerminationStatusKey] intValue];
    NSString * results = [[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskResultsKey];
    
    //NSLog(@"inside %s: bgTask finished with status = %ld, result = '%@'", __PRETTY_FUNCTION__, status, [results quote]);
    
    self.bgResults = results;
    self.bgStatus = status;
    self.taskHasEnded = YES;
}

- (void) checkTaskHasFinished:(id)obj {
    NSLog(@"%@", [obj debugDescription]);
}

- (id) init {
    self = [super init];
    if (self != nil) {
        
        shouldSetLastResultCalled = NO;
        shouldSetScriptCalled = NO;
        
        bgStatus = BMScriptNotExecutedTerminationStatus;
        bgResults = nil;
        taskHasEnded = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:BMScriptTaskDidEndNotification object:nil];
        
        BMScript * bgScript = [BMScript pythonScriptWithSource:@"print 3**100"];
        
        [bgScript setDelegate:self];
        [bgScript executeInBackgroundAndNotify];
    }
    return self;
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [bgResults release], bgResults = nil;
    [super dealloc];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@: bgResults = '%@', bgStatus = %@, taskHasEnded? %@, shouldSetLastResultCalled? %@, shouldSetScriptCalled? %@", 
            [self description], [bgResults quote], BMStringFromTerminationStatus(bgStatus), BMStringFromBOOL(taskHasEnded), BMStringFromBOOL(shouldSetLastResultCalled), BMStringFromBOOL(shouldSetScriptCalled) ];
}

// MARK: BMScript Delegate Methods

- (BOOL) shouldSetLastResult:(NSString *)aString {
    self.shouldSetLastResultCalled = YES;
    if ([aString isEqualToString:@"9"]) {
        NSLog(@"LastResult will be set to 9");
        return YES;
    }
    return YES;
}

- (BOOL) shouldSetScript:(NSString *)aScript {
    self.shouldSetScriptCalled = YES;
    NSLog(@"%s", _cmd);
    return YES;
}

// MARK: BMScriptLanguageProtocol

- (NSDictionary *) defaultOptionsForLanguage {
    BMSynthesizeOptions(@"/bin/echo", @"using /bin/echo from ObserverDummy", nil);
    return defaultDict;
}

// MARK: Accessors 

- (NSString *)bgResults {
    return bgResults; 
}

- (void)setBgResults:(NSString *)newBgResults {
    if (bgResults != newBgResults) {
        [bgResults release];
        bgResults = [newBgResults retain];
    }
}

- (TerminationStatus)bgStatus {
    return bgStatus;
}

- (void)setBgStatus:(TerminationStatus)newBgStatus {
    bgStatus = newBgStatus;
}

- (BOOL)taskHasEnded {
    return taskHasEnded;
}

- (void)setTaskHasEnded:(BOOL)flag {
    taskHasEnded = flag;
}

- (BOOL)shouldSetLastResultCalled {
    return shouldSetLastResultCalled;
}

- (void)setShouldSetLastResultCalled:(BOOL)flag {
    shouldSetLastResultCalled = flag;
}

- (BOOL)shouldSetScriptCalled {
    return shouldSetScriptCalled;
}

- (void)setShouldSetScriptCalled:(BOOL)flag {
    shouldSetScriptCalled = flag;
}

@end