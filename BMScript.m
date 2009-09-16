//
//  BMScript.m
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import "BMScript.h"

#define DEBUG 0
#define DEBUG_HISTORY 0

#define TRUNCATE_LENGTH 20
#define REPLACEMENT_TOKEN @"%@"  /* used by templates to mark locations where a replacement should occurr */

#if BMS_THREAD_SAFE
#define synchronized @synchronized(self)
#else
#define synchronized
#endif

#define ap_start NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_3
#define ap_end   [pool drain];
#else
#define ap_end   [pool release];
#endif

NSString * const BMScriptTaskDidEndNotification   = @"BMScriptTaskDidEndNotification";

NSString * const BMScriptOptionsTaskLaunchPathKey = @"BMScriptOptionsTaskLaunchPathKey";
NSString * const BMScriptOptionsTaskArgumentsKey  = @"BMScriptOptionsTaskArgumentsKey";
NSString * const BMScriptOptionsRubyVersionKey    = @"BMScriptOptionsRubyVersionKey"; /* unused */

NSString * const BMScriptTemplateArgumentMissingException  = @"BMScriptTemplateArgumentMissingException";
NSString * const BMScriptTemplateArgumentsMissingException = @"BMScriptTemplateArgumentsMissingException";

NSString * const BMScriptLanguageProtocolDoesNotConformException = @"BMScriptLanguageProtocolDoesNotConformException";
NSString * const BMScriptLanguageProtocolMethodMissingException  = @"BMScriptLanguageProtocolMethodMissingException";


static BOOL isTemplate;

@interface BMScript (Private)
- (BOOL) setupTask;
- (TerminationStatus) launchTaskAndStoreLastResult;
- (void) threadLoop; 
@end


@implementation BMScript

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
// MARK: Properties (10.5+)
@synthesize script;
@synthesize history;
@synthesize options;
@synthesize rubyTask;
// @synthesize taskArgs;
@synthesize lastResult;
@synthesize outPipe;
@synthesize defaultScript;
@synthesize defaultOptions;
@synthesize conditionLock;
@synthesize bgThread;
#else
// MARK: Accessors (10.4)
//=========================================================== 
//  script 
//=========================================================== 

- (NSString *) script {
    NSString *result;
    synchronized {
        result = [script copy];
    }
    return [result autorelease];
}

- (void)setScript:(NSString *) newScript {
    synchronized {
        if (script != newScript) {
            [script release];
            script = [newScript copy];
        }
    }
}

//=========================================================== 
//  history 
//=========================================================== 

- (NSMutableArray *) history {
    NSMutableArray *result;
    synchronized {
        result = [history retain];
    }
    return [result autorelease];
}

- (void) setHistory:(NSMutableArray *)newHistory {
    synchronized {
        if (history != newHistory) {
            [history release];
            history = [newHistory retain];
        }
    }
}

//=========================================================== 
//  options 
//=========================================================== 

- (NSDictionary *) options {
    NSDictionary *result;
    synchronized {
        result = [options retain];
    }
    return [result autorelease];
}

- (void) setOptions:(NSDictionary *)newOptions {
    synchronized {
        if (options != newOptions) {
            [options release];
            options = [newOptions retain];
        }
    }
}

//=========================================================== 
//  lastResult 
//=========================================================== 

- (NSString *) lastResult {
    NSString *result;
    synchronized {
        result = [lastResult copy];
    }
    return [result autorelease];
}

- (void) setLastResult:(NSString *)newLastResult {
    synchronized {
        if (lastResult != newLastResult) {
            [lastResult release];
            lastResult = [newLastResult copy];
        }
    }
}

//=========================================================== 
//  rubyTask 
//=========================================================== 

- (NSTask *) rubyTask {
    NSTask *result;
    synchronized {
        result = [rubyTask retain];
    }
    return [result autorelease];
}

- (void) setRubyTask:(NSTask *)newRubyTask {
    synchronized {
        if (rubyTask != newRubyTask) {
            [rubyTask release];
            rubyTask = [newRubyTask retain];
        }
    }
}

//=========================================================== 
//  taskArgs 
//=========================================================== 

