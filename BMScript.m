//
//  BMScript.m
//  BMScriptTest
//
//  Created by Andre Berg on 11.09.09.
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

#import "BMScript.h"
#import "BMAtomic.h"
#import "BMScriptProbes.h"      /* dtrace probes auto-generated from .d file(s) */

#include <unistd.h>             /* for usleep       */
#include <pthread.h>            /* for pthread_*    */


#define BMSCRIPT_INSERTION_TOKEN    @"%@"   /* used by templates to mark locations where a replacement insertions should occur */
#define BM_NSSTRING_TRUNCATE_LENGTH 20      /* used by -truncate, defined in NSString (BMScriptUtilities) */

#ifndef BMSCRIPT_DEBUG_MEMORY
    #define BMSCRIPT_DEBUG_MEMORY   0
#endif

#ifndef BMSCRIPT_DEBUG_HISTORY
    #define BMSCRIPT_DEBUG_HISTORY  0
#endif

#ifndef BMSCRIPT_DEBUG_OBJECTS
    #define BMSCRIPT_DEBUG_OBJECTS  0
    #if BMSCRIPT_DEBUG_OBJECTS
        #define BMSCRIPT_OBJECT_TRACE NSLog(@"Creating object %@", [super description]);
    #else
        #define BMSCRIPT_OBJECT_TRACE
    #endif
#endif

#ifndef BMSCRIPT_DEBUG_INIT
    #define BMSCRIPT_DEBUG_INIT     0
    #if BMSCRIPT_DEBUG_INIT
        #define BMSCRIPT_INIT_TRACE NSLog(@"Initializing object %@ with:\n %@", [super description], [self debugDescription]);
    #else
        #define BMSCRIPT_INIT_TRACE
    #endif
#endif

#ifndef BMSCRIPT_DEBUG_DELEGATE_METHODS
    #define BMSCRIPT_DEBUG_DELEGATE_METHODS 0
    #if BMSCRIPT_DEBUG_DELEGATE_METHODS
        #define BMSCRIPT_DELEGATE_METHOD_TRACE NSLog(@"Inside %@:%s", self, __PRETTY_FUNCTION__);
    #else
        #define BMSCRIPT_DELEGATE_METHOD_TRACE
    #endif
#endif

