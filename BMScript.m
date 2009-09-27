//
//  BMScript.m
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  For license details see end of this file.
//  Short version: licensed under MIT license.
//

#import "BMScript.h"
#import "BMScriptProbes.h"  /* dtrace probes auto-generated from .d file(s) */

#include <unistd.h>         /* for usleep       */
#include <pthread.h>        /* for pthread_*    */

#ifndef BMSCRIPT_DEBUG_MEMORY
#define BMSCRIPT_DEBUG_MEMORY  0
#endif
#ifndef BMSCRIPT_DEBUG_HISTORY
#define BMSCRIPT_DEBUG_HISTORY 0
#endif
#ifndef BMSCRIPT_DEBUG_OBJECTS
#define BMSCRIPT_DEBUG_OBJECTS 0
#endif
#ifndef BMSCRIPT_DEBUG_INIT
#define BMSCRIPT_DEBUG_INIT    0
#endif
#ifndef BMSCRIPT_DEBUG_DELEGATE_METHODS
#define BMSCRIPT_DEBUG_DELEGATE_METHODS 0
#endif

#if (BMSCRIPT_DEBUG_DELEGATE_METHODS)
    #define BMSCRIPT_DELEGATE_METHOD_TRACE NSLog(@"Inside %s", __PRETTY_FUNCTION__);
#else
    #define BMSCRIPT_DELEGATE_METHOD_TRACE
#endif

#if (BMSCRIPT_DEBUG_OBJECTS)
    #define BMSCRIPT_OBJECT_TRACE NSLog(@"Creating object %@", [super description]);
#else
    #define BMSCRIPT_OBJECT_TRACE
#endif

#if (BMSCRIPT_DEBUG_INIT)
    #define BMSCRIPT_INIT_TRACE NSLog(@"Initializing object %@ with:\n %@", [super description], [self debugDescription]);
#else
    #define BMSCRIPT_INIT_TRACE
#endif


#define BMSCRIPT_INSERTION_TOKEN @"%@"          /* used by templates to mark locations where a replacement insertions should occur */
#define NSSTRING_TRUNCATE_LENGTH 20             /* used by -truncate, defined in NSString (BMScriptUtilities) */

// #define INCONSISTENCY_REASON(_X_) ([NSString stringWithFormat:@"Decendants of BMScript must not call %s directly. "\
//                                                               @"It is called as needed by the execution methods of BMScript. "\
//                                                               @"Trying to set %@ directly causes internal inconsistencies.",\
//                                                               __PRETTY_FUNCTION__, (_X_)])

#define RETAIN_COUNT_FOOTPRINT {\
    NSLog(@"inside %s of instance %@", __PRETTY_FUNCTION__, [super description]);\
    NSLog(@"------------------------------");\
    [self printRetainCounts];\
    NSLog(@"------------------------------");\
}
    
