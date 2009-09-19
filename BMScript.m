//
//  BMScript.m
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import "BMScript.h"

#include <unistd.h>         /* for usleep       */
#include <pthread.h>        /* for pthread_*    */


#define DEBUG 0
#define DEBUG_HISTORY 0
#define DEBUG_MEMORY 0

// #define INCONSISTENCY_REASON(_X_) ([NSString stringWithFormat:@"Decendants of BMScript must not call %s directly. "\
//                                                               @"It is called as needed by the execution methods of BMScript. "\
//                                                               @"Trying to set %@ directly causes internal inconsistencies.",\
//                                                               __PRETTY_FUNCTION__, (_X_)])

// Master Yoda sayz: Not use retainCount you must, young padawan!
#define RETAIN_COUNT_FOOTPRINT {\
    NSLog(@"inside %@ of instance %@", NSStringFromSelector(_cmd), [super description]);\
    NSLog(@"------------------------------");\
    [self printRetainCounts];\
    NSLog(@"------------------------------");\
}

#if THREAD_SAFE
    #define synchronized @synchronized(self)
    #define pthread_lock \
    static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;\
    if (pthread_mutex_lock(&mtx)) {\
        printf("*** Warning: Lock failed! Application behaviour may be undefined. Exiting...");\
        exit(EXIT_FAILURE);\
    }
    #define pthread_unlock \
    if ((pthread_mutex_unlock(&mtx) != 0)) {\
        printf("*** Warning: Unlock failed! Application behaviour may be undefined. Exiting...");\
        exit(EXIT_FAILURE);\
    }
#else
    #define synchronized
    #define pthread_lock
    #define pthread_unlock
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

static BOOL s_isTemplate;
static BOOL s_hasDelegate = NO;

static TerminationStatus s_taskStatus = BMScriptNotExecutedTerminationStatus;
static TerminationStatus s_bgTaskStatus = BMScriptNotExecutedTerminationStatus;

@interface BMScript (Private)

- (BOOL) setupTask;
- (TerminationStatus) launchTaskAndStoreLastResult;
- (void) setupAndlaunchBackgroundTask;
- (void) taskTerminated:(NSNotification *)aNotification;
- (void) appendData:(NSData *)d;
- (void) printRetainCounts;

// MARK: Private Accessors
- (NSTask *)task;
- (void)setTask:(NSTask *)newTask;
- (NSPipe *)pipe;
- (void)setOutPipe:(NSPipe *)newOutPipe;
- (NSString *) defaultScript;
- (void) setDefaultScript: (NSString *) newDefaultScript;
- (NSDictionary *) defaultOptions;
- (void) setDefaultOptions: (NSDictionary *) newDefaultOptions;
- (NSThread *) bgThread;
- (void) setBgThread: (NSThread *) newBgThread;
- (NSPipe *) bgPipe;
- (void) setBgPipe:(NSPipe *)newBgPipe;
- (NSString *)partialResult;
- (void)setPartialResult:(NSString *)newPartialResult;

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
        NSString * item = [newScript copy];
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldSetScript:)]) {
                if ([self shouldSetScript:item]) {
                    [script release];
                    script = item;
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldSetScript:)]) {
                if ([self shouldSetScript:item]) {
                    [script release];
                    script = item;
                }
            } else {
                [script release];
                script = item;
            }
        }
    }
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

//=========================================================== 
//  lastResult 
//=========================================================== 
- (NSString *)lastResult {
    return [[lastResult copy] autorelease]; 
}

- (void)setLastResult:(NSString *)newLastResult {
    if (lastResult != newLastResult) {
        [lastResult release];
        lastResult = [newLastResult copy];
    }
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
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
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldSetOptions:)]) {
                if ([self shouldSetOptions:item]) {
                    [options release];
                    options = item;
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldSetOptions:)]) {
                if ([self shouldSetOptions:item]) {
                    [options release];
                    options = item;
                }
            } else {
                [options release];
                options = item;
            }
        }
    }
    
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

//=========================================================== 
//  history 
//=========================================================== 
- (NSMutableArray *)history {
    NSMutableArray * result;
    pthread_lock
    result = [[history retain] autorelease];
    pthread_unlock
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
    return result;
}