// - (NSArray *) taskArgs {
//     NSArray *result;
//     synchronized {
//         result = [taskArgs retain];
//     }
//     return [result autorelease];
// }
// - (void) setTaskArgs:(NSArray *)newTaskArgs {
//     synchronized {
//         if (taskArgs != newTaskArgs) {
//             [taskArgs release];
//             taskArgs = [newTaskArgs retain];
//         }
//     }
// }

//=========================================================== 
//  outPipe 
//=========================================================== 

- (NSPipe *) outPipe {
    NSPipe *result;
    synchronized {
        result = [outPipe retain];
    }
    return [result autorelease];
}

- (void) setOutPipe:(NSPipe *)newOutPipe {
    synchronized {
        if (outPipe != newOutPipe) {
            [outPipe release];
            outPipe = [newOutPipe retain];
        }
    }
}

//=========================================================== 
//  defaultScript 
//=========================================================== 

- (NSString *) defaultScript {
    //NSLog(@"in -defaultScript, returned defaultScript = %@", defaultScript);
    
    NSString *result;
    synchronized {
        result = [defaultScript copy];
    }
    return [result autorelease];
}

- (void) setDefaultScript: (NSString *) newDefaultScript {
    //NSLog(@"in -setDefaultScript:, old value of defaultScript: %@, changed to: %@", defaultScript, newDefaultScript);
    
    synchronized {
        if (defaultScript != newDefaultScript) {
            [defaultScript release];
            defaultScript = [newDefaultScript copy];
        }
    }
}

//=========================================================== 
//  defaultOptions 
//=========================================================== 

- (NSDictionary *) defaultOptions {
    //NSLog(@"in -defaultOptions, returned defaultOptions = %@", defaultOptions);
    
    NSDictionary *result;
    synchronized {
        result = [defaultOptions retain];
    }
    return [result autorelease];
}

- (void) setDefaultOptions: (NSDictionary *) newDefaultOptions {
    //NSLog(@"in -setDefaultOptions:, old value of defaultOptions: %@, changed to: %@", defaultOptions, newDefaultOptions);
    
    synchronized {
        if (defaultOptions != newDefaultOptions) {
            [defaultOptions release];
            defaultOptions = [newDefaultOptions retain];
        }
    }
}

//=========================================================== 
//  conditionLock 
//=========================================================== 

- (NSConditionLock *) conditionLock {
    //NSLog(@"in -conditionLock, returned conditionLock = %@", conditionLock);
    
    NSConditionLock *result;
    synchronized {
        result = [conditionLock retain];
    }
    return [result autorelease];
}

- (void) setConditionLock: (NSConditionLock *) newConditionLock {
    //NSLog(@"in -setConditionLock:, old value of conditionLock: %@, changed to: %@", conditionLock, newConditionLock);
    
    synchronized {
        if (conditionLock != newConditionLock) {
            [conditionLock release];
            conditionLock = [newConditionLock retain];
        }
    }
}

//=========================================================== 
//  bgThread 
//=========================================================== 

- (NSThread *) bgThread {
    //NSLog(@"in -bgThread, returned bgThread = %@", bgThread);
    
    NSThread *result;
    synchronized {
        result = [bgThread retain];
    }
    return [result autorelease];
}

- (void) setBgThread: (NSThread *) newBgThread {
    //NSLog(@"in -setBgThread:, old value of bgThread: %@, changed to: %@", bgThread, newBgThread);
    
    synchronized {
        if (bgThread != newBgThread) {
            [bgThread release];
            bgThread = [newBgThread retain];
        }
    }
}

#endif

- (void) dealloc {
    
    [script release], script = nil;
    [history release], history = nil;
    [options release], options = nil;
    [rubyTask release], rubyTask = nil;
//     [taskArgs release], taskArgs = nil;
    [lastResult release], lastResult = nil;
    [outPipe release], outPipe = nil;
    [defaultScript release], defaultScript = nil;
    [defaultOptions release], defaultOptions = nil;
    [conditionLock release], conditionLock = nil;
    [bgThread release], bgThread = nil;

    // script = nil;
    // history = nil;
    // rubyTask = nil;
    // taskArgs = nil;
    // lastResult = nil;
    // outPipe = nil;
    [super dealloc];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"%@,\n script: '%@',\n history (count %d): %@,\n lastResult: %@,\n options: %@", 
            [super description], [script quote], [history count], history, lastResult, [options descriptionInStringsFileFormat]];
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat:@"%@,\n task: %@,\n args: %@,\n outpipe: %@", 
            [self description], rubyTask, [options objectForKey:BMScriptOptionsTaskArgumentsKey], outPipe ];
}

