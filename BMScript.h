//
//  BMScript.h
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <AvailabilityMacros.h>

#define BMS_THREAD_SAFE 1  /* if 1 will wrap locations where shared variables are mutated with @synchronized(self)
                               Important! This does not guarantee thread safety!
                               The only way to ensure thread safety is by testing within YOUR app */

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif
#define NSIntegerMax    LONG_MAX
#define NSIntegerMin    LONG_MIN
#define NSUIntegerMax   ULONG_MAX
#endif

typedef NSInteger TerminationStatus;

OBJC_EXPORT NSString * const BMScriptTaskDidEndNotification;

OBJC_EXPORT NSString * const BMScriptOptionsTaskLaunchPathKey;
OBJC_EXPORT NSString * const BMScriptOptionsTaskArgumentsKey;
OBJC_EXPORT NSString * const BMScriptOptionsVersionKey; /* currently unused */

OBJC_EXPORT NSString * const BMScriptTemplateArgumentMissingException;
OBJC_EXPORT NSString * const BMScriptTemplateArgumentsMissingException;

OBJC_EXPORT NSString * const BMScriptLanguageProtocolDoesNotConformException;
OBJC_EXPORT NSString * const BMScriptLanguageProtocolMethodMissingException;


/* the ScriptLanguage protocol must be implemented by language-specific subclasses 
   in order to provide sensible defaults for language-specific values. */
@protocol BMScriptLanguageProtocol
- (NSString *) defaultScriptSourceForLanguage;
- (NSDictionary *) defaultOptionsForLanguage;
@optional
- (SEL) taskFinishedCallback; /* must be implemented in order to use -[executeInBackgroundAndNotify].
                                 should return a selector (SEL) which should be called once 
                                 NSTaskWillExitNotification is about to arrive. 
 
                                 IMPORTANT: if you use -[executeInBackgroundAndNotify] and this method 
                                 is not implemented an exception of type BMScriptLanguageProtocolMethodMissingException 
                                 will be raised. */
@end

@interface BMScript : NSObject <NSCopying, NSCoding, BMScriptLanguageProtocol> {
    NSString * script;
    NSMutableArray * history;
    NSDictionary * options;
    NSString * lastResult;
@protected
    NSTask * rubyTask;
//     NSArray * taskArgs;
    NSPipe * outPipe;
@private
    NSString * defaultScript;
    NSDictionary * defaultOptions;
    NSConditionLock * conditionLock;
    NSThread * bgThread;
}

// MARK: Initializer Methods

- (id) initWithScriptSource:(NSString *)scriptSource;
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;     /* designated initializer */
- (id) initWithContentsOfFile:(NSString *)path;
- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
- (id) initWithContentsOfTemplateFile:(NSString *)path;
- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;

// MARK: Factory Methods

+ (id) scriptWithSource:(NSString *)scriptSource;
+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;
+ (id) scriptWithContentsOfFile:(NSString *)path;
+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
// + (id) scriptWithContentsOfURL:(NSURL *)url;
// + (id) scriptWithContentsOfURL:(NSURL *)url options:(NSDictionary *)scriptOptions;
+ (id) scriptWithContentsOfTemplateFile:(NSString *)path;
+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;

// MARK: Templates

- (BOOL) saturateTemplateWithArgument:(NSString *)tArg;
- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ...;
- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary;

// MARK: Execution

- (BOOL) execute;
- (BOOL) executeAndReturnResult:(NSString **)result;
- (BOOL) executeAndReturnError:(NSError **)error;
- (BOOL) executeAndReturnResult:(NSString **)result error:(NSError **)error;
- (void) executeInBackgroundAndNotify AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER; 
- (void) taskFinished;


// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(int)index;
- (NSString *) resultFromHistoryAtIndex:(int)index;
- (NSString *) lastScriptSourceFromHistory;
- (NSString *) lastResultFromHistory;


#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
#define BMRS_ACCESSORS @"synthesized properties"

// MARK: Properties (10.5+)
#if BMS_THREAD_SAFE
@property (copy)    NSString * script;
@property (retain)  NSMutableArray * history;
@property (retain)  NSDictionary * options;
@property (retain)  NSTask * rubyTask;
// @property (retain)  NSArray * taskArgs;
@property (copy)    NSString * lastResult;
@property (retain)  NSPipe * outPipe;
@property (copy)    NSString * defaultScript;
@property (retain)  NSDictionary * defaultOptions;
@property (retain)  NSConditionLock * conditionLock;
@property (retain)  NSThread * bgThread;
#else
@property (nonatomic, copy)    NSString * script;
@property (nonatomic, retain)  NSMutableArray * history;
@property (nonatomic, retain)  NSDictionary * options;
@property (nonatomic, retain)  NSTask * rubyTask;
// @property (nonatomic, retain)  NSArray * taskArgs;
@property (nonatomic, copy)    NSString * lastResult;
@property (nonatomic, retain)  NSPipe * outPipe;
@property (nonatomic, copy)    NSString * defaultScript;
@property (nonatomic, retain)  NSDictionary * defaultOptions;
@property (nonatomic, retain)  NSConditionLock * conditionLock;
@property (nonatomic, retain)  NSThread * bgThread;
#endif

