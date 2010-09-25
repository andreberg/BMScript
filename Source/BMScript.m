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

#if BMSCRIPT_ENABLE_DTRACE
#import "BMScriptProbes.h"      /* dtrace probes auto-generated from .d file(s) */
#endif

#include <unistd.h>             /* for usleep       */
#include <pthread.h>            /* for pthread_*    */

#define BMNSSTRING_TRUNCATE_LENGTH      20              /* used by -truncatedString, defined in NSString (BMScriptUtilities) */
#define BMNSSTRING_TRUNCATE_TOKEN       @"\u2026"       /* Unicode: Horizontal Ellipsis (…). Also used by -truncatedString   */

#define BMSCRIPT_TEMPLATE_TOKEN_EMPTY   @""BMSCRIPT_TEMPLATE_TOKEN_START""BMSCRIPT_TEMPLATE_TOKEN_END""                                 /* complete (but empty) magic token used in templates */
#define BMSCRIPT_TEMPLATE_TOKEN_INSERT  @""BMSCRIPT_TEMPLATE_TOKEN_START""BMSCRIPT_INSERTION_TOKEN""BMSCRIPT_TEMPLATE_TOKEN_END""       /* complete magic token incl. insertion token used in templates */
#define BMSCRIPT_DEFAULT_OPTIONS        @"BMSynthesizeOptions(@\"/bin/echo\", @\"\")"   /* default script option for display in warnings etc. */
#define BMSCRIPT_DEFAULT_SCRIPT_SOURCE  @"'<script source placeholder>'"                /* default script source for display in warnings etc. */

#define BMSCRIPT_TASK_TIME_LIMIT        10  /* time limit in seconds for how long the blocking task is allowed to execute before being interrupted */

#ifndef BMSCRIPT_DEBUG_HISTORY
    #define BMSCRIPT_DEBUG_HISTORY  0
#endif