#if BMSCRIPT_THREAD_SAFE
    #if BMSCRIPT_FAST_LOCK
        #define BMSCRIPT_LOCK \
        BM_PROBE(ACQUIRE_LOCK_START, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]); \
        static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER; \
        if (pthread_mutex_lock(&mtx)) {\
            printf("*** Warning: Lock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }
        #define BMSCRIPT_UNLOCK \
        if ((pthread_mutex_unlock(&mtx) != 0)) {\
            printf("*** Warning: Unlock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }\
        BM_PROBE(ACQUIRE_LOCK_END, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);
    #else
        #define BMSCRIPT_LOCK \
        BM_PROBE(ACQUIRE_LOCK_START, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);\
        @synchronized(self) {
        #define BMSCRIPT_UNLOCK }\
        BM_PROBE(ACQUIRE_LOCK_END, (char *) [BMStringFromBOOL(BMSCRIPT_FAST_LOCK) UTF8String]);
    #endif
#else 
    #define BMSCRIPT_LOCK
    #define BMSCRIPT_UNLOCK
#endif

#define ap_start NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_3
    #define ap_end   [pool drain];
#else
    #define ap_end   [pool release];
#endif


NSString * const BMScriptOptionsTaskLaunchPathKey = @"BMScriptOptionsTaskLaunchPathKey";
NSString * const BMScriptOptionsTaskArgumentsKey  = @"BMScriptOptionsTaskArgumentsKey";
NSString * const BMScriptOptionsRubyVersionKey    = @"BMScriptOptionsRubyVersionKey"; /* currently unused */

NSString * const BMScriptTaskDidEndNotification                   = @"BMScriptTaskDidEndNotification";
NSString * const BMScriptNotificationInfoTaskResultsKey           = @"BMScriptNotificationInfoTaskResultsKey";
NSString * const BMScriptNotificationInfoTaskTerminationStatusKey = @"BMScriptNotificationInfoTaskTerminationStatusKey";

NSString * const BMScriptTemplateArgumentMissingException  = @"BMScriptTemplateArgumentMissingException";
NSString * const BMScriptTemplateArgumentsMissingException = @"BMScriptTemplateArgumentsMissingException";

NSString * const BMScriptLanguageProtocolDoesNotConformException = @"BMScriptLanguageProtocolDoesNotConformException";
NSString * const BMScriptLanguageProtocolMethodMissingException  = @"BMScriptLanguageProtocolMethodMissingException";
NSString * const BMScriptLanguageProtocolIllegalAccessException  = @"BMScriptLanguageProtocolIllegalAccessException";

// MARK: File Statics (Globals)

//static BOOL s_isTemplate;
//static BOOL s_hasDelegate;

static TerminationStatus s_taskStatus = BMScriptNotExecutedTerminationStatus;
static TerminationStatus s_bgTaskStatus = BMScriptNotExecutedTerminationStatus;

@interface BMScript (Private)

- (BOOL) setupTask;
- (TerminationStatus) launchTaskAndStoreLastResult;
- (void) setupAndLaunchBackgroundTask;
- (void) taskTerminated:(NSNotification *)aNotification;
- (void) appendData:(NSData *)d;
- (void) dataComplete:(NSNotification *)aNotification;
- (void) dataReady:(NSNotification *)aNotification;

// MARK: Protected Accessors

- (NSTask *) task;
- (void) setTask:(NSTask *)newTask;
- (NSPipe *) pipe;
- (void)setOutPipe:(NSPipe *)newOutPipe;
- (NSThread *) bgThread;
- (void) setBgThread: (NSThread *)newBgThread;
- (NSPipe *) bgPipe;
- (void) setBgPipe:(NSPipe *)newBgPipe;
- (BOOL) isTemplate;
- (void) setIsTemplate:(BOOL)flag;

- (NSString *) partialResult;
- (void) setPartialResult:(NSString *)newPartialResult;
- (void) setLastResult:(NSString *)newLastResult;
- (void) setHistory:(NSMutableArray *)newHistory;

@end


@implementation BMScript

// MARK: Accessor Definitions

//=========================================================== 
//  script 
//=========================================================== 
- (NSString *)script {
    return [[script retain] autorelease]; 
}

- (void)setScript:(NSString *)newScript {
    if (script != newScript) {
        if ([[self delegate] respondsToSelector:@selector(shouldSetScript:)]) {
            if ([[self delegate] shouldSetScript:newScript]) {
                [script release];
                script = [newScript retain];
            }
        } else {
            [script release];
            script = [newScript retain];
        }
    }
}

//=========================================================== 
//  lastResult 
//=========================================================== 
- (NSString *)lastResult {
    return [[lastResult retain] autorelease]; 
}

- (void)setLastResult:(NSString *)newLastResult {
    BMSCRIPT_LOCK
    //NSLog(@"Inside %@ %s:", (bgTask ? [super description] : @""), __PRETTY_FUNCTION__); 
    if (lastResult != newLastResult) {
        //NSLog(@"lastResult was '%@', will set to '%@'", [[lastResult quote] truncate], [[newLastResult quote] truncate]);
        [lastResult release];
        lastResult = [newLastResult retain];
    }
    BMSCRIPT_UNLOCK
    
}

//=========================================================== 
//  options 
//=========================================================== 
- (NSDictionary *)options {
    return [[options retain] autorelease]; 
}

- (void)setOptions:(NSDictionary *)newOptions {
    if (options != newOptions) {
        NSDictionary * item = [newOptions retain];
        if ([[self delegate] respondsToSelector:@selector(shouldSetOptions:)]) {
            if ([[self delegate] shouldSetOptions:item]) {
                [options release];
                options = item;
            }
        } else {
            [options release];
            options = item;
        }
    }
    
}

//=========================================================== 
//  history 
//=========================================================== 
- (NSMutableArray *)history {
    NSMutableArray * result;
    BMSCRIPT_LOCK
    result = [[history retain] autorelease];
    BMSCRIPT_UNLOCK
    return result;
}

- (void)setHistory:(NSMutableArray *)newHistory {
    BMSCRIPT_LOCK
    if (history != newHistory) {
        [history release];
        history = [newHistory retain];
    }
    BMSCRIPT_UNLOCK
    
}

//=========================================================== 
//  task 
//=========================================================== 
- (NSTask *)task {
    return [[task retain] autorelease]; 
}

- (void)setTask:(NSTask *)newTask {
    if (task != newTask) {
        [task release];
        task = [newTask retain];
    }
    
}

//=========================================================== 
//  pipe 
//=========================================================== 
- (NSPipe *)pipe {
    return [[pipe retain] autorelease]; 
}

- (void)setPipe:(NSPipe *)newPipe {
    if (pipe != newPipe) {
        [pipe release];
        pipe = [newPipe retain];
    }
    
}

//=========================================================== 
//  defaultScript 
//=========================================================== 
// - (NSString *)defaultScript {
//     return [[defaultScript copy] autorelease]; 
// }
// 
// - (void)setDefaultScript:(NSString *)newDefaultScript {
//     if (defaultScript != newDefaultScript) {
//         [defaultScript release];
//         defaultScript = [newDefaultScript copy];
//     }
// }

//=========================================================== 
//  defaultOptions 
//=========================================================== 
// - (NSDictionary *)defaultOptions {
//     return [[defaultOptions retain] autorelease]; 
// }
// 
// - (void)setDefaultOptions:(NSDictionary *)newDefaultOptions {
//     if (defaultOptions != newDefaultOptions) {
//         [defaultOptions release];
//         defaultOptions = [newDefaultOptions retain];
//     }
// }

//=========================================================== 
//  bgTask 
//=========================================================== 
- (NSTask *)bgTask {
    return [[bgTask retain] autorelease]; 
}

- (void)setBgTask:(NSTask *)newBgTask {
    if (bgTask != newBgTask) {
        [bgTask release];
        bgTask = [newBgTask retain];
    }
    
}

//=========================================================== 
//  bgPipe 
//=========================================================== 
- (NSPipe *)bgPipe {
    return [[bgPipe retain] autorelease]; 
}

- (void)setBgPipe:(NSPipe *)newBgPipe {
    if (bgPipe != newBgPipe) {
        [bgPipe release];
        bgPipe = [newBgPipe retain];
    }
    
}

//=========================================================== 
//  partialResult 
//=========================================================== 
- (NSString *)partialResult {
    return [[partialResult retain] autorelease];
}
- (void)setPartialResult:(NSString *)newPartialResult {
    BMSCRIPT_LOCK
    if (partialResult != newPartialResult) {
        if ([[self delegate] respondsToSelector:@selector(shouldAppendPartialResult:)]) {
            if ([[self delegate] shouldAppendPartialResult:newPartialResult]) {
                [partialResult release];
                partialResult = [newPartialResult retain];
            }
        } else {
            [partialResult release];
            partialResult = [newPartialResult retain];
        }
    }
    BMSCRIPT_UNLOCK
}

//=========================================================== 
//  delegate 
//=========================================================== 
- (id<BMScriptDelegateProtocol>)delegate {
    return delegate; 
}

- (void)setDelegate:(id<BMScriptDelegateProtocol>)newDelegate {
    BMSCRIPT_LOCK
    if (delegate != newDelegate) {
        delegate = newDelegate;
    }
    BMSCRIPT_UNLOCK
}

//=========================================================== 
//  isTemplate 
//=========================================================== 
- (BOOL)isTemplate {
    return isTemplate;
}

- (void)setIsTemplate:(BOOL)flag {
    BMSCRIPT_LOCK
    isTemplate = flag;
    BMSCRIPT_UNLOCK
}



// MARK: Deallocation

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if ([task isRunning]) {
        [task terminate];
    }
    
    if ([bgTask isRunning]) {
        [bgTask terminate];
    }
    
    [script release], script = nil;
    [history release], history = nil;
    [options release], options = nil;
    [lastResult release], lastResult = nil;
    [partialResult release], partialResult = nil;
    [task release], task = nil;
    [pipe release], pipe = nil;
    [bgTask release], bgTask = nil;
    [bgPipe release], bgPipe = nil;
            
    [super dealloc];
}

// MARK: Description

- (NSString *) description {
    return [NSString stringWithFormat:@"%@,\n script: '%@',\n lastResult: '%@',\n delegate: %@,\n options: %@", 
            [super description], [script quote], [lastResult quote], (delegate == self? (id)@"self" : delegate), [options descriptionInStringsFileFormat]];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@,\n history (%d items): %@,\n task: %@,\n pipe: %@,\n bgTask: %@,\n bgPipe: %@", 
            [self description], [history count], history, task, pipe, bgTask, bgPipe ];
}

// MARK: Initializer Methods

- (id)init {
    return [self initWithScriptSource:nil options:nil]; 
}

- (id) initWithScriptSource:(NSString *)scriptSource { 
    return [self initWithScriptSource:scriptSource options:nil]; 
}

/* designated initializer */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions {
    
    if ([[self superclass] isEqual:[BMScript class]] && ![self conformsToProtocol:@protocol(BMScriptLanguageProtocol)]) {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolDoesNotConformException 
                                       reason:@"descendants of BMScript must conform to the BMScriptLanguageProtocol" 
                                     userInfo:nil];
    }
    
    if (self = [super init]) {
        if (scriptSource) {
            script = [scriptSource retain];
        } else {
            if ([self respondsToSelector:@selector(defaultScriptSourceForLanguage)]) {
                script = [[self performSelector:@selector(defaultScriptSourceForLanguage)] retain];
            } else {
                script = @"<script source placeholder>";
            }
        }

        if (scriptOptions) {
            options = [scriptOptions retain];
        } else {
            if ([[self superclass] isEqual:[BMScript class]] && ![self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                               reason:@"descendants of BMScript must implement -[defaultOptionsForLanguage]" 
                                             userInfo:nil];
            } else if ([self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                options = [[self performSelector:@selector(defaultOptionsForLanguage)] retain];
            } else {
                NSDictionary * defaultOptions = BMSynthesizeOptions(@"/bin/echo", nil);
                options = [defaultOptions retain];
            }
            
        }
        
        history = [[NSMutableArray alloc] init];
        lastResult = [[NSString alloc] init];
        partialResult = [[NSString alloc] init];
        
        // tasks/pipes will be allocated & initialized as needed
        task = nil;
        pipe = nil;
        bgTask = nil;
        bgPipe = nil;
        
        if ([self conformsToProtocol:@protocol(BMScriptDelegateProtocol)]) {
            delegate = self;
        }
        
        BMSCRIPT_INIT_TRACE
    }
    return self;
}

- (id) initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfFile:path options:nil];
}

- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    NSError * err;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (scriptSource) {
        self.isTemplate = NO;
        return [self initWithScriptSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"Error reading file at %@\n%@", path, [err localizedFailureReason]);
    }
    return nil;
}

