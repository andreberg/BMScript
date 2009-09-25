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
#define BMSCRIPT_DEBUG_MEMORY 0
#endif
#ifndef BMSCRIPT_DEBUG_HISTORY
#define BMSCRIPT_DEBUG_HISTORY 0
#endif
#ifndef BMSCRIPT_DEBUG_OBJECTS
#define BMSCRIPT_DEBUG_OBJECTS 0
#endif
#ifndef BMSCRIPT_DEBUG_INIT
#define BMSCRIPT_DEBUG_INIT 0
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




NSString * const BMScriptTaskDidEndNotification                   = @"BMScriptTaskDidEndNotification";
NSString * const BMScriptNotificationInfoTaskResultsKey           = @"BMScriptNotificationInfoTaskResultsKey";
NSString * const BMScriptNotificationInfoTaskTerminationStatusKey = @"BMScriptNotificationInfoTaskTerminationStatusKey";

NSString * const BMScriptOptionsTaskLaunchPathKey = @"BMScriptOptionsTaskLaunchPathKey";
NSString * const BMScriptOptionsTaskArgumentsKey  = @"BMScriptOptionsTaskArgumentsKey";
NSString * const BMScriptOptionsRubyVersionKey    = @"BMScriptOptionsRubyVersionKey"; /* currently unused */

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
- (void) printRetainCounts;

// MARK: Private Accessors
- (NSTask *)task;
- (void)setTask:(NSTask *)newTask;
- (NSPipe *)pipe;
- (void)setOutPipe:(NSPipe *)newOutPipe;
// - (NSString *) defaultScript;
// - (void) setDefaultScript: (NSString *) newDefaultScript;
// - (NSDictionary *) defaultOptions;
// - (void) setDefaultOptions: (NSDictionary *) newDefaultOptions;
- (NSThread *) bgThread;
- (void) setBgThread: (NSThread *) newBgThread;
- (NSPipe *) bgPipe;
- (void) setBgPipe:(NSPipe *)newBgPipe;
// - (NSString *)partialResult;
// - (void)setPartialResult:(NSString *)newPartialResult;
- (BOOL)isTemplate;
- (void)setIsTemplate:(BOOL)flag;
/**
 * Sets the lastResult instance variable. Uses release/copy.
 * @param newLastResult new value for lastResult.
 */
- (void)setLastResult:(NSString *)newLastResult;

/**
 * Sets the history instance variable. Uses release/retain.
 * Wraps access with a pthread_mutex_lock if BMSCRIPT_THREAD_SAFE is 1.
 * @param newHistory new value for history.
 */
- (void)setHistory:(NSMutableArray *)newHistory;

@end


@implementation BMScript

// MARK: Accessors

//=========================================================== 
//  script 
//=========================================================== 
- (NSString *)script {
    return [[script copy] autorelease]; 
}

- (void)setScript:(NSString *)newScript {
    if (script != newScript) {
        if ([[self delegate] respondsToSelector:@selector(shouldSetScript:)]) {
            if ([[self delegate] shouldSetScript:newScript]) {
                [script release];
                script = [newScript copy];
            }
        } else {
            [script release];
            script = [newScript copy];
        }
    }
    
}

//=========================================================== 
//  lastResult 
//=========================================================== 
- (NSString *)lastResult {
    return [[lastResult copy] autorelease]; 
}

- (void)setLastResult:(NSString *)newLastResult {
    BMSCRIPT_LOCK
    if (lastResult != newLastResult) {
        [lastResult release];
        lastResult = [newLastResult copy];
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
// - (NSString *)partialResult {
//     return [[partialResult copy] autorelease];
// }
// - (void)setPartialResult:(NSString *)newPartialResult {
//     BMSCRIPT_LOCK
//     if (partialResult != newPartialResult) {
//         [partialResult release];
//         partialResult = [newPartialResult copy];
//     }
//     BMSCRIPT_UNLOCK
// }

//=========================================================== 
//  delegate 
//=========================================================== 
- (id)delegate {
    return delegate; 
}

- (void)setDelegate:(id)newDelegate {
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
    
    [script release], script = nil;
    [history release], history = nil;
    [options release], options = nil;
    [lastResult release], lastResult = nil;
    [task release], task = nil;
    [pipe release], pipe = nil;
    [bgTask release], bgTask = nil;
    [bgPipe release], bgPipe = nil;
    [super dealloc];
}

- (void) finalize {    
    [super finalize];
}

// MARK: Description

- (NSString *) description {
    return [NSString stringWithFormat:@"%@,\n script: '%@',\n lastResult: '%@',\n delegate: %@,\n options: %@", 
            [super description], [script quote], [lastResult quote], (delegate == self? @"self" : delegate), [options descriptionInStringsFileFormat]];
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
                script = @"no script source set";
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
        
        // tasks/pipes will be allocated & initialized as needed
        task = nil;
        pipe = nil;
        bgTask = nil;
        bgPipe = nil;
        
        delegate = self;
        
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

+ (id) scriptWithSource:(NSString *)scriptSource { 
    return [[[self alloc] initWithScriptSource:scriptSource options:nil] autorelease]; 
}

+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions { 
    return [[[self alloc] initWithScriptSource:scriptSource options:scriptOptions] autorelease]; 
}

+ (id) scriptWithContentsOfFile:(NSString *)path {
    return [[[self alloc] initWithContentsOfFile:path options:nil] autorelease];
}

+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfFile:path options:scriptOptions] autorelease];
}