#if (BMSCRIPT_THREAD_AWARE && BMSCRIPT_ENABLE_DTRACE)
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
#elif (BMSCRIPT_THREAD_AWARE && !BMSCRIPT_ENABLE_DTRACE)
    #if BMSCRIPT_FAST_LOCK
        #define BM_LOCK(name) \
        static pthread_mutex_t mtx_##name = PTHREAD_MUTEX_INITIALIZER; \
        if (pthread_mutex_lock(&mtx_##name)) {\
            printf("*** Warning: Lock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        }
        #define BM_UNLOCK(name) \
        if ((pthread_mutex_unlock(&mtx_##name) != 0)) {\
            printf("*** Warning: Unlock failed! Application behaviour may be undefined. Exiting...");\
            exit(EXIT_FAILURE);\
        };
    #else
        #define BM_LOCK(name) \
        static id const sync_##name##_ref = @""#name;\
        @synchronized(sync_##name##_ref) {
        #define BM_UNLOCK(name) };
    #endif
#else 
    #define BM_LOCK(name)
    #define BM_UNLOCK(name)
#endif


NSString * const BMScriptTaskDidEndNotification                  = @"BMScriptTaskDidEndNotification";
NSString * const BMScriptNotificationTaskResults                 = @"BMScriptNotificationTaskResults";
NSString * const BMScriptNotificationTaskReturnValue             = @"BMScriptNotificationTaskReturnValue";
NSString * const BMScriptNotificationExecutionStatus             = @"BMScriptNotificationExecutionStatus";

NSString * const BMScriptOptionsTaskLaunchPathKey                = @"BMScriptOptionsTaskLaunchPathKey";
NSString * const BMScriptOptionsTaskArgumentsKey                 = @"BMScriptOptionsTaskArgumentsKey";

NSString * const BMScriptTemplateTokenStartKey                   = @"BMScriptTemplateTokenStartKey";
NSString * const BMScriptTemplateTokenEndKey                     = @"BMScriptTemplateTokenEndKey";

NSString * const BMScriptTemplateArgumentMissingException        = @"BMScriptTemplateArgumentMissingException";

NSString * const BMScriptLanguageProtocolDoesNotConformException = @"BMScriptLanguageProtocolDoesNotConformException";
NSString * const BMScriptLanguageProtocolMethodMissingException  = @"BMScriptLanguageProtocolMethodMissingException";


/* Empty braces means this is an "Extension" as opposed to a Category */
@interface BMScript (/* Private */)

@property (BM_ATOMIC copy, readwrite) NSData * result;
@property (BM_ATOMIC assign) NSInteger returnValue;
@property (BM_ATOMIC copy) NSMutableData * partialResult;
@property (BM_ATOMIC assign) BOOL isTemplate;
@property (BM_ATOMIC retain) NSTask * task;
@property (BM_ATOMIC retain) NSPipe * pipe;
@property (BM_ATOMIC retain) NSTask * bgTask;
@property (BM_ATOMIC retain) NSPipe * bgPipe;
@property (BM_ATOMIC copy, readwrite) NSMutableArray * _history;

- (void) stopTask;
- (BOOL) setupTask;
- (void) cleanupTask:(NSTask *)whichTask;
- (ExecutionStatus) launchTask;
- (void) setupAndLaunchBackgroundTask;
- (void) taskTerminated:(NSNotification *)aNotification;
- (void) appendPartialData:(NSData *)d;
- (void) dataReceived:(NSNotification *)aNotification;
- (const char *) gdbDataFormatter;

@end

@implementation BMScript

@synthesize delegate;
@synthesize source;
@synthesize options;
@synthesize partialResult;
@synthesize result;
@synthesize isTemplate;
@synthesize task;
@synthesize pipe;
@synthesize bgTask;
@synthesize bgPipe;
@synthesize returnValue;
@synthesize _history;


// MARK: Description

- (NSString *) description {
    return [NSString stringWithFormat:@"%@\n"
                                      @"  script: '%@'\n"
                                      @"  result: '%@'\n"
                                      @"  retval: '%d'\n"
                                      @"delegate: '%@'\n"
                                      @" options: '%@'", 
                                      [super description], 
                                      [self.source quotedString], 
                                      [[self.result contentsAsString] quotedString], 
                                       self.returnValue,
                                      (self.delegate == self? (id)@"self" : self.delegate), 
                                      [self.options descriptionInStringsFileFormat]];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@\n"
                                      @" history (%d item%@): '%@'\n"
                                      @"    task: '%@'\n"
                                      @"    pipe: '%@'\n"
                                      @"  bgTask: '%@'\n"
                                      @"  bgPipe: '%@'\n", 
                                      [self description], 
                                      [self._history count], ([self._history count] == 1 ? @"" : @"s"), self._history, 
                                       self.task, 
                                       self.pipe, 
                                       self.bgTask, 
                                       self.bgPipe];
}

- (const char *) gdbDataFormatter {
    
    NSString * launchPath = [self.options objectForKey:BMScriptOptionsTaskLaunchPathKey];
    NSArray * args = [self.options objectForKey:BMScriptOptionsTaskArgumentsKey];
    NSMutableString * accString = [NSMutableString string];
    if (args) {
        for (NSString * arg in args) {
            [accString appendFormat:@" %@%@", arg, ([arg isEqualToString:@""] ? @"" : @", ")];
        }
    }
    NSString * desc = [NSString stringWithFormat:@"options = %@%@script = %@, result = %@, isTemplate = %@", 
                       (launchPath ? launchPath : @"nil, "),
                       (accString ? accString : @"nil, "),
                       (self.source ? [[self.source quotedString] truncatedString] : @"nil"), 
                       (self.result ? [[[self.result contentsAsString] quotedString] truncatedString] : @"nil"),
                       BMNSStringFromBOOL(self.isTemplate)];
    
    return [desc UTF8String];
}

// MARK: Deallocation

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    if (BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    
    [source release], source = nil;
    [_history release], _history = nil;
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
    if (BM_EXPECTED([task isRunning], 0)) [task terminate];
    if (BM_EXPECTED([bgTask isRunning], 0)) [bgTask terminate];
    [super finalize];
}

// MARK: Object Creation

- (id)init {
    NSLog(@"%@ Warning: Initializing instance %@ with default values! "
          @"(options = \"/bin/echo\", \"\", script source = '<script source placeholder>')", NSStringFromClass([self class]), [super description]);
    return [self initWithScriptSource:nil options:nil]; 
}

/* designated initializer */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions {

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(INIT_BEGIN, 
                 (char *) (scriptSource ? [[scriptSource quotedString] UTF8String] : "(null)"), 
                 (char *) (scriptOptions ? [[[scriptOptions descriptionInStringsFileFormat] quotedString] UTF8String] : "(null)"));
    #endif
        
    source = nil;
    options = nil;
    
    NSString * classname = [self className];

    if (([self class] != [BMScript class]) && 
        ([self isKindOfClass:[BMScript class]]) && 
        !([self conformsToProtocol:@protocol(BMScriptLanguageProtocol)])) {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolDoesNotConformException 
                                       reason:[NSString stringWithFormat:@"%@ Error: Descendants of BMScript must conform to the BMScriptLanguageProtocol!", classname]
                                     userInfo:nil];
    }
    
    if (BM_EXPECTED((self = [super init]) != nil, 1)) {
        
        if (scriptOptions) {
            options = [scriptOptions retain];
        } else {
            if (([self class] != [BMScript class]) && 
                ([self isKindOfClass:[BMScript class]]) && 
                !([self respondsToSelector:@selector(defaultOptionsForLanguage)])) {
                @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                               reason:[NSString stringWithFormat:@"%@ Error: Descendants of %@ must implement "
                                                                                 @"-[<BMScriptLanguageProtocol> defaultOptionsForLanguage].", classname, classname]
                                             userInfo:nil];
            } else if ([self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
                options = [[self performSelector:@selector(defaultOptionsForLanguage)] retain];
            } else {
                options = [BMSynthesizeOptions(@"/bin/echo", @"") retain];
            }
            
        }
        
        if (scriptSource) {
            if (scriptOptions || options) {
                source = [scriptSource retain];
            } else {
                // if scriptOptions == nil, we run with default options, namely /bin/echo so it might be better 
                // to put quotes around the scriptSource
                NSLog(@"%@ Info: Wrapping script source with single quotes. This is a precautionary measure "
                      @"because we are using default script options (instance initialized with options:nil).", classname);
                source = [[scriptSource stringByWrappingSingleQuotes] retain];
            }
        } else {
            if ([self respondsToSelector:@selector(defaultScriptSourceForLanguage)]) {
                source = [[self performSelector:@selector(defaultScriptSourceForLanguage)] retain];
            } else {
                source = @"'<script source placeholder>'";
            }
        }
        
        _history = [[NSMutableArray alloc] init];
        partialResult = [[NSString alloc] init];
        
        returnValue = BMScriptNotExecuted;
        
        // tasks/pipes will be allocated, initialized (and destroyed) lazily
        // on an as-needed basis because NSTasks are one-shot (not for re-use)
    }
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(INIT_END, (char *) [[[self debugDescription] quotedString] UTF8String]);
    #endif    
    return self;
}

- (id) initWithTemplateSource:(NSString *)templateSource options:(NSDictionary *)scriptOptions {
    
    if (templateSource) {
        self.isTemplate = YES;
        return [self initWithScriptSource:templateSource options:scriptOptions];
    }
    return nil;
}

- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    
    NSError * err = nil;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (BM_EXPECTED(scriptSource && !err, 1)) {
        self.isTemplate = NO;
        return [self initWithScriptSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"%@ Error: Reading script source from file at '%@' failed: %@", [self className], path, [err localizedFailureReason]);
    }
    return nil;
}

- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    
    NSError * err = nil;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (BM_EXPECTED(scriptSource && !err, 1)) {
        return [self initWithTemplateSource:scriptSource options:scriptOptions];
    } else {
        NSLog(@"%@ Error: Reading script source from file at '%@' failed: %@", [self className], path, [err localizedFailureReason]);
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
    
    BOOL success = NO;
    
    if (BM_EXPECTED([self.task isRunning], 0)) {
        [self.task terminate];
        [self cleanupTask:(self.task)];
    } else {

        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(SETUP_TASK_BEGIN);
        #endif

        self.task = [[NSTask alloc] init];
        self.pipe = [[NSPipe alloc] init];
        
        if (self.task && self.pipe) {
            
            NSString * path = [self.options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            NSArray * args = [self.options objectForKey:BMScriptOptionsTaskArgumentsKey];
            
            // If BMSynthesizeOptions is called with "nil" as second argument 
            // that effectively sets up BMScriptOptionsTaskArgumentsKey as 
            // [NSArray arrayWithObjects:nil] which in turn becomes a "__NSArray0"
            if (!args || [args isEmptyStringArray] || [args isZeroArray]) {
                args = [NSArray arrayWithObject:(self.source)];
            } else {
                args = [args arrayByAddingObject:(self.source)];
            }  
            
            [self.task setLaunchPath:path];
            [self.task setArguments:args];
            [self.task setStandardOutput:(self.pipe)];
            
            // Unfortunately we need the following define if we want to use SenTestingKit for unit testing. Since we are telling 
            // BMScript here to write to stdout and stderr SenTestingKit will actually output certain messages to stderr, messages
            // which can include the PID of the current task used for the testing. This invalidates testing task ouput from
            // two tasks even if their output is identical because their PID is not. To work around this, we can use a define which
            // will be set to 1 in the build settings for our unit tests via OTHER_CFLAGS and -DBMSCRIPT_UNIT_TESTS=1.
            if (!BMSCRIPT_UNIT_TEST) {
                //NSLog(@"BMScript: Info: setting [task standardError:pipe]");
                [self.task setStandardError:[self.task standardOutput]];
            }
            #if (BMSCRIPT_ENABLE_DTRACE)            
                BM_PROBE(SETUP_TASK_END);
            #endif
            success = YES;
        }
    }
    return success; 
}

/* fires a one-off (blocking or synchroneous) task and stores the result */
- (ExecutionStatus) launchTask {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    ExecutionStatus status = BMScriptNotExecuted;
    NSData * data = nil;
    
    @try {
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(NET_EXECUTION_BEGIN, (char *) [[BMNSStringFromExecutionStatus(status) stringByWrappingSingleQuotes] UTF8String]);
        #endif
        [self.task launch];
        //[self.task waitUntilExit]; // see explanation below
    }
    @catch (NSException * e) {
        self.returnValue = status = BMScriptFailedWithException;
        #if (BMSCRIPT_ENABLE_DTRACE)
                BM_PROBE(NET_EXECUTION_END, (char *) [[BMNSStringFromExecutionStatus(status) stringByWrappingSingleQuotes] UTF8String]);
        #endif
        goto endnow1;
    }
    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(NET_EXECUTION_END, (char *) [[BMNSStringFromExecutionStatus(status) stringByWrappingSingleQuotes] UTF8String]);
    #endif
    
    NSMutableData * someData = [NSMutableData data];
    NSDate * limitDate = [NSDate dateWithTimeIntervalSinceNow:BMSCRIPT_TASK_TIME_LIMIT];
    
    // It appears that very large output data from the underlying task 
    // fills up the pipe instance used by the reading filehandle and then
    // the task will block forever because it wants to deliver new data
    // but has to wait until the pipe is approachable again.
    // There's two ways around this: fire off the task in a thread. Not really
    // sure why this works. Maybe because the thread comes with another runloop
    // and the task can check if it needs to interrupt the process. 
    // Alternatively, do not call waitUntilExit and empty the filehandle data 
    // yourself by reading to the end. I could do this asynchroneously but since 
    // what I offer with the blocking execution model, the caller may depend on it
    // blocking. So I do what normally is considered bad practice: I poll for
    // the end of the task while emptying the filehandle each 0.1 seconds.
    // To be safer I say it has to end after BMSCRIPT_TASK_TIME_LIMIT seconds.
    // Of course I may need to expose the time limit to the caller since (s)he 
    // may be setting up for a somewhat lenghty execution. (hint: for this really, 
    // the non-blocking model is much better). 
    // I think it is somewhat reasonable to assume that a considerate programmer 
    // would use the non-blocking execution model if the script could potentially
    // take forever, so for the moment I am settings this to 10s. My own tests
    // have shown that for that even for input data up to 1 MiB using this "hack"
    // below the task will complete as fast as if it would have never blocked due
    // to the pipe being full. However further tests are still in order if this
    // approach is practical. For example instead of using usleep I could use sth
    // like [NSThread sleepForTimeInterval:...], etc. 
    // 
    while ([self.task isRunning]) {
        [someData appendData:[[self.pipe fileHandleForReading] readDataToEndOfFile]];
        usleep(10000);
        if ([limitDate compare:[NSDate date]] < 0) {
            [self.task interrupt];
        }
    }
    
    data = [[someData copy] autorelease];
    
    [self.task terminate];
    
    self.returnValue = status = [self.task terminationStatus];
    
    [self.task release], self.task = nil;
    
    NSData * aResult = data;
    
    BOOL shouldSetResult = YES;
    if ([self.delegate respondsToSelector:@selector(shouldSetResult:)]) {
        shouldSetResult = [self.delegate shouldSetResult:data];
    }
    if (shouldSetResult) {
        if ([self.delegate respondsToSelector:@selector(willSetResult:)]) {
            aResult = [self.delegate willSetResult:data];
        }
        self.result = aResult;
    }
    
endnow1:
    [pool drain], pool = nil;
    [self cleanupTask:(self.task)];
    return status;
}

/* fires a one-off (non-blocking or asynchroneous) task and reels in the results 
   one after another through notifications */
- (void) setupAndLaunchBackgroundTask {
    
    if (BM_EXPECTED([self.bgTask isRunning], 0)) {
        [self.bgTask terminate];
        [self cleanupTask:(self.bgTask)];
    } else {
        if (!self.bgTask) {
            #if (BMSCRIPT_ENABLE_DTRACE)            
                BM_PROBE(SETUP_BG_TASK_BEGIN);
            #endif

            // Create a task and pipe
            self.bgTask = [[[NSTask alloc] init] autorelease];
            self.bgPipe = [[[NSPipe alloc] init] autorelease];    
            
            NSString * path = [self.options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            NSArray * args = [self.options objectForKey:BMScriptOptionsTaskArgumentsKey];
            
            // If BMSynthesizeOptions is called with "nil" as second argument 
            // that effectively sets up BMScriptOptionsTaskArgumentsKey as 
            // [NSArray arrayWithObjects:nil] which in turn becomes an opaque 
            // object named "__NSArray0"
            if (!args || [args isEmptyStringArray] || [args isZeroArray]) {
                //NSLog(@"args = %@, args class = %@", args, NSStringFromClass([args class]));
                args = [NSArray arrayWithObject:(self.source)];
            } else {
                args = [args arrayByAddingObject:(self.source)];
            }  
            
            // set options for background task
            [self.bgTask setLaunchPath:path];
            [self.bgTask setArguments:args];
            [self.bgTask setStandardOutput:(self.bgPipe)];
            [self.bgTask setStandardError:(self.bgPipe)];
            
            // register for notifications
            
            // currently the execution model for background tasks is an incremental one:
            // self.partialResult is accumulated over the time the task is running and
            // posting NSFileHandleReadCompletionNotification notifications. This happens
            // through #dataReceived: which calls #appendData: until the NSTaskDidTerminateNotification 
            // is posted. Then, the partialResult is simply mirrored over to lastResult.
            // This gives the user the advantage for long running scripts to check partialResult
            // periodically and see if the task needs to be aborted.
                        
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(dataReceived:) 
                                                         name:NSFileHandleReadCompletionNotification 
                                                       object:[self.bgPipe fileHandleForReading]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(taskTerminated:) 
                                                         name:NSTaskDidTerminateNotification 
                                                       object:self.bgTask];
            #if (BMSCRIPT_ENABLE_DTRACE)            
                BM_PROBE(SETUP_BG_TASK_END);
            #endif

            @try {
                [self.bgTask launch];
            }
            @catch (NSException * e) {
                self.returnValue = BMScriptFailedWithException;
                [self cleanupTask:(self.bgTask)];
            }

            // kick off pipe reading in background
            [[self.bgPipe fileHandleForReading] readInBackgroundAndNotify];
        }
    }
}

- (void) dataReceived:(NSNotification *)aNotification {
    
	NSData * data = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if ([data length] > 0) {
        [self appendPartialData:data];
    } else {
        [self stopTask];
    }
    // fire again in background after each notification
    [[self.bgPipe fileHandleForReading] readInBackgroundAndNotify];
}


- (void) appendPartialData:(NSData *)data {
    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(APPEND_DATA_BEGIN, (char *) [[data contentsAsString] UTF8String]);
    #endif
    
    NSData * aPartial = [[data copy] autorelease];
    
    if (BM_EXPECTED(data != nil, 1)) {
        
        BOOL shouldAppendPartial = YES;
        if ([self.delegate respondsToSelector:@selector(shouldAppendPartialResult:)]) {
            shouldAppendPartial = [self.delegate shouldAppendPartialResult:data];
        }
        if (shouldAppendPartial) {
            if ([self.delegate respondsToSelector:@selector(willAppendPartialResult:)]) {
                aPartial = [self.delegate willAppendPartialResult:aPartial];
            }
            [self.partialResult appendData:aPartial];
        }
    } else {
        NSLog(@"BMScript: Warning: Attempted %s but could not append to self.partialResult. Data maybe lost!", __PRETTY_FUNCTION__);
    }
    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(APPEND_DATA_END, (char *) [[self.partialResult contentsAsString] UTF8String]);
    #endif
    
    aPartial = nil;
}

- (void) cleanupTask:(NSTask *)whichTask {
    
    if (self.task && self.task == whichTask) {
                
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_TASK_BEGIN);
        #endif
        
        [self.task release], self.task = nil;
        
        if (self.pipe) {
            [[self.pipe fileHandleForReading] closeFile];
            [self.pipe release], self.pipe = nil;
        }
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_TASK_END);
        #endif
        
    } else if (self.bgTask && self.bgTask == whichTask) {
        
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_BG_TASK_BEGIN);
        #endif
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSFileHandleReadCompletionNotification 
                                                      object:[self.bgPipe fileHandleForReading]];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSTaskDidTerminateNotification 
                                                      object:(self.bgTask)];
        [self.bgTask release], self.bgTask = nil;
        
        if (self.bgPipe) {
            [[self.bgPipe fileHandleForReading] closeFile];
            [self.bgPipe release], self.bgPipe = nil;
        }
        
        #if (BMSCRIPT_ENABLE_DTRACE)
            BM_PROBE(CLEANUP_BG_TASK_END);
        #endif
    }
}