- (void)setHistory:(NSMutableArray *)newHistory {
    pthread_lock
    if (history != newHistory) {
        [history release];
        history = [newHistory retain];
    }
    pthread_unlock
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
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
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
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
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

//=========================================================== 
//  defaultScript 
//=========================================================== 
- (NSString *)defaultScript {
    return [[defaultScript copy] autorelease]; 
}

- (void)setDefaultScript:(NSString *)newDefaultScript {
    if (defaultScript != newDefaultScript) {
        [defaultScript release];
        defaultScript = [newDefaultScript copy];
    }
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

//=========================================================== 
//  defaultOptions 
//=========================================================== 
- (NSDictionary *)defaultOptions {
    return [[defaultOptions copy] autorelease]; 
}

- (void)setDefaultOptions:(NSDictionary *)newDefaultOptions {
    if (defaultOptions != newDefaultOptions) {
        [defaultOptions release];
        defaultOptions = [newDefaultOptions copy];
    }
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

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
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
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
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

//=========================================================== 
//  partialResult 
//=========================================================== 
- (NSString *)partialResult {
    return [[partialResult copy] autorelease];
}

- (void)setPartialResult:(NSString *)newPartialResult {
    pthread_lock
    if (partialResult != newPartialResult) {
        [partialResult release];
        partialResult = [newPartialResult copy];
    }
    pthread_unlock
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}

//=========================================================== 
//  delegate 
//=========================================================== 
- (id)delegate {
    return delegate; 
}

- (void)setDelegate:(id)newDelegate {
    pthread_lock
    if (delegate != newDelegate && !s_hasDelegate) {
        delegate = newDelegate;
        s_hasDelegate = YES;
    }
    pthread_unlock
    if (DEBUG_MEMORY) RETAIN_COUNT_FOOTPRINT;
}


// MARK: Deallocation

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [script autorelease];
    [history autorelease];
    [options autorelease];
    [task autorelease];
    [lastResult autorelease];
    [pipe autorelease];
    [defaultScript autorelease];
    [defaultOptions autorelease];
    [bgTask autorelease];
    [bgPipe autorelease];

    [super dealloc];
}

// MARK: Description

- (NSString *) description {
    return [NSString stringWithFormat:@"%@,\n script: '%@',\n history (count %d): %@,\n lastResult: %@,\n options: %@", 
            [super description], [script quote], [history count], history, lastResult, [options descriptionInStringsFileFormat]];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@,\n task: %@,\n pipe: %@,\n bgTask: %@,\n bgPipe: %@", 
            [self description], bgTask, pipe, bgTask, bgPipe ];
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
    
    if (![self conformsToProtocol:@protocol(BMScriptLanguageProtocol)]) {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolDoesNotConformException 
                                       reason:@"descendants of BMScript must conform to the BMScriptLanguageProtocol" 
                                     userInfo:nil];
    }
    
    if ([self respondsToSelector:@selector(defaultScriptSourceForLanguage)]) {
        defaultScript = [[self defaultScriptSourceForLanguage] retain];
    } else {
        defaultScript = @"";
    }
    
    if ([self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
        defaultOptions = [[self defaultOptionsForLanguage] retain];
    } else {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                       reason:@"descendants of BMScript must implement -[defaultOptionsForLanguage]" 
                                     userInfo:nil];
    }
    self = [super init];
    if (self != nil) {
        if (!scriptSource) {
            scriptSource = defaultScript;
        }
        if (scriptOptions) {
            options = [scriptOptions retain];
        } else {                
            if (DEBUG) NSLog(@"defaultOptions: %@", [defaultOptions descriptionInStringsFileFormat]);
            options = [defaultOptions retain];
        }
        script = [scriptSource retain];
        history = [[NSMutableArray alloc] init];
        lastResult = [[NSString alloc] init];
        partialResult = [[NSString alloc] init];
        pthread_lock
        s_hasDelegate = NO;
        pthread_unlock
    }
    if (DEBUG) NSLog(@"self = %@", self);
    return self;
}

- (id) initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfFile:path options:nil];
}

- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions {
    NSError * err;
    NSString * scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (scriptSource) {
        pthread_lock
        s_isTemplate = NO;
        pthread_unlock
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
        pthread_lock
        s_isTemplate = YES;
        pthread_unlock
        scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
        scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%%{}" withString:@"%%{%@}"];
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

// + (id) scriptWithContentsOfURL:(NSURL *)url {
//     return [self scriptWithContentsOfURL:url options:nil];
// }
// + (id) scriptWithContentsOfURL:(NSURL *)url options:(NSDictionary *)scriptOptions {
//     NSError * err;
//     NSString * scriptSource = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
//     if (scriptSource) {
//         scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
//         scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%%{}" withString:@"%%{%@}"];
//         return [[[self alloc] initWithScriptSource:scriptSource options:scriptOptions] autorelease];
//     } else {
//         NSLog(@"Error reading file at URL '%@'\n%@", url, [err localizedFailureReason]);
//     }
//     return nil;
// }

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
          [self retainCount], 
          [script retainCount],
          [lastResult retainCount], 
          [delegate retainCount],
          [options retainCount],
          [history retainCount],
          [task retainCount],
          [pipe retainCount],
          [defaultScript retainCount],
          [defaultOptions retainCount],
          [bgTask retainCount],
          [bgPipe retainCount],
          [partialResult retainCount]);
}

- (BOOL) setupTask {
    
    if (DEBUG) usleep(500000);
    
    task = [[NSTask alloc] init];
    pipe = [[NSPipe alloc] init];
    
    if (task && pipe) {
        NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
        args = [args arrayByAddingObject:script];
        NSString * path = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
        
        [task setLaunchPath:path];
        [task setArguments:args];
        [task setStandardOutput:pipe];
        [task setStandardError:pipe];
        
        if (DEBUG) NSLog(@"self debugDescription: %@", [self debugDescription]);
        
        return YES;
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
    pthread_lock
    s_taskStatus = status;
    pthread_unlock
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (s_hasDelegate) {
        if ([[self delegate] respondsToSelector:@selector(shouldSetLastResult:)]) {
            if ([[self delegate] shouldSetLastResult:string]) {
                [self setLastResult:string];
            }
        }
    } else {
        if ([self respondsToSelector:@selector(shouldSetLastResult:)]) {
            if ([self shouldSetLastResult:string]) {
                [self setLastResult:string];
            }
        } else {
            [self setLastResult:string];
        }
    }
    [string release];
    return status;
}

/* fires a one-off (non-blocking or asynchroneous) task and reels in the results 
   one after another thru notifications */
- (void) setupAndlaunchBackgroundTask {
    
    if ([bgTask isRunning]) {
        [bgTask terminate];
    } else {
        // Create a task and pipe
        bgTask = [[NSTask alloc] init];
        bgPipe = [[NSPipe alloc] init];
        
        if (bgTask && bgPipe) {
            
            NSArray * args = [options objectForKey:BMScriptOptionsTaskArgumentsKey];
            args = [args arrayByAddingObject:[self script]];
            NSString * path = [options objectForKey:BMScriptOptionsTaskLaunchPathKey];
            
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
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldAppendPartialResult:)]) {
                if ([[self delegate] shouldAppendPartialResult:string]) {
                    [self setPartialResult:[[self partialResult] stringByAppendingString:string]];
                }
            }
            if ([[self delegate] respondsToSelector:@selector(shouldSetLastResult:)]) {
                if ([[self delegate] shouldSetLastResult:string]) {
                    [self setLastResult:[[self partialResult] stringByAppendingString:string]];
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldAppendPartialResult:)]) {
                if ([self shouldAppendPartialResult:string]) {
                    [self setPartialResult:[[self partialResult] stringByAppendingString:string]];
                }
            } else {
                [self setPartialResult:[[self partialResult] stringByAppendingString:string]];
            }
            if ([self respondsToSelector:@selector(shouldSetLastResult:)]) {
                if ([self shouldSetLastResult:string]) {
                    [self setLastResult:[[self partialResult] stringByAppendingString:string]];
                }
            } else {
                [self setLastResult:[[self partialResult] stringByAppendingString:string]];
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
    
    s_bgTaskStatus = [[aNotification object] terminationStatus];
        
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:s_bgTaskStatus], BMScriptNotificationInfoTaskTerminationStatusKey, 
                           [self lastResult], BMScriptNotificationInfoTaskResultsKey, nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:BMScriptTaskDidEndNotification object:[self bgTask] userInfo:info]];
    
    NSArray * historyItem = [NSArray arrayWithObjects:[self script], [self lastResult], nil];
    [[self history] addObject:historyItem];
    if (DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
    
    if ([self conformsToProtocol:@protocol(BMScriptLanguageProtocol)]) {
        if ([self respondsToSelector:@selector(taskFinishedCallback:)]) {
            [self taskFinishedCallback:[self copy]];
        }
    }
}