- (id) initWithContentsOfTemplateFile:(NSString *)path {
    return [self initWithContentsOfTemplateFile:path options:nil];
}

- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    NSError * err;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (scriptSource) {
        self.isTemplate = YES;
        scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
        scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%%{}" withString:@"%%{"BMSCRIPT_INSERTION_TOKEN"}"];
        return [self initWithScriptSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"Error reading file at %@\n%@", path, [err localizedFailureReason]);
    }
    return nil;
}


// MARK: Factory Methods

// + (id) scriptWithSource:(NSString *)scriptSource { 
//     return [[[self alloc] initWithScriptSource:scriptSource options:nil] autorelease]; 
// }

+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions { 
    return [[[self alloc] initWithScriptSource:scriptSource options:scriptOptions] autorelease]; 
}

// + (id) scriptWithContentsOfFile:(NSString *)path {
//     return [[[self alloc] initWithContentsOfFile:path options:nil] autorelease];
// }

+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfFile:path options:scriptOptions] autorelease];
}

// + (id) scriptWithContentsOfTemplateFile:(NSString *)path {
//     return [[[self alloc] initWithContentsOfTemplateFile:path options:nil] autorelease];
// }

+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfTemplateFile:path options:scriptOptions] autorelease];
}

// MARK: Private Methods