#if BMSCRIPT_THREAD_SAFE
    #if BMSCRIPT_FAST_LOCK
        #define BM_LOCK(name) \
        BM_PROBE(ACQUIRE_LOCK_START, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]); \
        static pthread_mutex_t mtx_##name = PTHREAD_MUTEX_INITIALIZER; \
        if (pthread_mutex_lock(&mtx_##name)) {\
            printf("*** Warning: Lock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }
        #define BM_UNLOCK(name) \
        if ((pthread_mutex_unlock(&mtx_##name) != 0)) {\
            printf("*** Warning: Unlock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }\
        BM_PROBE(ACQUIRE_LOCK_END, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);
    #else
        #define BM_LOCK(name) \
        BM_PROBE(ACQUIRE_LOCK_START, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);\
        static id const sync_##name##_ref = @""#name;\
        @synchronized(sync_##name##_ref) {
        #define BM_UNLOCK(name) }\
        BM_PROBE(ACQUIRE_LOCK_END, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);
    #endif
#else 
    #define BM_LOCK(name)
    #define BM_UNLOCK(name)
#endif

#define ap_start NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_3
    #define ap_end   [pool drain];
#else
    #define ap_end   [pool release];
#endif


NSString * const BMScriptOptionsTaskLaunchPathKey                           = @"BMScriptOptionsTaskLaunchPathKey";
NSString * const BMScriptOptionsTaskArgumentsKey                            = @"BMScriptOptionsTaskArgumentsKey";
NSString * const BMScriptOptionsVersionKey         /* currently unused */   = @"BMScriptOptionsVersionKey"; 
NSString * const BMScriptOptionsStrictTerminationStatusInterpretationKey    = @"BMScriptOptionsStrictTerminationStatusInterpretationKey";

NSString * const BMScriptTaskDidEndNotification                             = @"BMScriptTaskDidEndNotification";
NSString * const BMScriptNotificationTaskResults                            = @"BMScriptNotificationTaskResults";
NSString * const BMScriptNotificationTaskTerminationStatus                  = @"BMScriptNotificationTaskTerminationStatus";

NSString * const BMScriptTemplateArgumentMissingException           = @"BMScriptTemplateArgumentMissingException";
NSString * const BMScriptTemplateArgumentsMissingException          = @"BMScriptTemplateArgumentsMissingException";

NSString * const BMScriptLanguageProtocolDoesNotConformException    = @"BMScriptLanguageProtocolDoesNotConformException";
NSString * const BMScriptLanguageProtocolMethodMissingException     = @"BMScriptLanguageProtocolMethodMissingException";
NSString * const BMScriptLanguageProtocolIllegalAccessException     = @"BMScriptLanguageProtocolIllegalAccessException";


// MARK: File Statics (Globals)

static TerminationStatus gTaskStatus = BMScriptNotExecutedTerminationStatus;
static TerminationStatus gBgTaskStatus = BMScriptNotExecutedTerminationStatus;

//static NSLock * taskLock = [[NSLock alloc] init];
//static NSLock * bgTaskLock = [[NSLock alloc] init];

/* Empty braces means this is an "Extension" as opposed to a Category */
@interface BMScript ()

@property (BM_ATOMIC copy) NSString * result;
@property (BM_ATOMIC copy) NSString * partialResult;
@property (BM_ATOMIC assign) BOOL isTemplate;
@property (BM_ATOMIC retain) NSTask * task;
@property (BM_ATOMIC retain) NSPipe * pipe;
@property (BM_ATOMIC retain) NSTask * bgTask;
@property (BM_ATOMIC retain) NSPipe * bgPipe;

- (void) stopTask;
- (BOOL) setupTask;
- (TerminationStatus) launchTaskAndStoreResult;
- (void) setupAndLaunchBackgroundTask;
- (void) taskTerminated:(NSNotification *)aNotification;
- (void) appendData:(NSData *)d;
- (void) dataComplete:(NSNotification *)aNotification;
- (void) dataReceived:(NSNotification *)aNotification;

@end

@implementation BMScript

@dynamic delegate;

@synthesize script;
@synthesize options;
@synthesize partialResult;
@synthesize result;
@synthesize isTemplate;
@synthesize history;
@synthesize task;
@synthesize pipe;
@synthesize bgTask;
@synthesize bgPipe;

// MARK: Accessor Definitions

//=========================================================== 
//  lastResult 
//=========================================================== 

- (NSString *)lastResult {
    return [[result retain] autorelease]; 
}
// 
// - (void)setLastResult:(NSString *)newLastResult {
//     BM_LOCK
//     //NSLog(@"Inside %@ %s:", (bgTask ? [super description] : @""), __PRETTY_FUNCTION__); 
//     if (lastResult != newLastResult) {
//         //NSLog(@"lastResult was '%@', will set to '%@'", [[lastResult quote] truncate], [[newLastResult quote] truncate]);
//         [lastResult release];
//         lastResult = [newLastResult retain];
//     }
//     BM_UNLOCK
//     
// }

//=========================================================== 
//  script 
//=========================================================== 

// - (NSString *)script {
//     return [[script retain] autorelease]; 
// }
// 
// - (void)setScript:(NSString *)newScript {
//     if (script != newScript) {
//         if ([delegate respondsToSelector:@selector(shouldSetScript:)]) {
//             if ([delegate shouldSetScript:newScript]) {
//                 [script release];
//                 script = [newScript retain];
//             }
//         } else {
//             [script release];
//             script = [newScript retain];
//         }
//     }
// }

//=========================================================== 
//  options 
//=========================================================== 

// - (NSDictionary *)options {
//     return [[options retain] autorelease]; 
// }
// 
// - (void)setOptions:(NSDictionary *)newOptions {
//     if (options != newOptions) {
//         NSDictionary * item = [newOptions retain];
//         if ([delegate respondsToSelector:@selector(shouldSetOptions:)]) {
//             if ([delegate shouldSetOptions:item]) {
//                 [options release];
//                 options = item;
//             }
//         } else {
//             [options release];
//             options = item;
//         }
//     }
//     
// }

//=========================================================== 
//  partialResult 
//=========================================================== 
// - (NSString *)partialResult {
//     return [[partialResult retain] autorelease];
// }
// - (void)setPartialResult:(NSString *)newPartialResult {
//     BM_LOCK(partialResult)
//     if (partialResult != newPartialResult) {
//         if ([delegate respondsToSelector:@selector(shouldAppendPartialResult:)]) {
//             if ([delegate shouldAppendPartialResult:newPartialResult]) {
//                 [partialResult release];
//                 partialResult = [newPartialResult retain];
//             }
//         } else {
//             [partialResult release];
//             partialResult = [newPartialResult retain];
//         }
//     }
//     BM_UNLOCK(partialResult)
// }

//=========================================================== 
//  delegate 
//=========================================================== 
- (id<BMScriptDelegateProtocol>)delegate {
    return delegate; 
}

- (void)setDelegate:(id<BMScriptDelegateProtocol>)newDelegate {
    BM_LOCK(delegate)
    if (delegate != newDelegate) {
        delegate = newDelegate;
    }
    BM_UNLOCK(delegate)
}

//=========================================================== 
//  history 
//=========================================================== 

// - (NSMutableArray *)history {
//     NSMutableArray * aHistory;
//     BM_LOCK
//     aHistory = [[history retain] autorelease];
//     BM_UNLOCK
//     return aHistory;
// }
// 
// - (void)setHistory:(NSMutableArray *)newHistory {
//     BM_LOCK
//     if (history != newHistory) {
//         [history release];
//         history = [newHistory retain];
//     }
//     BM_UNLOCK
//     
// }

//=========================================================== 
//  task 
//=========================================================== 
// - (NSTask *)task {
//     return [[task retain] autorelease]; 
// }
// 
// - (void)setTask:(NSTask *)newTask {
//     if (task != newTask) {
//         [task release];
//         task = [newTask retain];
//     }
//     
// }

//=========================================================== 
//  pipe 
//=========================================================== 
// - (NSPipe *)pipe {
//     return [[pipe retain] autorelease]; 
// }
// 
// - (void)setPipe:(NSPipe *)newPipe {
//     if (pipe != newPipe) {
//         [pipe release];
//         pipe = [newPipe retain];
//     }
// }

//=========================================================== 
//  bgTask 
//=========================================================== 
// - (NSTask *)bgTask {
//     return [[bgTask retain] autorelease]; 
// }
// 
// - (void)setBgTask:(NSTask *)newBgTask {
//     if (bgTask != newBgTask) {
//         [bgTask release];
//         bgTask = [newBgTask retain];
//     }
//     
// }

//=========================================================== 
//  bgPipe 
//=========================================================== 
// - (NSPipe *)bgPipe {
//     return [[bgPipe retain] autorelease]; 
// }
// 
// - (void)setBgPipe:(NSPipe *)newBgPipe {
//     if (bgPipe != newBgPipe) {
//         [bgPipe release];
//         bgPipe = [newBgPipe retain];
//     }
//     
// }

//=========================================================== 
//  isTemplate 
//=========================================================== 

// - (BOOL)isTemplate {
//     return isTemplate;
// }
// 
// - (void)setIsTemplate:(BOOL)flag {
//     BM_LOCK(isTemplate)
//     isTemplate = flag;
//     BM_UNLOCK(isTemplate)
// }

// MARK: Description

- (NSString *) description {
    return [NSString stringWithFormat:@"%@\n"
            @"  script: '%@'\n"
            @"  result: '%@'\n"
            @"delegate: '%@'\n"
            @" options: '%@'\n", 
            [super description], 
            [script quote], 
            [result quote], 
            (delegate == self? (id)@"self" : delegate), 
            [options descriptionInStringsFileFormat]];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@\n"
            @" history (%d item%@): '%@'"
            @"    task: '%@'\n"
            @"    pipe: '%@'\n"
            @"  bgTask: '%@'\n"
            @"  bgPipe: '%@'\n", 
            [self description], [history count], ([history count] == 1 ? @"" : @"s"), history, task, pipe, bgTask, bgPipe ];
}

// MARK: Deallocation

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    if (BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    
    [script release], script = nil;
    [history release], history = nil;
    [options release], options = nil;
    [result release], result = nil;
    [partialResult release], partialResult = nil;
    [task release], task = nil;
    [pipe release], pipe = nil;
    [bgTask release], bgTask = nil;
    [bgPipe release], bgPipe = nil;
    
    [super dealloc];
}

- (void) finalize {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    if (BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    
    script = nil;
    history = nil;
    options = nil;
    result = nil;
    partialResult = nil;
    task = nil;
    pipe = nil;
    bgTask = nil;
    bgPipe = nil;
    
    [super finalize];
}


// MARK: Initializer Methods

- (id)init { 
    NSLog(@"BMScript: Warning: Initializing instance %@ with default values!"
          @"(options = \"/bin/echo\", \"\", script source = '<script source placeholder>')", [super description]);
    return [self initWithScriptSource:nil options:nil]; 
}


// - (id) initWithScriptSource:(NSString *)scriptSource {
//     NSLog(@"Warning: Initializing BMScript instance with default options (\"/bin/sh\", \"-c\").");
//     return [self initWithScriptSource:scriptSource options:nil]; 
// }

/* designated initializer */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions {
    
    if ([self isDescendantOfClass:[BMScript class]] && ![self conformsToProtocol:@protocol(BMScriptLanguageProtocol)]) {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolDoesNotConformException 
                                       reason:@"BMScript Error: "
                                              @"Descendants of BMScript must conform to the BMScriptLanguageProtocol!" 
                                     userInfo:nil];
    }
    self = [super init];
    if (BM_EXPECTED(self != nil, 1)) {
        if (scriptSource) {
            // if scriptOptions == nil, we run with default options, namely /bin/echo so it might be better 
            // to put quotes around the scriptSource
            script = (scriptOptions != nil ? [scriptSource retain] : [[scriptSource wrapSingleQuotes] retain]);
        } else {
            if ([self respondsToSelector:@selector(defaultScriptSourceForLanguage)]) {
                script = [[self performSelector:@selector(defaultScriptSourceForLanguage)] retain];
            } else {
                NSLog(@"BMScript Warning: Initializing instance %@ with default script: '<script source placeholder>'", [super description]);
                script = @"'<script source placeholder>'";
            }
        }

        if (scriptOptions) {
            options = [scriptOptions retain];
        } else {
            if ([self isDescendantOfClass:[BMScript class]] && ![self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                               reason:@"BMScript Error: Descendants of BMScript must implement "
                                                      @"-[<BMScriptLanguageProtocol> defaultOptionsForLanguage]." 
                                             userInfo:nil];
            } else if ([self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                options = [[self performSelector:@selector(defaultOptionsForLanguage)] retain];
            } else {
                NSLog(@"BMScript Warning: Initializing instance %@ with default options \"/bin/echo\", \"\"", [super description]);
                options = [BMSynthesizeOptions(@"/bin/echo", @"") retain];
            }
            
        }
        
        history = [[NSMutableArray alloc] init];
        lastResult = [[NSString alloc] init];
        partialResult = [[NSString alloc] init];
        
        // tasks/pipes will be allocated, initialized (and destroyed) lazily
        // on an as-needed basis because NSTasks are one-shot (not for re-use)
        
        BMSCRIPT_INIT_TRACE
    }
    return self;
}

- (id) initWithTemplateSource:(NSString *)templateSource options:(NSDictionary *)scriptOptions {
    if (templateSource) {
        BM_LOCK(isTemplate)
        self.isTemplate = YES;
        BM_UNLOCK(isTemplate)
        templateSource = [templateSource stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
        templateSource = [templateSource stringByReplacingOccurrencesOfString:@"%%{}" withString:@"%%{"BMSCRIPT_INSERTION_TOKEN"}"];
        return [self initWithScriptSource:templateSource options:scriptOptions];
    }
    return nil;
}

// - (id) initWithContentsOfFile:(NSString *)path {
//     return [self initWithContentsOfFile:path options:nil];
// }

- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    NSError * err = nil;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (BM_EXPECTED(scriptSource && !err, 1)) {
        BM_LOCK(isTemplate)
        self.isTemplate = NO;
        BM_UNLOCK(isTemplate)
        return [self initWithScriptSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"BMScript Error: Reading script source from file at '%@' failed: %@", path, [err localizedFailureReason]);
    }
    return nil;
}

- (id) initWithContentsOfTemplateFile:(NSString *)path {
    return [self initWithContentsOfTemplateFile:path options:nil];
}

- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    NSError * err;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (BM_EXPECTED(scriptSource != nil, 1)) {
        return [self initWithTemplateSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"BMScript Error: Reading script source from file at '%@' failed: %@", path, [err localizedFailureReason]);
    }
    return nil;
}


// MARK: Factory Methods

+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions { 
    return [[[self alloc] initWithScriptSource:scriptSource options:scriptOptions] autorelease]; 
}

+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfFile:path options:scriptOptions] autorelease];
}

+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfTemplateFile:path options:scriptOptions] autorelease];
}

// MARK: Private Methods

- (BOOL) setupTask {
    
    BM_PROBE(ENTER_SETUP_TASK, (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String]);

    BOOL success = NO;
    
    if (BM_EXPECTED([task isRunning], 0)) {
        [task terminate];
    } else {
       task = [[NSTask alloc] init];
       pipe = [[NSPipe alloc] init];
        
        if (task && pipe) {
            
            NSString * path = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
            
            // If BMSynthesizeOptions is called with "nil" as second argument 
            // that effectively sets up BMScriptOptionsTaskArgumentsKey as 
            // [NSArray arrayWithObjects:nil] which in turn becomes a "__NSArray0"
            if (!args || [NSStringFromClass([args class]) isEqualToString:@"__NSArray0"]) {
                NSLog(@"BMScript: Warning: array with no objects set as task arguments.\n args = %@, args class = %@", args, NSStringFromClass([args class]));
                args = [NSArray arrayWithObject:script];
            } else {
                args = [args arrayByAddingObject:script];
            }  
            
            [task setLaunchPath:path];
            [task setArguments:args];
            [task setStandardOutput:pipe];
            
            // Unfortunately we need the following define if we want to use SenTestingKit for unit testing. Since we are telling 
            // BMScript here to write to stdout and stderr SenTestingKit will actually output certain messages to stderr, messages
            // which can include the PID of the current task used for the testing. This invalidates testing task ouput from
            // two tasks even if their output is identical because their PID is not. To work around this, we can use a define which
            // will be set to 1 in the build settings for our unit tests via OTHER_CFLAGS and -DBMSCRIPT_UNIT_TESTS=1.
            if (!BMSCRIPT_UNIT_TEST) {
                //NSLog(@"BMScript: Info: setting [task standardError:pipe]");
                [task setStandardError:pipe];
            }
            success = YES;
        }
    }
    
    BM_PROBE(EXIT_SETUP_TASK, (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String]);
    
    return success; 
}

/* fires a one-off (blocking or synchroneous) task and stores the result */
- (TerminationStatus) launchTaskAndStoreResult {
    
    BM_PROBE(ENTER_LAUNCH_TASK_AND_STORE_LAST_RESULT, 
             (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String], 
             (char *) [[result quote] UTF8String]);
    
    TerminationStatus status;
    
    BM_LOCK(task)
    [task launch];
    NSData * data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    [task terminate];
    [[pipe fileHandleForReading] closeFile];
    [task release], task = nil;
    [pipe release], pipe = nil;
    BM_UNLOCK(task)

    BM_LOCK(gTaskStatus)
    gTaskStatus = status = [task terminationStatus];
    BM_UNLOCK(gTaskStatus)
    //gTaskStatus = BMAtomicCompareAndSwapInteger((NSInteger)-1, (NSInteger)status, (NSInteger *)&gTaskStatus);

    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString * aResult = string;
    
    BM_LOCK(result)
    BOOL shouldSetResult = YES;
    if ([delegate respondsToSelector:@selector(shouldSetResult:)]) {
        shouldSetResult = [delegate shouldSetResult:string];
    }
    if (shouldSetResult) {
        if ([delegate respondsToSelector:@selector(willSetResult:)]) {
            aResult = [delegate willSetResult:string];
        }
        self.result = aResult;
    }
    BM_UNLOCK(result)

    [string release], string = nil;

    BM_PROBE(EXIT_LAUNCH_TASK_AND_STORE_LAST_RESULT, 
             (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String], 
             (char *) [[result quote] UTF8String]);
    
    return status;
}

/* fires a one-off (non-blocking or asynchroneous) task and reels in the results 
   one after another thru notifications */
- (void) setupAndLaunchBackgroundTask {
    
    BM_PROBE(ENTER_SETUP_AND_LAUNCH_BACKGROUND_TASK, 
             (char *) [BMStringFromBOOL((bgTask == nil ? NO : [bgTask isRunning])) UTF8String], 
             (char *) [[result quote] UTF8String]);
    
    if (BM_EXPECTED([bgTask isRunning], 0)) {
        [bgTask terminate];
    } else {
        if (!bgTask) {
            
            // Create a task and pipe
            bgTask = [[NSTask alloc] init];
            bgPipe = [[NSPipe alloc] init];    
            
            NSString * path = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
            
            // If BMSynthesizeOptions is called with "nil" as second argument 
            // that effectively sets up BMScriptOptionsTaskArgumentsKey as 
            // [NSArray arrayWithObjects:nil] which in turn becomes an opaque 
            // object named "__NSArray0"
            if (BM_EXPECTED(!args || [NSStringFromClass([args class]) isEqualToString:@"__NSArray0"], 0)) {
                //NSLog(@"args = %@, args class = %@", args, NSStringFromClass([args class]));
                args = [NSArray arrayWithObject:script];
            } else {
                args = [args arrayByAddingObject:script];
            }  
            
            // set options for background task
            [bgTask setLaunchPath:path];
            [bgTask setArguments:args];
            [bgTask setStandardOutput:bgPipe];
            [bgTask setStandardError:bgPipe];
            
            // register for notifications
            
            // currently the execution model for background tasks is an incremental one:
            // self.partialResult is accumulated over the time the task is running and
            // posting NSFileHandleReadCompletionNotification notifications. This happens
            // through #dataReceived: which calls #appendData: until the NSTaskDidTerminateNotification 
            // is posted. Then, the partialResult is simply mirrored over to lastResult.
            // This gives the user the advantage for long running scripts to check partialResult
            // periodically and see if the task needs to be aborted.
            
            // [[NSNotificationCenter defaultCenter] addObserver:self 
            //                                          selector:@selector(dataComplete:) 
            //                                              name:NSFileHandleReadToEndOfFileCompletionNotification 
            //                                            object:bgTask];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(dataReceived:) 
                                                         name:NSFileHandleReadCompletionNotification 
                                                       object:[bgPipe fileHandleForReading]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(taskTerminated:) 
                                                         name:NSTaskDidTerminateNotification 
                                                       object:bgTask];
            
            [bgTask launch];
            
            BM_PROBE(EXIT_SETUP_AND_LAUNCH_BACKGROUND_TASK, 
                     (char *) [BMStringFromBOOL((bgTask == nil ? NO : [bgTask isRunning])) UTF8String], 
                     (char *) [[result quote] UTF8String]);

            // kick off pipe reading in background
            [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
            //[[bgPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
        }
    }
}

- (void) dataComplete:(NSNotification *)aNotification {
    BM_PROBE(ENTER_DATA_COMPLETE);

    NSData * data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    // NSNumber * errorCode = [[aNotification userInfo] valueForKey:@"NSFileHandleError"];
    if (BM_EXPECTED(data != nil, 1)) {
        
        NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString * aResult = string;
        
        BM_LOCK(result)
        BOOL shouldSetResult = YES;
        if ([delegate respondsToSelector:@selector(shouldSetResult:)]) {
            shouldSetResult = [delegate shouldSetResult:aResult];
        }
        if (shouldSetResult) {
            if ([delegate respondsToSelector:@selector(willSetResult:)]) {
                aResult = [delegate willSetResult:string];
            }
            self.result = aResult;
        }
        BM_UNLOCK(result)
        [string release], string = nil;
    } else {
        NSLog(@"BMScript Warning: %s attempted but could not append data because it is missing!", __PRETTY_FUNCTION__);
    }
    
    BM_PROBE(EXIT_DATA_COMPLETE, (char *) [result UTF8String]);
}


- (void) dataReceived:(NSNotification *)aNotification {
    BM_PROBE(ENTER_DATA_RECEIVED);
    
	NSData * data = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    // NSNumber * errorCode = [[aNotification userInfo] valueForKey:@"NSFileHandleError"];
    if (BM_EXPECTED([data length] > 0, 1)) {
        [self appendData:data];
        // fire again in background after each notification
        [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
    } else {
        [self stopTask];
    }
    BM_PROBE(EXIT_DATA_RECEIVED);
}


- (void) appendData:(NSData *)data {
    BM_PROBE(ENTER_APPEND_DATA);

    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (BM_EXPECTED(string != nil, 1)) {
        NSString * aPartial = string;
        BOOL shouldAppendPartial = YES;
        if ([delegate respondsToSelector:@selector(shouldAppendPartialResult:)]) {
            shouldAppendPartial = [delegate shouldAppendPartialResult:aPartial];
        }
        if (shouldAppendPartial) {
            if ([delegate respondsToSelector:@selector(willAppendPartialResult:)]) {
                aPartial = [delegate willAppendPartialResult:string];
            }
            BM_LOCK(partialResult)
            self.partialResult = [partialResult stringByAppendingString:aPartial];
            BM_UNLOCK(partialResult)
        }
    } else {
        NSLog(@"BMScript: Warning: Attempted %s but could not append to self.partialResult. Data maybe lost!", __PRETTY_FUNCTION__);
    }
    [string release], string = nil;
    
    BM_PROBE(EXIT_APPEND_DATA, (char *) [[partialResult quote] UTF8String]);
}

- (void) stopTask {
    BM_PROBE(ENTER_TASK_TERMINATED);
    
    // read out remaining data, as the pipes have a limited buffer size 
    // and may stall on subsequent calls if full
    NSData * dataInPipe = [[bgPipe fileHandleForReading] readDataToEndOfFile];
    if (BM_EXPECTED(dataInPipe && [dataInPipe length], 0)) {
        [self appendData:dataInPipe];
    }

    if(BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    
    BM_LOCK(gBgTaskStatus)
    gBgTaskStatus = [bgTask terminationStatus];
    BM_UNLOCK(gBgTaskStatus)
    
    // task is finished, copy over the accumulated partialResults into lastResult
    NSString * string = self.partialResult;
    NSString * aResult = string;
    
    BM_LOCK(result)
    BOOL shouldSetResult = YES;
    if ([delegate respondsToSelector:@selector(shouldSetResult:)]) {
        shouldSetResult = [delegate shouldSetResult:aResult];
    }
    if (shouldSetResult) {
        if ([delegate respondsToSelector:@selector(willSetResult:)]) {
            aResult = [delegate willSetResult:string];
        }
        self.result = aResult;
    }
    BM_UNLOCK(result)
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleReadCompletionNotification 
                                                  object:[bgPipe fileHandleForReading]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSTaskDidTerminateNotification 
                                                  object:bgTask];
    
    [[bgPipe fileHandleForReading] closeFile];
    [bgTask release], bgTask = nil;
    [bgPipe release], bgPipe = nil;
    
    BM_LOCK(self)
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:gBgTaskStatus], BMScriptNotificationTaskTerminationStatus, 
                                            result, BMScriptNotificationTaskResults, nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BMScriptTaskDidEndNotification 
                                                        object:self 
                                                      userInfo:info];
    BM_UNLOCK(self)
    
    BM_PROBE(END_BG_EXECUTE, (char *) [[result quote] UTF8String]);

    NSArray * historyItem = [NSArray arrayWithObjects:script, result, nil];
    BM_LOCK(history)
    if ([delegate respondsToSelector:@selector(shouldAddItemToHistory:)]) {
        if ([delegate shouldAddItemToHistory:historyItem]) {
            [history addObject:historyItem];
        }
    } else {
        [history addObject:historyItem];
    }
    BM_UNLOCK(history)
    
    if (BMSCRIPT_DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
    
    BM_PROBE(EXIT_TASK_TERMINATED, 
             (char *) [[lastResult quote] UTF8String], 
             (char *) [[partialResult quote] UTF8String]);
}

- (void) taskTerminated:(NSNotification *) aNotification { 
    #pragma unused(aNotification)
    [self stopTask]; 
}

// MARK: Templates

// TODO: add probes for template system

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    if (self.isTemplate) {
        BM_LOCK(script)
        self.script = [NSString stringWithFormat:script, tArg];
        self.isTemplate = NO;
        BM_UNLOCK(script)
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {    
    if (self.isTemplate) {
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

        // determine how many replacements we need to make
        NSInteger numTokens = [script countOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN];
        if (numTokens == NSNotFound) {
            return NO;
        }
        
        NSString * accumulator = self.script;
        NSString * arg;
        
        va_list arglist;
        va_start(arglist, firstArg);
        
        NSRange searchRange = NSMakeRange(0, [accumulator rangeOfString:BMSCRIPT_INSERTION_TOKEN].location + [BMSCRIPT_INSERTION_TOKEN length]);
        
        accumulator = [accumulator stringByReplacingOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN
                                                             withString:firstArg 
                                                                options:NSLiteralSearch 
                                                                  range:searchRange];
        
        while (--numTokens > 0) {
            arg = va_arg(arglist, NSString *);
            searchRange = NSMakeRange(0, [accumulator rangeOfString:BMSCRIPT_INSERTION_TOKEN].location + [BMSCRIPT_INSERTION_TOKEN length]);
            accumulator = [accumulator stringByReplacingOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN
                                                                 withString:arg 
                                                                    options:NSLiteralSearch 
                                                                      range:searchRange];
            if (numTokens <= 1) break;
        }
        
        va_end(arglist);
        
        BM_LOCK(script)
        self.script = [accumulator stringByReplacingOccurrencesOfString:@"%%" withString:@"%"];
        self.isTemplate = NO;
        BM_UNLOCK(script)

        [pool drain];
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary {
    if (self.isTemplate) {
        
        NSString * accumulator = self.script;
        
        NSArray * keys = [dictionary allKeys];
        NSArray * values = [dictionary allValues];
        
        NSInteger i = 0;
        for (NSString * key in keys) {
            accumulator = [accumulator stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%{"BMSCRIPT_INSERTION_TOKEN"}", key ] 
                                                                 withString:[values objectAtIndex:i]];
            i++;
        }
        
        BM_LOCK(script)
        self.script = [accumulator stringByReplacingOccurrencesOfString:@"%" withString:@""];
        self.isTemplate = NO;
        BM_UNLOCK(script)
        
        return YES;
    }
    return NO;
}



// MARK: Execution

- (BOOL) execute {
    
    BM_PROBE(ENTER_EXECUTE, 
             (char *) [[script quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[options objectForKey:BMScriptOptionsTaskLaunchPathKey] UTF8String]);
    
    BOOL success = NO;
    
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];

    } else {
        if ([self executeAndReturnResult:nil]) {
            success = YES;
        }
    }
    
    BM_PROBE(EXIT_EXECUTE, (char *) [[result quote] UTF8String]);
    return success;
}

- (BOOL) executeAndReturnResult:(NSString **)results {
    
    BM_PROBE(ENTER_EXECUTE_AND_RETURN_RESULT, 
             (char *) [[script quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[options objectForKey:BMScriptOptionsTaskLaunchPathKey] UTF8String]);
    
    BOOL success = NO;
    
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];
    } else {
        if ([self executeAndReturnResult:results error:nil] == YES) {
            success = YES;
        }
    }
    
    BM_PROBE(EXIT_EXECUTE_AND_RETURN_RESULT, 
             (char *) [[result quote] UTF8String]);
    
    return success;
}

- (BOOL) executeAndReturnResult:(NSString **)results error:(NSError **)error {
    
    BM_PROBE(ENTER_EXECUTE_AND_RETURN_RESULT_ERROR,
             (char *) [[[self script] quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[task launchPath] UTF8String]);
    
    BM_PROBE(START_NET_EXECUTE, 
             (char *) [[script quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[task launchPath] UTF8String]);
    
    BOOL success = NO;
    TerminationStatus status;
    
    if (self.isTemplate) {
        if (error) {
            NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"BMScript Error: Please define all replacement values for the current template "
                                                   @"by calling one of the -saturateTemplate... methods prior to execution" 
                                            forKey:NSLocalizedFailureReasonErrorKey];
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
        } else {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"BMScript Error: Please define all replacement values for the current template "
                                                  @"by calling one of the -saturateTemplate... methods prior to execution" 
                                         userInfo:nil];            
        }            
    } else {// isTemplate is NO
        
        BM_LOCK(self)
        success = [self setupTask];
        BM_UNLOCK(self)
        
        if (BM_EXPECTED(success, 1)) {
            
            BM_LOCK(self)
            status = [self launchTaskAndStoreResult];
            BM_UNLOCK(self)
            
            BOOL strictBit = NO;
            NSNumber * num = [options objectForKey:BMScriptOptionsStrictTerminationStatusInterpretationKey];
            
            if (num) strictBit = [num boolValue];

            if ((strictBit && (status == BMScriptFinishedSuccessfullyTerminationStatus)) 
                || (!strictBit && (status > BMScriptNotExecutedTerminationStatus))) {
                
                if (BM_EXPECTED(results != nil, 1)) *results = result;
                
                BM_LOCK(history)
                NSArray * historyItem = [NSArray arrayWithObjects:script, result, nil];
                if ([delegate respondsToSelector:@selector(shouldAddItemToHistory:)]) {
                    if ([delegate shouldAddItemToHistory:historyItem]) {
                        [history addObject:historyItem];
                    }
                } else {
                    [history addObject:historyItem];
                }
                BM_UNLOCK(history)
                if (BMSCRIPT_DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
                success = YES;
            } else {
                if (error) {
                    NSString * availableResults = [[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] 
                                                                        encoding:NSUTF8StringEncoding];
                    NSString * reason = [NSString stringWithFormat:@"BMScript task returned with non-zero exit status: %@", availableResults];
                    [availableResults release], availableResults = nil;
                    [[pipe fileHandleForReading] closeFile];
                    
                    NSDictionary * errorDict = [NSDictionary dictionaryWithObject:reason
                                                                           forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
                }
            }
        } else {
            if (error) {
                NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"script task setup failed" 
                                            forKey:NSLocalizedFailureReasonErrorKey];
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
            }
        }
    }
    
    BM_PROBE(END_NET_EXECUTE, (char *) [[result quote] UTF8String]);
    BM_PROBE(EXIT_EXECUTE_AND_RETURN_RESULT_ERROR, (char *) [[result quote] UTF8String]);

    return success;
}


- (void) executeInBackgroundAndNotify {
    if (self.isTemplate) {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
    }
    
    BM_PROBE(START_BG_EXECUTE, 
             (char *) [[script quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[options objectForKey:BMScriptOptionsTaskLaunchPathKey] UTF8String]);
    
    [self setupAndLaunchBackgroundTask];
    
}

// MARK: History

// TODO add probes for history system

- (NSString *) scriptSourceFromHistoryAtIndex:(NSInteger)index {
    
    BM_PROBE(ENTER_SCRIPT_SOURCE_FROM_HISTORY_AT_INDEX, index, (int) [history count]);
    NSString * aScript = nil;
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:0];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aScript = item;
            }
        } else {
            aScript = item;
        }
    }
    BM_PROBE(EXIT_SCRIPT_SOURCE_FROM_HISTORY_AT_INDEX, (char *) [[aScript quote] UTF8String], (int) [history count]);
    return aScript;
}