- (void) stopTask {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(STOP_BG_TASK_BEGIN);
    #endif
    
    // read out remaining data, as the pipes have a limited buffer size 
    // and may stall on subsequent calls if full
    NSData * dataInPipe = [[(self.bgPipe) fileHandleForReading] readDataToEndOfFile];
    if (dataInPipe && [dataInPipe length]) {
        [self appendPartialData:dataInPipe];
    }

    if (BM_EXPECTED([self.bgTask isRunning], 0)) [self.bgTask terminate];
    
    ExecutionStatus status = self.returnValue;
    if (status == 0) {
        status = BMScriptFinishedSuccessfully;
    }

    self.returnValue = [self.bgTask terminationStatus];
    
    // task is finished, copy over the accumulated partialResults into lastResult
    NSData * data = self.partialResult;
    NSData * aResult = data;
    
    BOOL shouldSetResult = YES;
    if ([self.delegate respondsToSelector:@selector(shouldSetResult:)]) {
        shouldSetResult = [self.delegate shouldSetResult:aResult];
    }
    if (shouldSetResult) {
        if ([self.delegate respondsToSelector:@selector(willSetResult:)]) {
            aResult = [self.delegate willSetResult:data];
        }
        self.result = aResult;
    }
    
    [self cleanupTask:(self.bgTask)];

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(BG_EXECUTE_END, (char *) [[[self.result contentsAsString] quotedString] UTF8String]);
    #endif
    
    NSArray * historyItem = [NSArray arrayWithObjects:self.source, self.result, nil];
    
    BOOL shouldAddItemToHistory = YES;
    if ([self.delegate respondsToSelector:@selector(shouldAddItemToHistory:)]) {
        shouldAddItemToHistory = [self.delegate shouldAddItemToHistory:historyItem];
    }
    if (shouldAddItemToHistory) {
        if ([self.delegate respondsToSelector:@selector(willAddItemToHistory:)]) {
            historyItem = [self.delegate willAddItemToHistory:historyItem];
        }
        [self._history addObject:historyItem];
    }
    
    if (BMSCRIPT_DEBUG_HISTORY) {
        NSLog(@"%@ Debug: Script '%@' executed successfully.\n"
              @"Added to history = %@", [self className], [[self.source quotedString] truncatedString], self._history);
    }
    
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInteger:self.returnValue], BMScriptNotificationTaskReturnValue,
                                     [NSNumber numberWithInteger:status], BMScriptNotificationExecutionStatus, 
                                                             self.result, BMScriptNotificationTaskResults, nil];
    BM_LOCK(self)
    [[NSNotificationCenter defaultCenter] postNotificationName:BMScriptTaskDidEndNotification object:self userInfo:info];
    BM_UNLOCK(self)
    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(STOP_BG_TASK_END);
    #endif
}