- (BOOL) setupTask {
    
    BM_PROBE(ENTER_SETUP_TASK, 
             (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String]);

    BOOL success = NO;
    
    if ([task isRunning]) {
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
                //NSLog(@"args = %@, args class = %@", args, NSStringFromClass([args class]));
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
            #if BMSCRIPT_UNIT_TESTS != 1
                [task setStandardError:pipe];
                //NSLog(@"[task setStandardError:pipe]");
            #endif
            
            success = YES;
        }
    }
    
    BM_PROBE(EXIT_SETUP_TASK, 
             (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String]);
    
    return success; 
}

/* fires a one-off (blocking or synchroneous) task and stores the result */
- (TerminationStatus) launchTaskAndStoreLastResult {
    
    BM_PROBE(ENTER_LAUNCH_TASK_AND_STORE_LAST_RESULT, 
             (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String], 
             (char *) [[lastResult quote] UTF8String]);
    
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    [task launch];
    NSData * data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    status = [task terminationStatus];
    
    BMSCRIPT_LOCK
    s_taskStatus = status;
    BMSCRIPT_UNLOCK
    
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([[self delegate] respondsToSelector:@selector(shouldSetLastResult:)]) {
        if ([[self delegate] shouldSetLastResult:string]) {
            self.lastResult = string;
        }
    } else {
        self.lastResult = string;
    }
    
    [task terminate];
    [task release], task = nil;
    [pipe release], pipe = nil;
    [string release];

    BM_PROBE(EXIT_LAUNCH_TASK_AND_STORE_LAST_RESULT, 
             (char *) [BMStringFromBOOL((task == nil ? NO : [task isRunning])) UTF8String], 
             (char *) [[lastResult quote] UTF8String]);
    
    return status;
}