- (NSString *) resultFromHistoryAtIndex:(NSInteger)index {

    BM_PROBE(ENTER_RESULT_FROM_HISTORY_AT_INDEX, index, (int) [history count]);
    NSString * aResult = nil;
    if ([history count] > 0) {
        NSString * item = [[history objectAtIndex:index] objectAtIndex:1];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aResult = item;
            }
        } else {
            aResult = item;
        }
    }
    BM_PROBE(EXIT_RESULT_FROM_HISTORY_AT_INDEX, (char *) [[aResult quote] UTF8String], (int) [history count]);
    return aResult;
}

- (NSString *) lastScriptSourceFromHistory {
    
    BM_PROBE(ENTER_LAST_SCRIPT_SOURCE_FROM_HISTORY, (int) [history count]);
    NSString * aScript = nil;
    if ([history count] > 0) {
        NSString * item = [[history lastObject] objectAtIndex:0];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aScript = item;
            }
        } else {
            aScript = item;
        }
    }
    BM_PROBE(EXIT_LAST_SCRIPT_SOURCE_FROM_HISTORY, (char *) [[aScript quote] UTF8String], (int) [history count]);
    return aScript;
}

- (NSString *) lastResultFromHistory {
    
    BM_PROBE(ENTER_LAST_RESULT_FROM_HISTORY, (int) [history count]);
    NSString * aResult = nil;
    if ([history count] > 0) {
        NSString * item = [[history lastObject] objectAtIndex:1];
        if ([delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([delegate shouldReturnItemFromHistory:item]) {
                aResult = item;
            }
        } else {
            aResult = item;
        }
    }
    BM_PROBE(EXIT_LAST_RESULT_FROM_HISTORY, (char *) [[aResult quote] UTF8String], (int) [history count]);
    return aResult;
}

// MARK: Equality

- (BOOL) isEqualToScript:(BMScript *)other {
    return [script isEqualToString:other.script];
}

- (BOOL) isEqual:(BMScript *)other {
    BOOL sameScript = [script isEqualToString:other.script];
    BOOL sameLaunchPath = [[options objectForKey:BMScriptOptionsTaskLaunchPathKey] 
                           isEqualToString:[other.options objectForKey:BMScriptOptionsTaskLaunchPathKey]];
    return sameScript && sameLaunchPath;
}

// MARK: BMScriptDelegate

- (BOOL) shouldAddItemToHistory:(NSArray *)anItem { 
    #pragma unused(anItem)
    BMSCRIPT_DELEGATE_METHOD_TRACE return YES; 
}
- (BOOL) shouldReturnItemFromHistory:(NSString *)anItem { 
    #pragma unused(anItem)
    BMSCRIPT_DELEGATE_METHOD_TRACE return YES; 
}
- (BOOL) shouldAppendPartialResult:(NSString *)string { 
    #pragma unused(string)
    BMSCRIPT_DELEGATE_METHOD_TRACE return YES; 
}
- (BOOL) shouldSetResult:(NSString *)aString { 
    #pragma unused(aString)
    BMSCRIPT_DELEGATE_METHOD_TRACE return YES; 
}
- (BOOL) shouldSetScript:(NSString *)aScript { 
    #pragma unused(aScript)
    BMSCRIPT_DELEGATE_METHOD_TRACE return YES; 
}
- (BOOL) shouldSetOptions:(NSDictionary *)opts { 
    #pragma unused(opts)
    BMSCRIPT_DELEGATE_METHOD_TRACE return YES; 
}

- (NSString *) willAddItemToHistory:(NSString *)anItem { BMSCRIPT_DELEGATE_METHOD_TRACE return anItem; }
- (NSString *) willReturnItemFromHistory:(NSString *)anItem { BMSCRIPT_DELEGATE_METHOD_TRACE return anItem; }
- (NSString *) willAppendPartialResult:(NSString *)string { BMSCRIPT_DELEGATE_METHOD_TRACE return string; }
- (NSString *) willSetResult:(NSString *)aString { BMSCRIPT_DELEGATE_METHOD_TRACE return aString; }
- (NSString *) willSetScript:(NSString *)aScript { BMSCRIPT_DELEGATE_METHOD_TRACE return aScript; }
- (NSDictionary *) willSetOptions:(NSDictionary *)opts { BMSCRIPT_DELEGATE_METHOD_TRACE return opts; }

// MARK BMScriptLanguage

// Currently unused as BMScriptLanguageProtocol was initially intended for subclasses
// It might change again but that's the status at the time of writing

//- (NSDictionary *) defaultOptionsForLanguage {
//     NSDictionary * opts = BMSynthesizeOptions(@"/bin/echo", @"");
//     return opts;
//}

//- (NSString *) defaultScriptSourceForLanguage {
//     return @"BMScript running default task (/bin/echo) with this message as script source.\n"
//            @"If you want to customize BMScript you can create a subclass easily with help of the BMScriptLanguageProtocol\n "
//            @"which describes a required method for supplying the default options dictionary and some optional methods.\n "
//            @"You can also call one of BMScript's many initializer and convenience factory methods to provide default options\n "
//            @"such as task launch path and arguments and a default script to execute.\n";  
//    return nil;
//}

// MARK: NSCopying

- (id)copyWithZone:(NSZone *)zone {
    #pragma unused(zone)
    return [self retain];
}

// MARK: NSMutableCopying

- (id) mutableCopyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithScriptSource:self.script
                                                              options:self.options ];
    return copy;
}