- (void) taskTerminated:(NSNotification *) aNotification { 
    #pragma unused(aNotification)
    [self stopTask]; 
}

// MARK: Templates

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(SATURATE_WITH_ARGUMENT_BEGIN, (char *) [tArg UTF8String]);
    #endif
    if (self.isTemplate) {
        NSString * src = self.source;
        src = [src stringByReplacingOccurrencesOfString:BMSCRIPT_TEMPLATE_TOKEN_EMPTY 
                                             withString:tArg];
        self.source = src;
        self.isTemplate = NO;
        return YES;
    }
    return NO;
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_ARGUMENT_END, (char *) [[self.source quotedString] UTF8String]);
    #endif
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(SATURATE_WITH_ARGUMENTS_BEGIN);
    #endif
    BOOL success = NO;
    if (self.isTemplate) {
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        NSString * src = self.source;
        src = [src stringByReplacingOccurrencesOfString:BMSCRIPT_TEMPLATE_TOKEN_EMPTY withString:BMSCRIPT_TEMPLATE_TOKEN_INSERT];
        
        // determine how many replacements we need to make
        NSInteger numTokens = [src countOccurrencesOfString:BMSCRIPT_INSERTION_TOKEN];
        if (numTokens == NSNotFound) {
            goto endnow2;
        }
        
        NSString * accumulator = src;
        NSString * arg;
        
        NSUInteger tlen = [@""BMSCRIPT_TEMPLATE_TOKEN_INSERT"" length];
        
        NSAssert(tlen > 0, @"");
        
        va_list arglist;
        va_start(arglist, firstArg);
        
        NSRange searchRange = NSMakeRange(0, [accumulator rangeOfString:BMSCRIPT_TEMPLATE_TOKEN_START].location + tlen);
        
        // make sure we don't break composed grapheme clusters
        searchRange = [accumulator adjustRangeToIncludeComposedCharacterSequencesForRange:searchRange];
        
        accumulator = [accumulator stringByReplacingOccurrencesOfString:BMSCRIPT_TEMPLATE_TOKEN_INSERT
                                                             withString:firstArg 
                                                                options:0 
                                                                  range:searchRange];
        
        while (--numTokens > 0) {
            arg = va_arg(arglist, NSString *);
            searchRange = NSMakeRange(0, [accumulator rangeOfString:BMSCRIPT_INSERTION_TOKEN].location + tlen);
            searchRange = [accumulator adjustRangeToIncludeComposedCharacterSequencesForRange:searchRange];
            accumulator = [accumulator stringByReplacingOccurrencesOfString:BMSCRIPT_TEMPLATE_TOKEN_INSERT
                                                                 withString:arg 
                                                                    options:0 
                                                                      range:searchRange];
            if (numTokens <= 1) break;
        }
        
        va_end(arglist);
        
        //self.source = [accumulator stringByUnescapingPercentSigns];
        self.source = accumulator;
        self.isTemplate = NO;

        [pool drain];
        success = YES;
        goto endnow2;
    }