/* fires a one-off (non-blocking or asynchroneous) task and reels in the results 
   one after another thru notifications */
- (void) setupAndLaunchBackgroundTask {
    
    BM_PROBE(ENTER_SETUP_AND_LAUNCH_BACKGROUND_TASK, 
             (char *) [BMStringFromBOOL((bgTask == nil ? NO : [bgTask isRunning])) UTF8String], 
             (char *) [[lastResult quote] UTF8String]);
    
    if ([bgTask isRunning]) {
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
            if (!args || [NSStringFromClass([args class]) isEqualToString:@"__NSArray0"]) {
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
            // through #dataReady: which calls #appendData: until the NSTaskDidTerminateNotification 
            // is posted. Then, the partialResult is simply mirrored over to lastResult.
            // This gives the user the advantage for long running scripts to check partialResult
            // periodically and see if the task needs to be aborted.
//             [[NSNotificationCenter defaultCenter] addObserver:self 
//                                                      selector:@selector(dataReady:) 
//                                                          name:NSFileHandleReadCompletionNotification 
//                                                        object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(dataComplete:) 
                                                         name:NSFileHandleReadToEndOfFileCompletionNotification 
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(taskTerminated:) 
                                                         name:NSTaskDidTerminateNotification 
                                                       object:nil];
            
            [bgTask launch];
            
            BM_PROBE(EXIT_SETUP_AND_LAUNCH_BACKGROUND_TASK, 
                     (char *) [BMStringFromBOOL((bgTask == nil ? NO : [bgTask isRunning])) UTF8String], 
                     (char *) [[lastResult quote] UTF8String]);

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
    if (data) {
        NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (string) {
            if ([[self delegate] respondsToSelector:@selector(shouldSetLastResult:)]) {
                if ([[self delegate] shouldSetLastResult:string]) {
                    self.lastResult = [lastResult stringByAppendingString:string];
                }
            } else {
                self.lastResult = [lastResult stringByAppendingString:string];
            }
        } else {
            NSLog(@"*** Warning: -[appendData:] attempted but could not append to self.lastResult. Data maybe lost!");
        }
        [string release];
    }
    
    BM_PROBE(EXIT_DATA_COMPLETE, 
             (char *) [lastResult UTF8String]);
}

- (void) dataReady:(NSNotification *)aNotification {
    
    BM_PROBE(ENTER_DATA_READY);
    
	NSData * data = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    // NSNumber * errorCode = [[aNotification userInfo] valueForKey:@"NSFileHandleError"];
    if ([data length]) {
        [self appendData:data];
    }
    
    BM_PROBE(EXIT_DATA_READY);
    
    // fire again in background after each notification
    [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
}

- (void) appendData:(NSData *)data {

    BM_PROBE(ENTER_APPEND_DATA);

    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string) {
        self.partialResult = [partialResult stringByAppendingString:string];
    } else {
        NSLog(@"*** Warning: -[appendData:] attempted but could not append to self.partialResult. Data maybe lost!");
    }
    
    [string release];
    
    BM_PROBE(EXIT_APPEND_DATA, 
             (char *) [[partialResult quote] UTF8String]);
}

- (void) taskTerminated:(NSNotification *)aNotification {
    
    BM_PROBE(ENTER_TASK_TERMINATED, 
             (char *) [[[[aNotification userInfo] descriptionInStringsFileFormat] quote] UTF8String]);

    // read out remaining data, as the pipes have a limited buffer size 
    // and may stall on subsequent calls if full
	NSData * dataInPipe = [[bgPipe fileHandleForReading] readDataToEndOfFile];
    if (dataInPipe) {
        [self appendData:dataInPipe];
    }
    
    BM_PROBE(END_BG_EXECUTE, 
             (char *) [[lastResult quote] UTF8String]);
    
    // task is finished, copy over the accumulated partialResults into lastResult
    if ([[self delegate] respondsToSelector:@selector(shouldSetLastResult:)]) {
        if ([[self delegate] shouldSetLastResult:partialResult ]) {
            self.lastResult = partialResult;
        }
    } else {
        self.lastResult = [lastResult stringByAppendingString:partialResult ];
    }
    
    
    BMSCRIPT_LOCK
    s_bgTaskStatus = [[aNotification object] terminationStatus];
    BMSCRIPT_UNLOCK
        
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:s_bgTaskStatus], BMScriptNotificationInfoTaskTerminationStatusKey, 
                           [self lastResult], BMScriptNotificationInfoTaskResultsKey, nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:BMScriptTaskDidEndNotification object:nil userInfo:info]];
    
    NSArray * historyItem = [NSArray arrayWithObjects:[self script], [self lastResult], nil];
    [[self history] addObject:historyItem];
    if (BMSCRIPT_DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
    
    if([bgTask isRunning]) {
        [bgTask terminate];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:nil];
    
    BM_PROBE(EXIT_TASK_TERMINATED, 
             (char *) [[lastResult quote] UTF8String], 
             (char *) [[partialResult quote] UTF8String]);
}