+ (id) scriptWithContentsOfTemplateFile:(NSString *)path {
    return [[[self alloc] initWithContentsOfTemplateFile:path options:nil] autorelease];
}

+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    return [[[self alloc] initWithContentsOfTemplateFile:path options:scriptOptions] autorelease];
}

// MARK: Private Methods

- (void) printRetainCounts {
    //
    // Yes, I know retainCount is bad, yes I have read the longer mailinglist thread 
    // where bbum and everyone else basically says "never ever rely on retainCount!"
    // ...
    // ...
    // and I am still abusing it. Spank me! :p
    //
    // PS: Don't get all wet on this... it was just used for general observations that 
    // have lead to absolutely no decisions about internal object state or design.
    // This abonimation will be deleted in the near future.
    // PPS: http://lists.apple.com/archives/xcode-users/2009/Jun/msg00242.html
    //
    NSInteger selfRetainCount = 0, scriptRetainCount = 0, lastResultRetainCount = 0,
              delegateRetainCount = 0, optionsRetainCount = 0, historyRetainCount = 0,
              taskRetainCount = 0, pipeRetainCount = 0, defaultScriptRetainCount = 0,
              defaultOptionsRetainCount = 0, bgTaskRetainCount = 0, bgPipeRetainCount = 0,
              partialResultRetainCount = 0;

    if (self) {
        selfRetainCount = [self retainCount];
    }
    if (script) {
        scriptRetainCount = [script retainCount];
    }
    if (lastResult) {
        lastResultRetainCount = [lastResult retainCount];
    }
    if (delegate) {
        delegateRetainCount = [delegate retainCount];
    }
    if (options) {
        optionsRetainCount = [options retainCount];
    }
    if (history) {
        historyRetainCount = [history retainCount];
    }
    if (task) {
        taskRetainCount = [task retainCount];
    }
    if (pipe) {
        pipeRetainCount = [pipe retainCount];
    }
//     if (defaultScript) {
//         defaultScriptRetainCount = [defaultScript retainCount];
//     }
//     if (defaultOptions) {
//         defaultOptionsRetainCount = [defaultOptions retainCount];
//     }
    if (bgTask) {
        bgTaskRetainCount = [bgTask retainCount];
    }
    if (bgPipe) {
        bgPipeRetainCount = [bgPipe retainCount];
    }
//     if (partialResult) {
//         partialResultRetainCount = [partialResult retainCount];
//     }

    NSLog(@"\nRetain Counts\n"
          @" self = %ld\n"
          @" script = %ld\n"
          @" lastResult = %ld\n"
          @" delegate = %ld\n"
          @" options = %ld\n"
          @" history = %ld\n"
          @" task = %ld\n"
          @" pipe = %ld\n"
          @" defaultScript = %ld\n"
          @" defaultOptions = %ld\n"
          @" bgTask = %ld\n"
          @" bgPipe = %ld\n"
          @" partialResult = %ld", 
          selfRetainCount, 
          scriptRetainCount,
          lastResultRetainCount, 
          delegateRetainCount,
          optionsRetainCount,
          historyRetainCount,
          taskRetainCount,
          pipeRetainCount,
          defaultScriptRetainCount,
          defaultOptionsRetainCount,
          bgTaskRetainCount,
          bgPipeRetainCount,
          partialResultRetainCount);
}

- (BOOL) setupTask {
    
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
            
            return YES;
        }
    }
    return NO; 
}

/* fires a one-off (blocking or synchroneous) task and stores the result */
- (TerminationStatus) launchTaskAndStoreLastResult {
    
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
    [string release];
    return status;
}

/* fires a one-off (non-blocking or asynchroneous) task and reels in the results 
   one after another thru notifications */