endnow2:
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_ARGUMENTS_END, (char *) [[self.source quotedString] UTF8String]);
    #endif
    return success;
}

- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary {
    
    BOOL success = NO;
    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_DICTIONARY_BEGIN, (char *) [[[dictionary descriptionInStringsFileFormat] quotedString] UTF8String]);
    #endif
    
    if (self.isTemplate) {
        
        NSString * accumulator = self.source;
        
        NSArray * keys = [dictionary allKeys];
        NSArray * values = [dictionary allValues];
        NSString * tokenStart;
        NSString * tokenEnd;
        
        if ((tokenStart = [dictionary objectForKey:BMScriptTemplateTokenStartKey]) && 
            (tokenEnd = [dictionary objectForKey:BMScriptTemplateTokenEndKey])) {
            ;
        } else {
            tokenStart = BMSCRIPT_TEMPLATE_TOKEN_START;
            tokenEnd = BMSCRIPT_TEMPLATE_TOKEN_END;
        }
        
        NSInteger i = 0;
        NSString * tokenString = nil;
        
        for (NSString * key in keys) {
            tokenString = [NSString stringWithFormat:@"%@"BMSCRIPT_INSERTION_TOKEN"%@", tokenStart, key, tokenEnd];
            accumulator = [accumulator stringByReplacingOccurrencesOfString:tokenString
                                                                 withString:[values objectAtIndex:i]];
            i++;
        }
        
        self.source = [accumulator stringByUnescapingPercentSigns];
        self.isTemplate = NO;
        
        success = YES;
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SATURATE_WITH_DICTIONARY_END, (char *) [[self.source quotedString] UTF8String]);
    #endif
    return success;
}



// MARK: Execution

- (ExecutionStatus) execute {
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:[NSString stringWithFormat:
                                               @"%@ Error: Please define all replacement values for the current template "
                                               @"by calling one of the -[saturateTemplate...] methods prior to execution", [self className]]
                                     userInfo:nil];
    }
    ExecutionStatus success = [self executeAndReturnResult:nil];
    return success;
}

- (ExecutionStatus) executeAndReturnResult:(NSData **)results {
    
    if (self.isTemplate) {
        @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                       reason:[NSString stringWithFormat:
                                               @"%@ Error: please define all replacement values for the current template "
                                               @"by calling one of the -[saturateTemplate...] methods prior to execution", [self className]]
                                     userInfo:nil];
    }
    
    ExecutionStatus success = [self executeAndReturnResult:results error:nil];
    
    return success;
}

- (ExecutionStatus) executeAndReturnResult:(NSData **)results error:(NSError **)error {
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(EXECUTE_BEGIN, 
                 (char *) [[[self.task launchPath] stringByWrappingSingleQuotes] UTF8String],
                 (char *) [[self.source quotedString] UTF8String], 
                 (char *) [BMNSStringFromBOOL(self.isTemplate) UTF8String]);
    #endif
    
    BOOL success = NO;
    ExecutionStatus status = BMScriptNotExecuted;
    
    if (self.isTemplate) {
        if (error) {
            NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:[NSString stringWithFormat:
                                                    @"%@ Error: Please define all replacement values for the current template "
                                                    @"by calling one of the -saturateTemplate... methods prior to execution", [self className]]
                                            forKey:NSLocalizedFailureReasonErrorKey];
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:errorDict];
        } else {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:[NSString stringWithFormat:
                                                   @"%@ Error: Please define all replacement values for the current template "
                                                   @"by calling one of the -saturateTemplate... methods prior to execution", [self className]]
                                         userInfo:nil];            
        }            
    } else {// isTemplate is NO
        
        BM_LOCK(task)
        success = [self setupTask];
        BM_UNLOCK(task)
        
        if (BM_EXPECTED(success, 1)) {
            
            status = [self launchTask];
            
            if (status == BMScriptFailedWithException) {
                if (error) {
                    NSString * reason = [NSString stringWithFormat:@"%@ Error: Executing the task raised an exception.", [self className]];
                    NSString * suggestion = [NSString stringWithFormat:@"Check launch path (path to the executable) and task arguments. "
                                                                       @"Often an exception by NSTask is raised because either or both are inappropriate."];               
                    NSDictionary * errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        reason, NSLocalizedFailureReasonErrorKey, 
                                                    suggestion, NSLocalizedRecoverySuggestionErrorKey, nil];
                    
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:errorDict];
                }
            } else if (status == BMScriptNotExecuted) {
                if (error) {
                    NSString * reason = [NSString stringWithFormat:@"%@ Error: Unable to execute task.", [self className]];
                    NSString * suggestion = [NSString stringWithFormat:@"Check launch path (path to the executable) and task arguments. "
                                                                       @"Often an NSTask refuses to execute because either or both are inappropriate."];
                    NSDictionary * errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        reason, NSLocalizedFailureReasonErrorKey, 
                                                    suggestion, NSLocalizedRecoverySuggestionErrorKey, nil];
                    
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:errorDict];
                }
            } else {
                if (results) {
                    *results = self.result;
                }
                
                NSArray * historyItem = [NSArray arrayWithObjects:self.source, self.result, nil];
                
                BOOL shouldAddItemToHistory = YES;
                if ([self.delegate respondsToSelector:@selector(shouldAddItemToHistory:)]) {
                    shouldAddItemToHistory = [self.delegate shouldAddItemToHistory:historyItem];
                }
                if (shouldAddItemToHistory) {
                    if ([self.delegate respondsToSelector:@selector(willAddItemToHistory:)]) {
                        historyItem = [self.delegate willAddItemToHistory:historyItem];
                    }
                    [self._history addObject:historyItem];
                }
                
                if (BMSCRIPT_DEBUG_HISTORY) {
                    NSLog(@"%@ Debug: Script '%@' executed successfully.\n"
                          @"Added to history = %@", [self className], [[self.source quotedString] truncatedString], self._history);
                }
            }
        } else {
            if (error) {
                NSString * errString = [NSString stringWithFormat:@"%@ Error: Task setup failed! (sorry, got no more info than that...)", [self className]];
                NSDictionary * errorDict = [NSDictionary dictionaryWithObject:errString 
                                                                       forKey:NSLocalizedFailureReasonErrorKey];
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:errorDict];
            }
        }
    }

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(EXECUTE_END, (char *) [[[self.result contentsAsString] quotedString] UTF8String]);
    #endif

    return status;
}