// MARK: Templates

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    if (s_isTemplate) {
        [self setScript:[NSString stringWithFormat:[self script], tArg]];
        pthread_lock
        s_isTemplate = NO;
        pthread_unlock
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {
    
    if (s_isTemplate) {
        // determine how many replacements we need to make
        NSInteger numTokens = [script countOccurrencesOfString:REPLACEMENT_TOKEN];
        if (numTokens == NSNotFound) {
            return NO;
        }
        
        NSString * accumulator = [self script];
        NSString * arg;
        
        va_list arglist;
        va_start(arglist, firstArg);
        
        NSRange searchRange = NSMakeRange(0, [accumulator rangeOfString:REPLACEMENT_TOKEN].location + [REPLACEMENT_TOKEN length]);
        
        accumulator = [accumulator stringByReplacingOccurrencesOfString:REPLACEMENT_TOKEN
                                                             withString:firstArg 
                                                                options:NSLiteralSearch 
                                                                  range:searchRange];
        
        while (--numTokens > 0) {
            arg = va_arg(arglist, NSString *);
            searchRange = NSMakeRange(0, [accumulator rangeOfString:REPLACEMENT_TOKEN].location + [REPLACEMENT_TOKEN length]);
            accumulator = [accumulator stringByReplacingOccurrencesOfString:REPLACEMENT_TOKEN
                                                                 withString:arg 
                                                                    options:NSLiteralSearch 
                                                                      range:searchRange];
            if (numTokens <= 1) break;
        }
        
        va_end(arglist);
        
        [self setScript:[accumulator stringByReplacingOccurrencesOfString:@"%%" withString:@"%"]];
        pthread_lock
        s_isTemplate = NO;
        pthread_unlock
        
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary {
    // TODO: stub
    return NO;
}



// MARK: Execution

- (BOOL) execute {
    if (s_isTemplate) {
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
    if (s_isTemplate) {
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
    if (s_isTemplate) {
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
    
    BOOL success = NO;
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    pthread_lock
    s_taskStatus = status;
    pthread_unlock
    
    if (s_isTemplate) {
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
            if (s_hasDelegate) {
                if ([[self delegate] respondsToSelector:@selector(shouldAddItemToHistory:)]) {
                    if ([self shouldAddItemToHistory:historyItem]) {
                        [history addObject:historyItem];
                    }
                }
            } else {
                if ([self respondsToSelector:@selector(shouldAddItemToHistory:)]) {
                    if ([self shouldAddItemToHistory:historyItem]) {
                        [history addObject:historyItem];
                    }
                } else {
                    [history addObject:historyItem];
                }
            }
            if (DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
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
    return success;
}


- (void) executeInBackgroundAndNotify {
    
    TerminationStatus status = BMScriptNotExecutedTerminationStatus;
    s_bgTaskStatus = status;
    
    if (s_isTemplate) {
            @throw [NSException exceptionWithName:BMScriptTemplateArgumentMissingException 
                                           reason:@"please define all replacement values for the current template "
                                                  @"by calling one of the -[saturateTemplate...] methods prior to execution" 
                                         userInfo:nil];            
    }
    
    [self setupAndlaunchBackgroundTask];
    
}

// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(NSInteger)index {
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:0];
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            } else {
                return item;
            }
        }
    }
    return nil;
}

- (NSString *) resultFromHistoryAtIndex:(NSInteger)index {
    if ([history count] > 0) {
        NSString * item = [[[self history] objectAtIndex:index] objectAtIndex:1];
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            } else {
                return item;
            }
        }
    }
    return nil;
}

- (NSString *) lastScriptSourceFromHistory {
    if ([history count] > 0) {
        NSString * item = [[[self history] lastObject] objectAtIndex:0];
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            } else {
                return item;
            }
        }
    }
    return nil;
}