// MARK: NSCoding

- (void) encodeWithCoder:(NSCoder *)coder { 
    [coder encodeObject:script];
    [coder encodeObject:result];
    [coder encodeObject:options];
    [coder encodeObject:history];
    [coder encodeObject:task];
    [coder encodeObject:pipe];
    [coder encodeObject:bgTask];
    [coder encodeObject:bgPipe];
    [coder encodeObject:delegate];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
}


- (id) initWithCoder:(NSCoder *)coder { 
    if ((self = [super init])) { 
        //int version = [coder versionForClassName:NSStringFromClass([self class])]; 
        //NSLog(@"class version = %i", version);
        script      = [[coder decodeObject] retain];
        result      = [[coder decodeObject] retain];
        options     = [[coder decodeObject] retain];
        history     = [[coder decodeObject] retain];
        task        = [[coder decodeObject] retain];
        pipe        = [[coder decodeObject] retain];
        bgTask      = [[coder decodeObject] retain];
        bgPipe      = [[coder decodeObject] retain];
        delegate    = [[coder decodeObject] retain];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
        
    }
    return self;
}

@end

@implementation BMScript (CommonScriptLanguagesFactories)

// Ruby

+ (id) rubyScriptWithSource:(NSString *)scriptSource {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) rubyScriptWithContentsOfFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Python 