- (void) executeInBackgroundAndNotify {
    if (self.isTemplate) {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
    }
    
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(BG_EXECUTE_BEGIN, 
                 (char *) [[[self.options objectForKey:BMScriptOptionsTaskLaunchPathKey] stringByWrappingSingleQuotes] UTF8String],
                 (char *) [[self.source quotedString] UTF8String], 
                 (char *) [BMNSStringFromBOOL(self.isTemplate) UTF8String]);
    #endif
    
    [self setupAndLaunchBackgroundTask];
    
}

// MARK: Virtual (Readonly) Getters

- (NSArray *) history {
    return [[self._history copy] autorelease];
}

- (NSInteger) lastReturnValue {
    if (self.result) {
        return self.returnValue;
    } else {
        return BMScriptNotExecuted;
    }
}

// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(NSUInteger)index {

    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SCRIPT_AT_INDEX_BEGIN, index, (int) [self._history count]);
    #endif
    NSString * aScript = nil;
    NSUInteger hc = [self._history count];
    if (hc > 0 && index <= hc) {
        NSArray * item = [self._history objectAtIndex:index];
        if ([self.delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([self.delegate shouldReturnItemFromHistory:item]) {
                aScript = [[[item objectAtIndex:0] retain] autorelease];
            }
        } else {
            aScript = [[[item objectAtIndex:0] retain] autorelease];
        }
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException 
                                       reason:[NSString stringWithFormat:@"Index (%d) out of bounds (%d)", index, hc]
                                     userInfo:nil];                    
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(SCRIPT_AT_INDEX_END, (char *) [[aScript quotedString] UTF8String], (int) [self._history count]);
    #endif
    return aScript;
}

- (NSData *) resultFromHistoryAtIndex:(NSUInteger)index {
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(RESULT_AT_INDEX_BEGIN, index, (int) [self._history count]);
    #endif
    NSData * aResult = nil;
    NSUInteger hc = [self._history count];
    if (hc > 0 && index <= hc) {
        NSArray * item = [self._history objectAtIndex:index];
        if ([self.delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([self.delegate shouldReturnItemFromHistory:item]) {
                aResult = [[[item objectAtIndex:1] retain] autorelease];
            }
        } else {
            aResult = [[[item objectAtIndex:1] retain] autorelease];
        }
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException 
                                       reason:[NSString stringWithFormat:@"Index (%d) out of bounds (%d)", index, hc]
                                     userInfo:nil];                    
    }    
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(RESULT_AT_INDEX_END, (char *) [[[aResult contentsAsString] quotedString] UTF8String], (int) [self._history count]);
    #endif
    return aResult;
}