// MARK: Templates

// TODO: add probes for template system

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    if (isTemplate) {
        self.script = [NSString stringWithFormat:script, tArg];
        self.isTemplate = NO;
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {
    
    if (isTemplate) {
        // determine how many replacements we need to make
        NSInteger numTokens = [script countOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN];
        if (numTokens == NSNotFound) {
            return NO;
        }
        
        NSString * accumulator = [self script];
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
        
        self.script = [accumulator stringByReplacingOccurrencesOfString:@"%%" withString:@"%"];
        self.isTemplate = NO;
        
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary {
    if (isTemplate) {
        
        NSString * accumulator = [self script];
        
        NSArray * keys = [dictionary allKeys];
        NSArray * values = [dictionary allValues];
        
        NSInteger i = 0;
        for (NSString * key in keys) {
            accumulator = [accumulator stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%{"BMSCRIPT_INSERTION_TOKEN"}", key ] 
                                                                 withString:[values objectAtIndex:i]];
            i++;
        }
        
        self.script = [accumulator stringByReplacingOccurrencesOfString:@"%" withString:@""];
        self.isTemplate = NO;
        
        return YES;
    }
    return NO;
}



// MARK: Execution

- (BOOL) execute {
    
    BM_PROBE(ENTER_EXECUTE, 
             (char *) [[[self script] quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[[self options] objectForKey:BMScriptOptionsTaskLaunchPathKey] UTF8String]);
    
    BOOL success = NO;
    
    if (isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];

    } else {
        if ([self executeAndReturnResult:nil] == YES) {
            success = YES;
        }
    }
    
    BM_PROBE(EXIT_EXECUTE, (char *) [[lastResult quote] UTF8String]);
    return success;
}

- (BOOL) executeAndReturnResult:(NSString **)result {
    
    BM_PROBE(ENTER_EXECUTE_AND_RETURN_RESULT, 
             (char *) [[script quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[options objectForKey:BMScriptOptionsTaskLaunchPathKey] UTF8String]);
    
    BOOL success = NO;
    
    if (isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];
    } else {
        if ([self executeAndReturnResult:result error:nil] == YES) {
            success = YES;
        }
    }
    
    BM_PROBE(EXIT_EXECUTE_AND_RETURN_RESULT, 
             (char *) [[lastResult quote] UTF8String]);
    
    return success;
}

- (BOOL) executeAndReturnError:(NSError **)error {
    
    BM_PROBE(ENTER_EXECUTE_AND_RETURN_ERROR, 
             (char *) [[[self script] quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[task launchPath] UTF8String]);
    
    BOOL success = NO;
    
    if (isTemplate) {
        if (error) {
            NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"please define all replacement values for the current template "
                                                   @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                        forKey:NSLocalizedFailureReasonErrorKey];
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
        } else {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
        }
    } else {
        if ([self executeAndReturnResult:nil error:error] == YES) {
            success = YES;
        }
    }
    BM_PROBE(EXIT_EXECUTE_AND_RETURN_RESULT, 
             (char *) [[lastResult quote] UTF8String]);
    
    return success;
}

- (BOOL) executeAndReturnResult:(NSString **)result error:(NSError **)error {
    
    BM_PROBE(ENTER_EXECUTE_AND_RETURN_RESULT_ERROR,
             (char *) [[[self script] quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[bgTask launchPath] UTF8String]);
    
    BM_PROBE(START_NET_EXECUTE, 
             (char *) [[[self script] quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[bgTask launchPath] UTF8String]);
    
    BOOL success = NO;
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    BMSCRIPT_LOCK
    s_taskStatus = status;
    BMSCRIPT_UNLOCK
    
    if (isTemplate) {
        if (error) {
            NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"please define all replacement values for the current template "
                                                   @"by calling one of the -saturateTemplate... methods prior to execution" 
                                            forKey:NSLocalizedFailureReasonErrorKey];
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
        } else {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -saturateTemplate... methods prior to execution" 
                                         userInfo:nil];            
        }            
        return success;
    }
    if ([self setupTask] == YES) {
        status = [self launchTaskAndStoreLastResult];
        if (BMScriptFinishedSuccessfullyTerminationStatus == status) {
            if (result) {
                *result = [self lastResult];
            }
            NSArray * historyItem = [NSArray arrayWithObjects:script, lastResult, nil];
            if ([[self delegate] respondsToSelector:@selector(shouldAddItemToHistory:)]) {
                if ([[self delegate] shouldAddItemToHistory:historyItem]) {
                    [history addObject:historyItem];
                }
            } else {
                [history addObject:historyItem];
            }
            if (BMSCRIPT_DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
            success = YES;
        } else {
            if (error) {
                NSDictionary * errorDict = 
                    [NSDictionary dictionaryWithObject:@"script task returned non 0 exit status (indicating a possible error)" 
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
    
    BM_PROBE(END_NET_EXECUTE, 
             (char *) [[[self lastResult] quote] UTF8String]);

    BM_PROBE(EXIT_EXECUTE_AND_RETURN_RESULT_ERROR, 
             (char *) [[[self lastResult] quote] UTF8String]);

    return success;
}


- (void) executeInBackgroundAndNotify {
    
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    s_bgTaskStatus = status;
    
    if (isTemplate) {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
    }
    
    BM_PROBE(START_BG_EXECUTE, 
             (char *) [[[self script] quote] UTF8String], 
             (char *) [BMStringFromBOOL(isTemplate) UTF8String], 
             (char *) [[bgTask launchPath] UTF8String]);
    
    [self setupAndLaunchBackgroundTask];
    
}

// MARK: History

// TODO: add probes for history system

- (NSString *) scriptSourceFromHistoryAtIndex:(NSInteger)index {
    
    BM_PROBE(ENTER_SCRIPT_SOURCE_FROM_HISTORY_AT_INDEX, index, (int) [history count]);
    NSString * aScript = nil;
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:0];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                aScript = item;
            }
        } else {
            aScript = item;
        }
    }
    BM_PROBE(EXIT_SCRIPT_SOURCE_FROM_HISTORY_AT_INDEX, (char *) [[aScript quote] UTF8String], (int) [history count]);
    return [[aScript retain] autorelease];
}

- (NSString *) resultFromHistoryAtIndex:(NSInteger)index {
    
    BM_PROBE(ENTER_RESULT_FROM_HISTORY_AT_INDEX, index, (int) [history count]);
    NSString * aResult = nil;
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:1];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                aResult = item;
            }
        } else {
            aResult = item;
        }
    }
    BM_PROBE(EXIT_RESULT_FROM_HISTORY_AT_INDEX, (char *) [[aResult quote] UTF8String], (int) [history count]);
    return [[aResult retain] autorelease];
}