// MARK: Initializer Methods

// init
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
        synchronized {
            self.defaultScript = [self defaultScriptSourceForLanguage];
        }
    } else {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                       reason:@"descendants of BMScript must implement -[defaultScriptSourceForLanguage]" 
                                     userInfo:nil];
    }
    if ([self respondsToSelector:@selector(defaultOptionsForLanguage)]) {
        synchronized {
            self.defaultOptions = [self defaultOptionsForLanguage];
        }
    } else {
        @throw [NSException exceptionWithName:BMScriptLanguageProtocolMethodMissingException 
                                       reason:@"descendants of BMScript must implement -[defaultOptionsForLanguage]" 
                                     userInfo:nil];
    }
    if (![super init]) {
        return nil;
    } else {
        synchronized {
            if (!scriptSource) {
                scriptSource = defaultScript;
            }
            if (scriptOptions) {
                self.options = scriptOptions;
            } else {                
                if (DEBUG) NSLog(@"defaultOptions: %@", [defaultOptions descriptionInStringsFileFormat]);
                self.options = defaultOptions;
            }
            self.script = scriptSource;
            self.history = [NSMutableArray array];
            self.lastResult = @"";
            self.conditionLock = [[NSConditionLock alloc] init];
            self.bgThread = [NSThread currentThread];
        }
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
        synchronized {
            isTemplate = NO;
            return [self initWithScriptSource:scriptSource options:scriptOptions];
        }
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
        synchronized {
            isTemplate = YES;
            scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
            scriptSource = [scriptSource stringByReplacingOccurrencesOfString:@"%%{}" withString:@"%%{%@}"];
            return [self initWithScriptSource:scriptSource options:scriptOptions];
        }
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

- (BOOL) setupTask {
    ap_start
    @try {
        NSTask * task = [[NSTask alloc] init];
        NSPipe * output = [[NSPipe alloc] init];
        NSArray * args = [[self options] objectForKey:BMScriptOptionsTaskArgumentsKey];
        args = [args arrayByAddingObject:script];
        NSString * path = [[self options] objectForKey:BMScriptOptionsTaskLaunchPathKey];
        
        [task setLaunchPath:path];
        [task setArguments:args];
        [task setStandardOutput:output];
        
        synchronized {    
            self.rubyTask = task;
//             self.taskArgs = args;
            self.outPipe = output;
        }
        if (DEBUG) NSLog(@"self debugDescription: %@", [self debugDescription]);
    }
    @catch (NSException * e) {
        NSLog(@"%@: Caught %@: %@", NSStringFromSelector(_cmd), [e name], [e  reason]);
        ap_end
        return NO;
    }
    ap_end
    return YES;
}

- (TerminationStatus) launchTaskAndStoreLastResult {
    TerminationStatus status = -1;
    ap_start
    NSTask * task = [[self rubyTask] retain];
    [task launch];
    NSData * data = [[[self outPipe] fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    status = [task terminationStatus];
    [task release];
    NSString * taskResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    synchronized { self.lastResult = taskResult; }
    [taskResult release], taskResult = nil;
    ap_end
    return status;
}

- (void) threadLoop {
    ap_start
    // TODO: read concurrent programming topics
    // TODO: implement
    ap_end
}

// MARK: Templates

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg {
    if (isTemplate) {
        synchronized {
            self.script = [NSString stringWithFormat:[self script], tArg];
            isTemplate = NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ... {
    
    if (isTemplate) {
        // determine how many replacements we need to make
        NSInteger numTokens = [script countOccurrencesOfString:REPLACEMENT_TOKEN];
        if (numTokens == NSNotFound) {
            return NO;
        }
        
        NSString * accumulator = script;
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
        
        synchronized {
            self.script = [accumulator stringByReplacingOccurrencesOfString:@"%%" withString:@"%"];
            isTemplate = NO;
        }
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
    if (isTemplate) {
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
    if (isTemplate) {
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
            return YES;
        }
    }
    return NO;
}

- (BOOL) executeAndReturnResult:(NSString **)result error:(NSError **)error {
    ap_start
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
        return success;
    }
    if ([self setupTask] == YES) {
        TerminationStatus status = [self launchTaskAndStoreLastResult];
        if (status == 0) {
            if (result) {
                synchronized {
                    *result = lastResult;
                }
            }
            synchronized {
                NSArray * historyItem = [NSArray arrayWithObjects:script, lastResult, nil];
                [history addObject:historyItem];
            }
            if (DEBUG_HISTORY) NSLog(@"Script '%@' executed successfully.\nAdded to history = %@", [[script quote] truncate], history);
            
            success = YES;
        } else {
            if (error) {
                NSDictionary * errorDict = 
                    [NSDictionary dictionaryWithObject:@"ruby script task returned non 0 exit status (indicating a possible error)" 
                                                forKey:NSLocalizedFailureReasonErrorKey];
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
            }
        }
    } else {
        if (error) {
            NSDictionary * errorDict = 
                [NSDictionary dictionaryWithObject:@"ruby script task setup failed" 
                                            forKey:NSLocalizedFailureReasonErrorKey];
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:errorDict];
        }
    }
    ap_end
    return success;
}


- (void) executeInBackgroundAndNotify {
    
    SEL callback = @selector(taskFinished);
    if ([self respondsToSelector:@selector(taskFinishedCallback)]) {
        callback = [self taskFinishedCallback];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:callback name:NSThreadWillExitNotification object:nil];
    
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    [self performSelectorInBackground:@selector(threadLoop) withObject:self];
#else
    [NSThread detachNewThreadSelector:@selector(threadLoop) toTarget:nil withObject:nil];
#endif
}

- (void) taskFinished {
    [[NSNotificationCenter defaultCenter] postNotificationName:BMScriptTaskDidEndNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:nil];
    [NSThread exit];
}


// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(NSInteger)index {
    if ([history count] > 0) {
        return [[history objectAtIndex:index] objectAtIndex:0];
    }
    return nil;
}

- (NSString *) resultFromHistoryAtIndex:(NSInteger)index {
    if ([history count] > 0) {
        return [[history objectAtIndex:index] objectAtIndex:1];
    }
    return nil;
}

- (NSString *) lastScriptSourceFromHistory {
    if ([history count] > 0) {
        return [[history lastObject] objectAtIndex:0];
    }
    return nil;
}

- (NSString *) lastResultFromHistory {
    if ([history count] > 0) {
        return [[history lastObject] objectAtIndex:1];
    }
    return nil;
}


// MARK: BMScriptLanguage

- (NSDictionary *) defaultOptionsForLanguage {
    return options;
}

- (NSString *) defaultScriptSourceForLanguage {
    return script;
}

// MARK: NSCopying

- (id)copyWithZone:(NSZone *)zone {
    BMScript * copy = [[[self class] allocWithZone:zone] initWithScriptSource:[self script] 
                                                                          options:[self options]];
    return copy;
}

// MARK: NSCoding

- (void) encodeWithCoder:(NSCoder *)coder { 
    [coder encodeObject:script];
    [coder encodeObject:history];
    [coder encodeObject:options];
    [coder encodeObject:lastResult];
    [coder encodeObject:rubyTask];
//     [coder encodeObject:taskArgs];
    [coder encodeObject:outPipe];
    [coder encodeObject:defaultScript];
    [coder encodeObject:defaultOptions];
    [coder encodeObject:conditionLock];
    [coder encodeObject:bgThread];
}


- (id) initWithCoder:(NSCoder *)coder { 
    if (self = [super init]) { 
        int version = [coder versionForClassName:NSStringFromClass([self class])]; 
        NSLog(@"class version = %i", version);
        script          = [[coder decodeObject] retain];
        history         = [[coder decodeObject] retain];
        options         = [[coder decodeObject] retain];
        lastResult      = [[coder decodeObject] retain];
        rubyTask        = [[coder decodeObject] retain];
//         taskArgs        = [[coder decodeObject] retain];
        outPipe         = [[coder decodeObject] retain];
        defaultScript   = [[coder decodeObject] retain];
        defaultOptions  = [[coder decodeObject] retain];
        conditionLock   = [[coder decodeObject] retain];
        bgThread        = [[coder decodeObject] retain];
    }
    return self;
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