+ (id) pythonScriptWithSource:(NSString *)scriptSource {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) pythonScriptWithContentsOfFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Perl

+ (id) perlScriptWithSource:(NSString *)scriptSource {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) perlScriptWithContentsOfFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

@end


#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
@implementation NSString (BMScriptNSString10_4Compatibility)

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts range:(NSRange)searchRange {
    NSMutableString * str = [NSMutableString stringWithString:self];
    [str replaceOccurrencesOfString:target withString:replacement options:opts range:searchRange];
    return (NSString *)str;
}

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement {
    NSRange searchRange = NSMakeRange(0, [self length]);
    NSMutableString * str = [NSMutableString stringWithString:self];
    [str replaceOccurrencesOfString:target withString:replacement options:0 range:searchRange];
    return (NSString *)str;
}

@end
#endif

@implementation NSString (BMScriptStringUtilities)

- (NSString *) quote {
    
    NSString * quotedResult = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
       quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"%"  withString:@"%%"];
    
    return quotedResult;
}

- (NSString *) wrapSingleQuotes { 
    return [NSString stringWithFormat:@"'%@'", self]; 
}

- (NSString *) wrapDoubleQuotes {
    return [NSString stringWithFormat:@"\"%@\"", self]; 
}


- (NSString *) truncate {
    #ifdef BM_NSSTRING_TRUNCATE_LENGTH
        NSUInteger len = BM_NSSTRING_TRUNCATE_LENGTH;
    #else
        NSUInteger len = 20;
    #endif
    if ([self length] < len) {
        return self;
    }
    return [self truncateToLength:len];
}