- (NSString *) lastScriptSourceFromHistory {
    
    BM_PROBE(ENTER_LAST_SCRIPT_SOURCE_FROM_HISTORY, (int) [history count]);
    NSString * aScript = nil;
    if ([history count] > 0) {
        NSString * item = [[[self history] lastObject] objectAtIndex:0];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                aScript = item;
            }
        } else {
            aScript = item;
        }
    }
    BM_PROBE(EXIT_LAST_SCRIPT_SOURCE_FROM_HISTORY, (char *) [[aScript quote] UTF8String], (int) [history count]);
    return [[aScript retain] autorelease];
}

- (NSString *) lastResultFromHistory {
    
    BM_PROBE(ENTER_LAST_RESULT_FROM_HISTORY, (int) [history count]);
    
    NSString * aResult = nil;
    if ([history count] > 0) {
        NSString * item = [[[self history] lastObject] objectAtIndex:1];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                aResult = item;
            }
        } else {
            aResult = item;
        }
    }
    
    BM_PROBE(EXIT_LAST_RESULT_FROM_HISTORY, (char *) [[aResult quote] UTF8String], (int) [history count]);
    
    return [[aResult retain] autorelease];
}

// MARK: Equality

- (BOOL) isEqualToScript:(BMScript *)other {
    BOOL sameScript = [[self script] isEqualToString:[other script]];
    BOOL sameLaunchPath = [[[self options] objectForKey:BMScriptOptionsTaskLaunchPathKey] 
                           isEqualToString:[[other options] objectForKey:BMScriptOptionsTaskLaunchPathKey]];
    return sameScript && sameLaunchPath;
}