- (NSString *) lastScriptSourceFromHistory {
    #if (BMSCRIPT_ENABLE_DTRACE)    
        BM_PROBE(LAST_SCRIPT_BEGIN, (int) [self._history count]);
    #endif
    NSString * aScript = nil;
    if ([self._history count] > 0) {
        NSArray * item = [self._history lastObject];
        if ([self.delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([self.delegate shouldReturnItemFromHistory:item]) {
                aScript = [[[item objectAtIndex:0] retain] autorelease];
            }
        } else {
            aScript = [[[item objectAtIndex:0] retain] autorelease];
        }
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(LAST_SCRIPT_END, (char *) [[aScript quotedString] UTF8String], (int) [self._history count]);
    #endif
    return aScript;
}

- (NSData *) lastResultFromHistory {
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(LAST_RESULT_BEGIN, (int) [self._history count]);
    #endif
    NSData * aResult = nil;
    if ([self._history count] > 0) {
        NSArray * item = [self._history lastObject];
        if ([self.delegate respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
            if ([self.delegate shouldReturnItemFromHistory:item]) {
                aResult = [[[item objectAtIndex:1] retain] autorelease];
            }
        } else {
            aResult = [[[item objectAtIndex:1] retain] autorelease];
        }
    }
    #if (BMSCRIPT_ENABLE_DTRACE)
        BM_PROBE(LAST_RESULT_END, (char *) [[[aResult contentsAsString] quotedString] UTF8String], (int) [self._history count]);
    #endif
    return aResult;
}

// MARK: Equality

- (BOOL) isEqualToScript:(BMScript *)other {
    return [self.source isEqualToString:other.source];
}

- (BOOL) isEqual:(BMScript *)other {
    if (other == self) return YES;
    BOOL sameScript = [self.source isEqualToString:other.source];
    BOOL sameLaunchPath = [[self.options objectForKey:BMScriptOptionsTaskLaunchPathKey] 
                           isEqualToString:[other.options objectForKey:BMScriptOptionsTaskLaunchPathKey]];
    return sameScript && sameLaunchPath;
}

// MARK: NSCopying

- (id) copyWithZone:(NSZone *)zone {
    #pragma unused(zone)
    BMScript * copy = [[[self class] allocWithZone:zone] initWithScriptSource:self.source 
                                                                      options:self.options ];
    copy.result      = self.result;
    copy.returnValue = self.returnValue;
    copy._history    = [[self._history copy] autorelease];
    
    [copy setDelegate:self.delegate];
    return copy;
}

// MARK: NSCoding

- (void) encodeWithCoder:(NSCoder *)coder {
    // [super encodeWithCoder:coder]; // superclass (NSObject) doesn't implement NSCoding protocol
    [coder encodeObject:source];
    [coder encodeObject:result];
    [coder encodeObject:options];
    [coder encodeObject:_history];
    [coder encodeObject:task];
    [coder encodeObject:pipe];
    [coder encodeObject:bgTask];
    [coder encodeObject:bgPipe];
    [coder encodeObject:delegate];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
    [coder encodeValueOfObjCType:@encode(NSInteger) at:&returnValue];
}


- (id) initWithCoder:(NSCoder *)coder { 
    if ((self = [super init])) { // invoke superclass' designated initializer if it doesn't conform to the NSCoding protocol
        source      = [[coder decodeObject] retain];
        result      = [[coder decodeObject] retain];
        options     = [[coder decodeObject] retain];
        _history    = [[coder decodeObject] retain];
        task        = [[coder decodeObject] retain];
        pipe        = [[coder decodeObject] retain];
        bgTask      = [[coder decodeObject] retain];
        bgPipe      = [[coder decodeObject] retain];
        delegate    = [[coder decodeObject] retain];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&isTemplate];
        [coder decodeValueOfObjCType:@encode(NSInteger) at:&returnValue];
    }
    return self;
}

- (id) replacementObjectForPortCoder:(NSPortCoder *)encoder {
    if ([encoder isByref]) {
        return [NSDistantObject proxyWithLocal:self
                                    connection:[encoder connection]];
    } else {
        return self;
    }
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

// Shell 

+ (id) shellScriptWithSource:(NSString *)scriptSource {
	NSDictionary * opts = BMSynthesizeOptions(@"/bin/sh", @"-c");
    return [[[self alloc] initWithScriptSource:scriptSource options:opts] autorelease];
}

+ (id) shellScriptWithContentsOfFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/bin/sh", @"-c");
    return [[[self alloc] initWithContentsOfFile:path options:opts] autorelease];
}

+ (id) shellScriptWithContentsOfTemplateFile:(NSString *)path {
	NSDictionary * opts = BMSynthesizeOptions(@"/bin/sh", @"-c");
    return [[[self alloc] initWithContentsOfTemplateFile:path options:opts] autorelease];
}

@end


@implementation NSString (BMScriptStringUtilities)

- (NSString *) quotedString {
    
    NSString * quotedResult = self;
    NSArray * charSets = BMNSStringCommonEscapeCharacterMapping;
    NSUInteger cslen = [charSets count];
    
    for (NSUInteger i = 0; i < cslen; ++i) {
        NSArray * curSet = [charSets objectAtIndex:i];
        quotedResult = [quotedResult stringByReplacingOccurrencesOfString:[curSet objectAtIndex:0] 
                                                               withString:[curSet objectAtIndex:1]];
    }
    
    return quotedResult;
}

- (NSString *) unquotedString {
    
    NSString * unquotedResult = self;
    NSArray * charSets = BMNSStringCommonEscapeCharacterMapping;
    NSUInteger cslen = [charSets count];
    
    for (NSUInteger i = 0; i < cslen; ++i) {
        NSArray * curSet = [charSets objectAtIndex:i];
        unquotedResult = [unquotedResult stringByReplacingOccurrencesOfString:[curSet objectAtIndex:1] 
                                                                   withString:[curSet objectAtIndex:0]];
    }
    
    return unquotedResult;
}

- (NSString *) escapedString {
    return [self stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderFirst];
}

- (NSString *) unescapedStringUsingOrder:(BMNSStringEscapeTraversingOrder)order {
    
    NSString * unescapedResult = self;
    NSArray * charSets = BMNSStringC99EscapeCharacterMapping;
    NSUInteger cslen = [charSets count];
    NSUInteger i;
    NSInteger j;
    
    //NSLog(@"[%@%s]: self = %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, self);
    
    switch (order) {
        case BMNSStringEscapeTraversingOrderFirst:
            for (i = 0; i < cslen; ++i) {
                NSArray * curSet = [charSets objectAtIndex:i];
                unescapedResult = [unescapedResult stringByReplacingOccurrencesOfString:[curSet objectAtIndex:1] 
                                                                             withString:[curSet objectAtIndex:0]];
                //NSLog(@"escapedResult after replacing %@: %@", [curSet objectAtIndex:1], escapedResult);
            }
            break;
        case BMNSStringEscapeTraversingOrderLast:
            for (j = --cslen; j >= 0; ) {
                NSArray * curSet = [charSets objectAtIndex:j--];
                unescapedResult = [unescapedResult stringByReplacingOccurrencesOfString:[curSet objectAtIndex:1] 
                                                                             withString:[curSet objectAtIndex:0]];
                //NSLog(@"escapedResult after replacing %@: %@", [curSet objectAtIndex:1], escapedResult);
            }            
            break;
        default:
            break;
    }
    
    return unescapedResult;
}

- (NSString *) stringByEscapingStringUsingOrder:(BMNSStringEscapeTraversingOrder)order {
    return [self stringByEscapingStringUsingMapping:nil order:order];
}

- (NSString *) stringByEscapingStringUsingMapping:(BMNSStringEscapeCharacterMapping *)mapping order:(BMNSStringEscapeTraversingOrder)order {
    
    NSString * escapedResult = self;
    BMNSStringEscapeCharacterMapping * charSets = BMNSStringC99EscapeCharacterMapping;
    
    if (mapping) {
        charSets = mapping;
    }
    if (![charSets count] > 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException 
                                       reason:[NSString stringWithFormat:@"[%@ %@] 'mapping' has no items (mapping = %@) ***", 
                                                [self class], NSStringFromSelector(_cmd), mapping]
                                     userInfo:nil];
    }
    
    NSUInteger cslen = [charSets count];
    NSUInteger i;
    NSInteger j;
    
    //NSLog(@"[%@%s]: self = %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, self);
    
    switch (order) {
        case BMNSStringEscapeTraversingOrderFirst:
            for (i = 0; i < cslen; i++) {
                NSArray * curSet = [charSets objectAtIndex:i];
                escapedResult = [escapedResult stringByReplacingOccurrencesOfString:[curSet objectAtIndex:0] 
                                                                         withString:[curSet objectAtIndex:1]];
                //NSLog(@"escapedResult after replacing %@: %@", [curSet objectAtIndex:1], escapedResult);
            }
            break;
        case BMNSStringEscapeTraversingOrderLast:
            for (j = --cslen; j >= 0; ) {
                NSArray * curSet = [charSets objectAtIndex:j--];
                escapedResult = [escapedResult stringByReplacingOccurrencesOfString:[curSet objectAtIndex:0] 
                                                                         withString:[curSet objectAtIndex:1]];
                //NSLog(@"escapedResult after replacing %@: %@", [curSet objectAtIndex:1], escapedResult);
            }
            break;
        default:
            break;
    }
    
    return escapedResult;
}

- (NSString *) stringByEscapingUnicodeCharacters {
    
    NSMutableString * uniString = [[NSMutableString alloc] init];
    
    UniChar * uniBuffer = (UniChar *)malloc(sizeof(UniChar) * [self length]);
    CFRange stringRange = CFRangeMake(0, [self length]);
    
    CFStringGetCharacters((CFStringRef)self, stringRange, uniBuffer);
    
    for (unsigned long i = 0; i < [self length]; i++ ) {
        if (uniBuffer[i] > 0x7e) {
            [uniString appendFormat:@"\\u%04x", uniBuffer[i]];
        } else {
            [uniString appendFormat:@"%c", uniBuffer[i]];
        }
    }
    
    free(uniBuffer);
    
    NSString * retString = [NSString stringWithString:uniString];
    [uniString release], uniString = nil;
    
    return retString;
}

- (NSString *) stringByEscapingPercentSigns {
    return [self stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
}

- (NSString *) stringByUnescapingPercentSigns {
    return [self stringByReplacingOccurrencesOfString:@"%%" withString:@"%"];
}

- (NSString *) stringByNormalizingPercentSigns {
    NSMutableString * result = [NSMutableString string];
    NSUInteger slen = [self length];
    if (!slen) {
        return nil;
    }
    NSUInteger i;
    BOOL wasPercentSign = NO;
    for (i = 0; i < slen; i++) {
        unichar uc = [self characterAtIndex:i];
        if (uc == '%') {
            if (!wasPercentSign) {
                [result appendFormat:@"%C", uc];
                wasPercentSign = YES;
            }
        } else {
            [result appendFormat:@"%C", uc];
            wasPercentSign = NO;
        }
    }
    return result;
}

- (NSString *) stringByWrappingSingleQuotes { 
    return [NSString stringWithFormat:@"'%@'", self]; 
}

- (NSString *) stringByWrappingDoubleQuotes {
    return [NSString stringWithFormat:@"\"%@\"", self]; 
}

- (NSString *) chomp {
    
    NSUInteger slen = [self length];
    NSString * lastChar = [self substringWithRange:NSMakeRange(slen-1, 1)];
    
    if ([lastChar isEqualToString:@"\n"] || [lastChar isEqualToString:@"\r"]) {
        return [self substringWithRange:NSMakeRange(0, [self length] - 1)];
    }
    
    return self;
}

- (NSString *) truncatedString {
    #ifdef BMNSSTRING_TRUNCATE_LENGTH
        NSUInteger len = BMNSSTRING_TRUNCATE_LENGTH;
    #else
        NSUInteger len = 20;
    #endif
    if ([self length] < len) {
        return self;
    }
    return [self stringByTruncatingToLength:len];
}

- (NSString *) stringByTruncatingToLength:(NSUInteger)len {
    if ([self length] < len) {
        return self;
    }
    NSRange range = (NSMakeRange(0, len));
    return [[self substringWithRange:[self adjustRangeToIncludeComposedCharacterSequencesForRange:range]] stringByAppendingString:BMNSSTRING_TRUNCATE_TOKEN];
}

- (NSString *) stringByTruncatingToLength:(NSUInteger)targetLength mode:(BMNSStringTruncateMode)mode indicator:(NSString *)indicatorString {
    
    NSString * res = nil;
    NSString * firstPart;
    NSString * lastPart;
    
    if (!indicatorString) {
        indicatorString = BMNSSTRING_TRUNCATE_TOKEN;
    }
    
    NSUInteger stringLength = [self length];
    NSUInteger ilength = [indicatorString length];
    
    if (stringLength <= targetLength) {
        return self;
    } else if (stringLength <= 0 || (!self)) {
        return nil;
    } else {
        switch (mode) {
            case BMNSStringTruncateModeCenter:
                firstPart = [self substringToIndex:(targetLength/2)];
                lastPart = [self substringFromIndex:(stringLength-((targetLength/2))+ilength)];
                res = [NSString stringWithFormat:@"%@%@%@", firstPart, indicatorString, lastPart];                
                break;
            case BMNSStringTruncateModeStart:
                res = [NSString stringWithFormat:@"%@%@", indicatorString, [self substringFromIndex:((stringLength-targetLength)+ilength)]];
                break;
            case BMNSStringTruncateModeEnd:
                res = [NSString stringWithFormat:@"%@%@", [self substringToIndex:(targetLength-ilength)], indicatorString];
                break;
            default:
                ;
                NSException * myException = [NSException exceptionWithName:NSInvalidArgumentException 
                                                                    reason:[NSString stringWithFormat:@"[%@ %@] called with invalid value for 'mode' (mode = %d) ***",
                                                                            [self class], NSStringFromSelector(_cmd), mode]
                                                                  userInfo:nil];
                @throw myException;
                return res;
                break;
        };
    }
    return res;
}

- (NSInteger) countOccurrencesOfString:(NSString *)aString {
    NSParameterAssert(aString);
    NSInteger num = ((NSInteger)[[NSArray arrayWithArray:[self componentsSeparatedByString:aString]] count] - 1);
    if (num > 0) {
        return num;
    }
    return NSNotFound;
}

- (NSArray *) bytesForEncoding:(NSStringEncoding)enc asHex:(BOOL)asHex {
    
    if (!self) return nil;
    if ([self length] == 0) return [NSArray array];
    if (!enc) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException 
                                       reason:@"enc must be a valid NSStringEncoding" 
                                     userInfo:nil];
    }
    NSUInteger len = [self length];
    NSUInteger ulen;
    NSRangePointer rp = NULL;
    char bytes[len];
    BOOL success = [self getBytes:bytes 
                        maxLength:len 
                       usedLength:&ulen 
                         encoding:enc 
                          options:NSStringEncodingConversionExternalRepresentation 
                            range:NSMakeRange(0, len) 
                   remainingRange:rp];
    if (!success) {
        return nil;
    }
    
    NSString * fmt = nil;
    if (asHex) {
        fmt = @"%#x";
    } else {
        fmt = @"%u";
    }
    size_t blen = strlen(bytes);
    NSMutableArray * bytesArray = [NSMutableArray arrayWithCapacity:blen];
    NSUInteger i;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    for (i = 0; i<ulen; i++) {
        char ch = bytes[i];
        [bytesArray insertObject:[NSString stringWithFormat:fmt, ch] atIndex:i];
    }
    [pool drain];
    return [NSArray arrayWithArray:bytesArray];
}

