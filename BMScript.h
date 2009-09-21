//
//  BMScript.h
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <AvailabilityMacros.h>

#define BMSCRIPT_THREAD_SAFE 1
#define BMSCRIPT_REPLACEMENT_TOKEN @"%@"        /* used by templates to mark locations where a replacement should occurr */
#define NSSTRING_TRUNCATE_LENGTH 20    /* used by -truncate, defined in NSString (BMScriptUtilities) */

#define BMScriptSynthesizeOptions(_PATH_, ...) \
NSDictionary * defaultDict = [NSDictionary dictionaryWithObjectsAndKeys:\
(_PATH_), BMScriptOptionsTaskLaunchPathKey, [NSArray arrayWithObjects:__VA_ARGS__], BMScriptOptionsTaskArgumentsKey, nil]

// To simplify support for 64bit (and Leopard in general), 
// provide the type defines for non Leopard SDKs
#if !(MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)

    // NSInteger/NSUInteger and Max/Mins
    #ifndef NSINTEGER_DEFINED
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
        #define NSINTEGER_DEFINED 1
    #endif  // NSINTEGER_DEFINED

    // CGFloat
    #ifndef CGFLOAT_DEFINED
        #if defined(__LP64__) && __LP64__
            // This really is an untested path (64bit on Tiger?)
            typedef double CGFloat;
            #define CGFLOAT_MIN DBL_MIN
            #define CGFLOAT_MAX DBL_MAX
            #define CGFLOAT_IS_DOUBLE 1
        #else /* !defined(__LP64__) || !__LP64__ */
            typedef float CGFloat;
            #define CGFLOAT_MIN FLT_MIN
            #define CGFLOAT_MAX FLT_MAX
            #define CGFLOAT_IS_DOUBLE 0
        #endif /* !defined(__LP64__) || !__LP64__ */
        #define CGFLOAT_DEFINED 1
    #endif // CGFLOAT_DEFINED

    // NS_INLINE
    #if !defined(NS_INLINE)
        #if defined(__GNUC__)
            #define NS_INLINE static __inline__ __attribute__((always_inline))
        #elif defined(__MWERKS__) || defined(__cplusplus)
            #define NS_INLINE static inline
        #elif defined(_MSC_VER)
            #define NS_INLINE static __inline
        #elif defined(__WIN32__)
            #define NS_INLINE static __inline__
        #endif
    #endif

#endif  // MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

NS_INLINE NSString * BMStringFromBOOL(BOOL b) { return (b ? @"YES" : @"NO"); }

typedef NSInteger TerminationStatus;

enum {
    BMScriptNotExecutedTerminationStatus = -1,
    BMScriptFinishedSuccessfullyTerminationStatus = 0,
    BMScriptTaskFailedTerminationStatus
    /* all else indicates erroneous termination status as returned by the task */
};

OBJC_EXPORT NSString * const BMScriptTaskDidEndNotification;
OBJC_EXPORT NSString * const BMScriptNotificationInfoTaskResultsKey;
OBJC_EXPORT NSString * const BMScriptNotificationInfoTaskTerminationStatusKey;

OBJC_EXPORT NSString * const BMScriptOptionsTaskLaunchPathKey;
OBJC_EXPORT NSString * const BMScriptOptionsTaskArgumentsKey;
OBJC_EXPORT NSString * const BMScriptOptionsVersionKey; /* currently unused */

OBJC_EXPORT NSString * const BMScriptTemplateArgumentMissingException;
OBJC_EXPORT NSString * const BMScriptTemplateArgumentsMissingException;

OBJC_EXPORT NSString * const BMScriptLanguageProtocolDoesNotConformException;
OBJC_EXPORT NSString * const BMScriptLanguageProtocolMethodMissingException;
OBJC_EXPORT NSString * const BMScriptLanguageProtocolIllegalAccessException;


/* the ScriptLanguage protocol must be implemented by language-specific subclasses 
   in order to provide sensible defaults for language-specific values. */
@protocol BMScriptLanguageProtocol
- (NSDictionary *) defaultOptionsForLanguage;
@optional
- (NSString *) defaultScriptSourceForLanguage;  /* implement this to supply a default script for [[self alloc] init].
                                                   if unimplemented, an empty script will be set as initial value for self.defaultScript */
@end

@interface BMScript : NSObject <NSCopying, NSCoding, BMScriptLanguageProtocol> {
    NSString * script;
    NSString * lastResult;
@protected
    id __weak delegate;
    NSDictionary * options;
    NSMutableArray * history;
    NSTask * task;
    NSPipe * pipe;
@private
    NSString * defaultScript;
    NSDictionary * defaultOptions;
    NSTask * bgTask;
    NSPipe * bgPipe;
    NSString * partialResult;
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

// MARK: History

- (NSString *) scriptSourceFromHistoryAtIndex:(int)index;
- (NSString *) resultFromHistoryAtIndex:(int)index;
- (NSString *) lastScriptSourceFromHistory;
- (NSString *) lastResultFromHistory;

// MARK: Accessors

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
 * @method lastResult
 * @abstract lastResult is set after the internal task finished executing and contains the result of the execution (i.e. whatever was returned by the shell, even error messages generated by the shell)
 * @result returns value for lastResult
 */
- (NSString *)lastResult;
- (void)setLastResult:(NSString *)newLastResult;

// MARK: Protected Accessors

- (NSMutableArray *)history;
- (void)setHistory:(NSMutableArray *)newHistory;
- (NSDictionary *)options;
- (void)setOptions:(NSDictionary *)newOptions;
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

// MARK: Delegate Methods

- (BOOL) shouldAddItemToHistory:(id)anItem;
- (BOOL) shouldReturnItemFromHistory:(id)anItem;
- (BOOL) shouldSetLastResult:(NSString *)aString;
- (BOOL) shouldAppendPartialResult:(NSString *)string;
- (BOOL) shouldSetScript:(NSString *)aScript;
- (BOOL) shouldSetOptions:(NSDictionary *)opts;

@end

@interface BMScript (CommonScriptLanguagesFactories)
+ (id) rubyScriptWithSource:(NSString *)scriptSource;
+ (id) rubyScriptWithContentsOfFile:(NSString *)path;
+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) pythonScriptWithSource:(NSString *)scriptSource;
+ (id) pythonScriptWithContentsOfFile:(NSString *)path;
+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) perlScriptWithSource:(NSString *)scriptSource;
+ (id) perlScriptWithContentsOfFile:(NSString *)path;
+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path;
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

@interface NSDictionary (BMScriptUtilities)
- (NSDictionary *) dictionaryByAddingObject:(id)object forKey:(id)key;
@end