- (NSString *) truncateToLength:(NSUInteger)len {
    if ([self length] < len) {
        return self;
    }
    return [[self substringWithRange:(NSMakeRange(0, len))] stringByAppendingString:@"..."];
}

- (NSInteger) countOccurrencesOfString:(NSString *)aString {
    NSInteger num = ((NSInteger)[[NSArray arrayWithArray:[self componentsSeparatedByString:aString]] count] - 1);
    if (num > 0) {
        return num;
    }
    return NSNotFound;
}

@end

@implementation NSDictionary (BMScriptUtilities)

- (NSDictionary *) dictionaryByAddingObject:(id)object forKey:(id)key {
    NSArray * keys = [[self allKeys] arrayByAddingObject:key];
    NSArray * values = [[self allValues] arrayByAddingObject:object];
    return [NSDictionary dictionaryWithObjects:values forKeys:keys];
}

@end

@implementation NSObject (BMScriptUtilities)

+ (BOOL) isDescendantOfClass:(Class)anotherClass {
    id instance = [self new];
    BOOL result = [instance isDescendantOfClass:anotherClass];
    [instance release], instance = nil;
    return result;
}

- (BOOL) isDescendantOfClass:(Class)anotherClass {
    return (!([[self class] isEqual:anotherClass]) && [self isKindOfClass:anotherClass]);
}

@end


///@endcond