#else
#define BMRS_ACCESSORS @"conventional accessors"

// MARK: Accessors (10.4)

/*!
 * @method script
 * @abstract the getter corresponding to setScript:
 * @result returns value for script
 */
- (NSString *)script;
/*!
 * @method setScript
 * @abstract sets script to the param
 * @discussion 
 * @param newScript 
 */
- (void)setScript:(NSString *)newScript;

/*!
 * @method history
 * @abstract the getter corresponding to setHistory:
 * @result returns value for history
 */
- (NSMutableArray *)history;
/*!
 * @method setHistory
 * @abstract sets history to the param
 * @discussion 
 * @param newHistory 
 */
- (void)setHistory:(NSMutableArray *)newHistory;

/*!
 * @method options
 * @abstract the getter corresponding to setOptions:
 * @result returns value for options
 */
- (NSDictionary *)options;
/*!
 * @method setOptions
 * @abstract sets options to the param
 * @discussion 
 * @param newOptions 
 */
- (void)setOptions:(NSDictionary *)newOptions;

/*!
 * @method lastResult
 * @abstract lastResult is set after the internal task finished executing and contains the result of the execution (i.e. whatever was returned by the shell, even error messages generated by the shell)
 * @result returns value for lastResult
 */
- (NSString *)lastResult;
/*!
 * @method setLastResult
 * @abstract sets lastResult to the param
 * @discussion 
 * @param newLastResult 
 */
- (void)setLastResult:(NSString *)newLastResult;

/*!
 * @method rubyTask
 * @abstract the getter corresponding to setRubyTask:
 * @result returns value for rubyTask
 */
- (NSTask *)rubyTask;
/*!
 * @method setRubyTask
 * @abstract sets rubyTask to the param
 * @discussion 
 * @param newRubyTask 
 */
- (void)setRubyTask:(NSTask *)newRubyTask;

// /*!
//  * @method taskArgs
//  * @abstract the getter corresponding to setTaskArgs:
//  * @result returns value for taskArgs
//  */
// - (NSArray *)taskArgs;
// /*!
//  * @method setTaskArgs
//  * @abstract sets taskArgs to the param
//  * @discussion 
//  * @param newTaskArgs 
//  */
// - (void)setTaskArgs:(NSArray *)newTaskArgs;


/*!
 * @method outPipe
 * @abstract the getter corresponding to setOutPipe:
 * @result returns value for outPipe
 */
- (NSPipe *)outPipe;
/*!
 * @method setOutPipe
 * @abstract sets outPipe to the param
 * @discussion 
 * @param newOutPipe 
 */
- (void)setOutPipe:(NSPipe *)newOutPipe;

/*!
 * @method defaultScript
 * @abstract the getter corresponding to setDefaultScript:
 * @result returns value for defaultScript
 */
- (NSString *) defaultScript;

/*!
 * @method setDefaultScript
 * @abstract sets defaultScript to the param
 * @discussion 
 * @param newDefaultScript 
 */
- (void) setDefaultScript: (NSString *) newDefaultScript;


/*!
 * @method defaultOptions
 * @abstract the getter corresponding to setDefaultOptions:
 * @result returns value for defaultOptions
 */
- (NSDictionary *) defaultOptions;
/*!
 * @method setDefaultOptions
 * @abstract sets defaultOptions to the param
 * @discussion 
 * @param newDefaultOptions 
 */
- (void) setDefaultOptions: (NSDictionary *) newDefaultOptions;


/*!
 * @method conditionLock
 * @abstract the getter corresponding to setConditionLock:
 * @result returns value for conditionLock
 */
- (NSConditionLock *) conditionLock;
/*!
 * @method setConditionLock
 * @abstract sets conditionLock to the param
 * @discussion 
 * @param newConditionLock 
 */
- (void) setConditionLock: (NSConditionLock *) newConditionLock;


/*!
 * @method bgThread
 * @abstract the getter corresponding to setBgThread:
 * @result returns value for bgThread
 */
- (NSThread *) bgThread;
/*!
 * @method setBgThread
 * @abstract sets bgThread to the param
 * @discussion 
 * @param newBgThread 
 */
- (void) setBgThread: (NSThread *) newBgThread;

#endif

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
@interface NSString (BMScriptNSString10_4Compatibility)
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)options range:(NSRange)searchRange; DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement; DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER
@end
#endif

@interface NSString (BMScriptStringUtilities)
- (NSString *) quote;
- (NSString *) truncate;
- (NSString *) truncateToLength:(NSInteger)len;
- (NSInteger) countOccurrencesOfString:(NSString *)aString;
@end