- (NSRange) adjustRangeToIncludeComposedCharacterSequencesForRange:(NSRange)aRange {
    
    NSUInteger index, endIndex;
    NSRange newRange, endRange;
    
    // Check for validity of range
    if ((aRange.location >= [self length]) ||
        (NSMaxRange(aRange) > [self length])) {
        [NSException raise:NSRangeException format:@"Invalid  range %@.",
         NSStringFromRange(aRange)];
    }
    
    index = aRange.location;
    newRange = [self rangeOfComposedCharacterSequenceAtIndex:index];
    
    index = aRange.location + aRange.length - 1;
    endRange = [self rangeOfComposedCharacterSequenceAtIndex:index];
    endIndex = endRange.location + endRange.length;
    
    newRange.length = endIndex - newRange.location;
    
    return newRange;
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


@implementation NSArray (BMScriptUtilities)

- (BOOL) isEmptyStringArray {
    for (NSString * str in self) {
        if (![str isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL) isZeroArray {
    return [NSStringFromClass([self class]) isEqualToString:@"__NSArray0"];
}

@end

@implementation NSData (BMScriptUtilities)

- (NSString *) contentsAsString {
    NSString * string = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    if (!string) {
        string = [[NSString alloc] initWithString:[self description]];
    }
    return [string autorelease];
}

@end


///@endcond