- (NSString *) lastResultFromHistory {
    if ([history count] > 0) {
        NSString * item = [[[self history] lastObject] objectAtIndex:1];
        if (s_hasDelegate) {
            if ([[self delegate] respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            }
        } else {
            if ([self respondsToSelector:@selector(shouldReturnItemFromHistory:)]) {
                if ([self shouldReturnItemFromHistory:item]) {
                    return item;
                }
            } else {
                return item;
            }
        }
    }
    return nil;
}

// MARK: Delegate Methods

- (BOOL) shouldAddItemToHistory:(id)anItem { return YES; }
- (BOOL) shouldReturnItemFromHistory:(id)anItem { return YES; }
- (BOOL) shouldSetLastResult:(NSString *)aString { return YES; }
- (BOOL) shouldAppendPartialResult:(NSString *)string { return YES; }
- (BOOL) shouldSetScript:(NSString *)aScript { return YES; }
- (BOOL) shouldSetOptions:(NSDictionary *)opts { return YES; }


// MARK: BMScriptLanguage

- (NSDictionary *) defaultOptionsForLanguage {
    SynthesizeOptions(@"/bin/echo", nil);
    return defaultDict;
}

- (NSString *) defaultScriptSourceForLanguage {
    return @"BMScript running default task (/bin/echo) with this message as value for the script source.\n"
           @"If you want to customize BMScript you can create a subclass easily with help of the BMScriptLanguageProtocol\n "
           @"which describes a required method for supplying the default options dictionary and some optional methods.\n "
           @"You can also call one of BMScript's many initializer and convenience factory methods to provide default options\n "
           @"such as task launch path and arguments and a default script to execute.\n";
}

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
    [coder encodeObject:defaultScript];
    [coder encodeObject:defaultOptions];
    [coder encodeObject:bgTask];
    [coder encodeObject:bgPipe];
    [coder encodeObject:partialResult];
}


- (id) initWithCoder:(NSCoder *)coder { 
    if (self = [super init]) { 
        int version = [coder versionForClassName:NSStringFromClass([self class])]; 
        NSLog(@"class version = %i", version);
        script          = [[coder decodeObject] retain];
        lastResult      = [[coder decodeObject] retain];
        options         = [[coder decodeObject] retain];
        history         = [[coder decodeObject] retain];
        task            = [[coder decodeObject] retain];
        pipe            = [[coder decodeObject] retain];
        defaultScript   = [[coder decodeObject] retain];
        defaultOptions  = [[coder decodeObject] retain];
        bgTask          = [[coder decodeObject] retain];
        bgPipe          = [[coder decodeObject] retain];
        partialResult   = [[coder decodeObject] retain];
        
    }
    return self;
}

// MARK: Misc

- (NSUInteger) hash {
    NSUInteger scriptHash = [script hash];
    NSUInteger selfHash   = [self hash];
    return selfHash & scriptHash;
}

- (BOOL) isEqual:(id)other {
    if ([self hash] == [other hash]) {
        return YES;
    }
    return NO;
}

@end

@implementation BMScript (CommonScriptLanguagesFactories)

// Ruby

+ (id) rubyScriptWithSource:(NSString *)scriptSource {
    SynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e", nil);
    return [[[self alloc] initWithScriptSource:scriptSource options:defaultDict] autorelease];
}

+ (id) rubyScriptWithContentsOfFile:(NSString *)path {
    SynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e", nil);
    return [[[self alloc] initWithContentsOfFile:path options:defaultDict] autorelease];
}

+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path {
	SynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e", nil);
    return [[[self alloc] initWithContentsOfTemplateFile:path options:defaultDict] autorelease];
}

// Python 

+ (id) pythonScriptWithSource:(NSString *)scriptSource {
    SynthesizeOptions(@"/usr/bin/python", @"-c", nil);
    return [[[self alloc] initWithScriptSource:scriptSource options:defaultDict] autorelease];
}

+ (id) pythonScriptWithContentsOfFile:(NSString *)path {
    SynthesizeOptions(@"/usr/bin/python", @"-c", nil);
    return [[[self alloc] initWithContentsOfFile:path options:defaultDict] autorelease];
}

+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path {
    SynthesizeOptions(@"/usr/bin/python", @"-c", nil);
    return [[[self alloc] initWithContentsOfTemplateFile:path options:defaultDict] autorelease];
}

// Perl

+ (id) perlScriptWithSource:(NSString *)scriptSource {
	SynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e", nil);
    return [[[self alloc] initWithScriptSource:scriptSource options:defaultDict] autorelease];
}

+ (id) perlScriptWithContentsOfFile:(NSString *)path {
	SynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e", nil);
    return [[[self alloc] initWithContentsOfFile:path options:defaultDict] autorelease];
}

+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path {
	SynthesizeOptions(@"/usr/bin/perl", @"-Mutf8", @"-e", nil);
    return [[[self alloc] initWithContentsOfTemplateFile:path options:defaultDict] autorelease];
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
#ifdef TRUNCATE_LENGTH
    NSUInteger len = TRUNCATE_LENGTH;
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