- (BOOL) isEqual:(BMScript *)other {
    return [[self script] isEqualToString:[other script]];
}

// MARK: BMScriptDelegate

- (BOOL) shouldAddItemToHistory:(id)anItem { BMSCRIPT_DELEGATE_METHOD_TRACE return YES; }
- (BOOL) shouldReturnItemFromHistory:(id)anItem { BMSCRIPT_DELEGATE_METHOD_TRACE return YES; }
- (BOOL) shouldSetLastResult:(NSString *)aString { BMSCRIPT_DELEGATE_METHOD_TRACE return YES; }
- (BOOL) shouldAppendPartialResult:(NSString *)string { BMSCRIPT_DELEGATE_METHOD_TRACE return YES; }
- (BOOL) shouldSetScript:(NSString *)aScript { BMSCRIPT_DELEGATE_METHOD_TRACE return YES; }
- (BOOL) shouldSetOptions:(NSDictionary *)opts { BMSCRIPT_DELEGATE_METHOD_TRACE return YES; }


// MARK BMScriptLanguage

// Currently unused as BMScriptLanguageProtocol was initially intended for subclasses
// It might change again but that's the status at the time of writing

//- (NSDictionary *) defaultOptionsForLanguage {
//     NSDictionary * opts = BMSynthesizeOptions(@"/bin/echo", nil);
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
    return [self retain];
}

// MARK: NSMutableCopying

- (id) mutableCopyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithScriptSource:[self script] 
                                                              options:[self options]];
    return copy;
}

// MARK: NSCoding

- (void) encodeWithCoder:(NSCoder *)coder { 
    [coder encodeObject:script];
    [coder encodeObject:lastResult];
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
    if (self = [super init]) { 
        //int version = [coder versionForClassName:NSStringFromClass([self class])]; 
        //NSLog(@"class version = %i", version);
        script     = [[coder decodeObject] retain];
        lastResult = [[coder decodeObject] retain];
        options    = [[coder decodeObject] retain];
        history    = [[coder decodeObject] retain];
        task       = [[coder decodeObject] retain];
        pipe       = [[coder decodeObject] retain];
        bgTask     = [[coder decodeObject] retain];
        bgPipe     = [[coder decodeObject] retain];
        delegate   = [[coder decodeObject] retain];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
        
    }
    return self;
}

@end

@implementation BMScript (CommonScriptLanguagesFactories)

// Ruby

+ (id) rubyScriptWithSource:(NSString *)scriptSource {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e", nil);
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) rubyScriptWithContentsOfFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e", nil);
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e", nil);
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Python 

+ (id) pythonScriptWithSource:(NSString *)scriptSource {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c", nil);
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) pythonScriptWithContentsOfFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c", nil);
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/python", @"-c", nil);
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

// Perl

+ (id) perlScriptWithSource:(NSString *)scriptSource {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e", nil);
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) perlScriptWithContentsOfFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e", nil);
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e", nil);
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
    quotedResult = [quotedResult stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
    
    return quotedResult;
}

- (NSString *) truncate {
#ifdef NSSTRING_TRUNCATE_LENGTH
    NSUInteger len = NSSTRING_TRUNCATE_LENGTH;
#else
    NSInteger len = 20;
#endif
    if ([self length] < len) {
        return self;
    }
    return [self truncateToLength:len];
}

- (NSString *) truncateToLength:(NSInteger)len {
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

/*
 * Copyright (c) 2009 André Berg (Berg Media)
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