- (void) setupAndLaunchBackgroundTask {
    
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
            // [NSArray arrayWithObjects:nil] which in turn becomes a "__NSArray0"
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
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(dataReady:) 
                                                         name:NSFileHandleReadCompletionNotification 
                                                       object:[bgPipe fileHandleForReading]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(taskTerminated:) 
                                                         name:NSTaskDidTerminateNotification 
                                                       object:bgTask];
            
            [bgTask launch];
            
            // kick off pipe reading in background
            [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
        }
    }
}

- (void) dataReady:(NSNotification *)aNotification {
    
	NSData * data = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if (data) {
        [self appendData:data];
    }
    // fire again in background after each notification
    [[bgPipe fileHandleForReading] readInBackgroundAndNotify];
}

- (void) appendData:(NSData *)data {
    
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string) {
        if ([[self delegate] respondsToSelector:@selector(shouldSetLastResult:)]) {
            if ([[self delegate] shouldSetLastResult:string]) {
                self.lastResult = [self.lastResult stringByAppendingString:string];
            }
        }
    } else {
        NSLog(@"*** Warning: -[appendData:] attempted but could not append to self.partialResult. Data maybe lost!");
    }
    [string release];
}

- (void) taskTerminated:(NSNotification *)aNotification {
    
	NSData * dataInPipe = [[bgPipe fileHandleForReading] readDataToEndOfFile];
    if (dataInPipe) {
        [self appendData:dataInPipe];
    }
    
    BMSCRIPT_LOCK
    s_bgTaskStatus = [[aNotification object] terminationStatus];
    BMSCRIPT_UNLOCK
        
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:s_bgTaskStatus], BMScriptNotificationInfoTaskTerminationStatusKey, 
                           [self lastResult], BMScriptNotificationInfoTaskResultsKey, nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:BMScriptTaskDidEndNotification object:[self bgTask] userInfo:info]];
    
    NSArray * historyItem = [NSArray arrayWithObjects:[self script], [self lastResult], nil];
    [[self history] addObject:historyItem];
    if (BMSCRIPT_DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
}

// MARK: Templates

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    if (self.isTemplate) {
        self.script = [NSString stringWithFormat:[self script], tArg];
        self.isTemplate = NO;
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {
    
    if (self.isTemplate) {
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
    if (self.isTemplate) {
        
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
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];

    } else {
        if ([self executeAndReturnResult:nil] == YES) {
            return YES;
        }
    }
    return NO;
}

- (BOOL) executeAndReturnResult:(NSString **)result {
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:@"please define all replacement values for the current template "
                                              @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                     userInfo:nil];
    } else {
        if ([self executeAndReturnResult:result error:nil] == YES) {
            return YES;
        }
    }
    return NO;
}

- (BOOL) executeAndReturnError:(NSError **)error {
    if (self.isTemplate) {
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
            return YES;
        }
    }
    return NO;
}

- (BOOL) executeAndReturnResult:(NSString **)result error:(NSError **)error {
    

    BM_PROBE(START_NET_EXECUTE, (char *) [[[self script] quote] UTF8String], (char *) [BMStringFromBOOL(self.isTemplate) UTF8String], (char *) [[[self options] objectForKey:BMScriptOptionsTaskLaunchPathKey] UTF8String]);
    
    BOOL success = NO;
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    BMSCRIPT_LOCK
    s_taskStatus = status;
    BMSCRIPT_UNLOCK
    
    if (self.isTemplate) {
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
    
    BM_PROBE(END_NET_EXECUTE, (char *)[[[self lastResult] quote] UTF8String]);
    return success;
}


- (void) executeInBackgroundAndNotify {
    
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    s_bgTaskStatus = status;
    
    if (self.isTemplate) {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
    }
    
    [self setupAndLaunchBackgroundTask];
    
}

// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(NSInteger)index {
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:0];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                return item;
            }
        } else {
            return item;
        }
    }
    return nil;
}

- (NSString *) resultFromHistoryAtIndex:(NSInteger)index {
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:1];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                return item;
            }
        } else {
            return item;
        }
    }
    return nil;
}

- (NSString *) lastScriptSourceFromHistory {
    if ([history count] > 0) {
        NSString * item = [[[self history] lastObject] objectAtIndex:0];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                return item;
            }
        } else {
            return item;
        }
    }
    return nil;
}

- (NSString *) lastResultFromHistory {
    if ([history count] > 0) {
        NSString * item = [[[self history] lastObject] objectAtIndex:1];
        if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([[self delegate] shouldReturnItemFromHistory:item]) {
                return item;
            }
        } else {
            return item;
        }
    }
    return nil;
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

// MARK: Delegate Methods

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
