//
//  BMScript.h
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  For license details see end of this file.
//  Short version: licensed under the MIT license.
//

/**
 * @mainpage BMScript: Harness The Power Of Shell Scripts
 * 
 * BMScript is an Objective-C class set to make it easier to utilize the
 * power and flexibility of a whole range of scripting languages that already
 * come with modern Macs. BMScript does not favor any particular scripting
 * language or UNIX™ command line tool for that matter, instead it was written
 * as an abstraction layer to NSTask, and as such supports any command line tool, 
 * provided that it is available on the target system.
 *
 * You can use BMScript as a sort of abstract superclass and customize its 
 * behaviour by making a subclass which knows about the details for the 
 * particular tool that you want to utilize. Your subclass must implement the 
 * BMScriptLanguageProtocol which only has a required and one optional method:
 *
 * @include bmScriptLanguageProtocol.m
 *
 * The first method should return sensible default values specific to the command line tool.
 * The second method should provide a default script source containing commands to execute
 * by the command line tool. As it is, currently, optional, if absent the default source will
 * be set to an empty string.
 *
 * The BMScript.defaultOptionsForLanguage method takes a dictionary which looks like this:
 *
 * @include bmScriptOptionsDictionary.m
 * 
 * There's two constant keys. These are the only keys you need to define values for.
 * Task arguments or flags are passed as NSStrings in an NSArray. It is important to note 
 * that the script source string should <b>NOT</b> be supplied in the array for the
 * #BMScriptOptionsTaskArgumentsKey, as it will be added by the class later after performing
 * a series of tests and replacements.
 * 
 * A macro function called BMSynthesizeOptions(path, args) is available to ease the declaration of the options. 
 * It is declared as:
 *
 * @include bmScriptSynthesizeOptions.m
 *
 * @note Don't forget the <b>nil</b> at the end even if you don't need to supply any task arguments.
 * 
 * The other, equally easy way to use BMScript is of course by using it directly:
 *
 * @include bmScriptCreationMethods.m
 *
 * If you do not use the designated initializer and supply the options yourself, the
 * BMScript.defaultOptionsForLanguage method of either your subclass or of BMScript will be called.
 * There are also convenience methods for the most common scripting languages, which have
 * their options set to OS default values:
 *
 * @include bmScriptConvenienceMethods.m
 *
 * As you can see loading scripts from source files is also supported, including a small
 * and lightweight template system. Using templates can be a good way to add domain-specific
 * problem solving to a subclass. To utilize the template system, three steps are required:
 *
 *   -# Initialize a BMScript instance with a template 
 *   -# Saturate template with values ("fill in the blanks")
 *   -# Execute BMScript instance 
 * 
 * Here are the methods you use to saturate a BMScript template with values:
 *
 * @include bmScriptSaturateTemplate.m
 *
 * So how does a template look like then? We use standard text files which have special
 * token strings bound to get replaced. If you are familiar with Ruby, the magic template token
 * looks a lot like Ruby's double quoted string literal: 
 * 
 * @verbatim %{} @endverbatim 
 * 
 * If it is empty it will be replaced in the order of occurrence. The first two saturate methods are good for this. 
 * If the magic token wraps other values, a more flexible dictionary based system can be used
 * with the third saturate method. There, the magic token must wrap names of keys defined in the
 * dictionary which will dictiate what the replacement value will be. Here is an example of a
 * Ruby script template, which converts octal or hexadecimal values to their decimal representation:
 *
 * @include convertToDecimalTemplate.rb
 * 
 * After you have obtained and configured a BMScript instance, you need to tell it to execute.
 * This can be done by telling it to excute synchroneously (blocking), or asynchroneously (non-blocking):
 *
 * @include bmScriptExecution.m
 *
 * Using the blocking execution model you can either pass a pointer to NSString where the result will be
 * written to (including NSError if needed), or just use plain BMScript.execute. The non-blocking execution 
 * model works by means of <a href="http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CocoaFundamentals/CommunicatingWithObjects/CommunicateWithObjects.html#//apple_ref/doc/uid/TP40002974-CH7-SW7" class="external">notifications</a>. 
 * You register your class as observer with the default notification center for
 * the notification called #BMScriptTaskDidEndNotification passing a selector to execute once the notification
 * arrives. Then you tell the BMScript instance to BMScript.executeInBackgroundAndNotify. When your selector is called
 * it will be passed an NSNotification object which encapsulates the NSTask used to run the script. To make that
 * clearer here's an example with the relevant parts thrown together:
 *
 * @include bmScriptNotificationExample.m
 *
 * It is important to note at this point that the blocking and non-blocking tasks are tracked by seperate instance variables.
 * This was done to minimize the risk of race conditions when BMScript would be used in a multi-threaded environment. 
 *
 * @par On The Topic Of Concurrency
 * 
 * All access to global data, shared variables and mutable objects has been 
 * locked with <a href="x-man-page://pthread" class="external">pthread_mutex_locks</a>. This is done by a macro wrapper which will avaluate to nothing if 
 * #BMSCRIPT_THREAD_SAFE is not 1. Note that there haven't been enough tests yet to say that BMScript is
 * thread-safe. It is likely to be thread-safe enough, but if that will be enough for your own application will 
 * unfortunately have to be tested by you. 
 *
 * @par Delegate Methods
 * 
 * BMScript also features delegate methods your subclass or another class posing as delegate can implement:
 * 
 * @include bmScriptDelegateMethods.m
 *
 * And last but not least, BMScript features an execution cache, called its history. This works like the Shell history
 * in that it will keep script sources as well as the results of the execution of those sources.
 * To access the history you may use the following methods:
 *
 * @include bmScriptHistory.m
 *
 */

/** 
 * @file BMScript.h
 * Documentation and class interface of BMScript.
 *
 * @defgroup functions Functions and Global Variables
 * @defgroup constants Constants
 * @defgroup delegate Delegate Methods
 */

#import <Cocoa/Cocoa.h>
#include <AvailabilityMacros.h>

#ifndef BMSCRIPT_THREAD_SAFE
    /** 
     * @def BMSCRIPT_THREAD_SAFE
     * Toggles synchronization locks. 
     * Set this to 1 to wrap globals, shared data and immutable objects with locks. 
     * The locks are implemented by a macro utilizing pthread_mutex_lock/unlock directly.
     */
    #define BMSCRIPT_THREAD_SAFE 1
    #ifndef BMSCRIPT_FAST_LOCK
        /** 
         * @def BMSCRIPT_FAST_LOCK
         * Toggles usage of pthread_mutex_lock() <-> synchronized(self).
         * Set this to 1 to use the pthread library directly for locks.
         */
        #define BMSCRIPT_FAST_LOCK 1
    #endif
#endif



/**
 * @def BMSynthesizeOptions(path, ...)
 * Used to synthesize a valid options dictionary. 
 * You can use this convenience macro to generate the boilerplate code for the 
 * BMScriptOptionsTaskLaunchPathKey and BMScriptOptionsTaskArgumentsKey keys.
 */
#define BMSynthesizeOptions(path, ...) \
[NSDictionary dictionaryWithObjectsAndKeys:(path),\
BMScriptOptionsTaskLaunchPathKey, [NSArray arrayWithObjects:__VA_ARGS__], BMScriptOptionsTaskArgumentsKey, nil]


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

/** A macro function which combines testing for a probe is enabled and actually calling this probe. */
#define BM_PROBE(name, ...) if (BMSCRIPT_ ## name ## _ENABLED()) BMSCRIPT_ ## name(__VA_ARGS__)

/** Provides a clearer indication of the task's termination status than simple integers.￼￼ */
typedef NSInteger TerminationStatus;

enum {
    /** task not executed yet */
    BMScriptNotExecutedTerminationStatus = -1,
    /** task finished successfully */
    BMScriptFinishedSuccessfullyTerminationStatus = 0,
    /** task failed */
    BMScriptFailedTerminationStatus
    /* all else indicates erroneous termination status as returned by the task */
};

/**
 * @ingroup functions
 * @{
 */

/**
 * Creates an NSString from a BOOL.
 * @param b the boolean to convert
 */
NS_INLINE NSString * BMStringFromBOOL(BOOL b) { return (b ? @"YES" : @"NO"); }
/**
 * Creates an NSString from a TerminationStatus.
 * @param status the TerminationStatus to convert
 */
NS_INLINE NSString * BMStringFromTerminationStatus(TerminationStatus status) {
    switch (status) {
        case BMScriptNotExecutedTerminationStatus:
            return @"task not executed";
            break;
        case BMScriptFinishedSuccessfullyTerminationStatus:
            return @"task finished successfully";
            break;
        default:
            return @"task failed";
            break;
    }
}

/** @} */

/**
 * @ingroup constants
 * @{
 */

/** Notficiation sent when the background task has ended */
OBJC_EXPORT NSString * const BMScriptTaskDidEndNotification;
/** Key incorporated by the notification's userInfo dictionary. Contains the result string of the finished task */
OBJC_EXPORT NSString * const BMScriptNotificationInfoTaskResultsKey;
/** Key incorporated by the notification's userInfo dictionary. Contains the termination status of the finished task */
OBJC_EXPORT NSString * const BMScriptNotificationInfoTaskTerminationStatusKey;

/** Key incorporated by the options dictionary. Contains the launch path string for the task */
OBJC_EXPORT NSString * const BMScriptOptionsTaskLaunchPathKey;
/** Key incorporated by the options dictionary. Contains the arguments array for the task */
OBJC_EXPORT NSString * const BMScriptOptionsTaskArgumentsKey;
/** currently unused */
OBJC_EXPORT NSString * const BMScriptOptionsVersionKey; /* currently unused */

/** 
 * Thrown when the template is not saturated with an argument. 
 *
 * Call BMScript.saturateTemplateWithArgument: before calling BMScript.execute or one of its variants 
 */
OBJC_EXPORT NSString * const BMScriptTemplateArgumentMissingException;
/** 
 * Thrown when the template is not saturated with arguments. 
 *
 * Call BMScript.saturateTemplateWithArguments: before calling BMScript.execute or one of its variants 
 */
OBJC_EXPORT NSString * const BMScriptTemplateArgumentsMissingException;

/**
 * Thrown when a subclass promises to conform to the BMScriptLanguageProtocol 
 * but consequently fails to declare the proper header. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolDoesNotConformException;
/** 
 * Thrown when a subclass promises to conform to the BMScriptLanguageProtocol 
 * but consequently fails to implement all required methods. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolMethodMissingException;
/** 
 * Thrown when a subclass promises accesses implemention details in an improper way. 
 * Currently unused. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolIllegalAccessException;

/** @} */

/** 
 * @protocol BMScriptLanguageProtocol
 * Must be implemented by subclasses to provide sensible defaults for language or tool specific values.
 */
@protocol BMScriptLanguageProtocol
/**
 * Returns the options dictionary. This is required.
 * @see BMSynthesizeOptions and @link bmScriptOptionsDictionary.m @endlink
 */
- (NSDictionary *) defaultOptionsForLanguage;
@optional
/**
 * Returns the default script source. This is optional and will be set to an empty string if absent.
 * BMScript's implementation just returns some info text on how to subclass or utilize BMScript. You 
 * might want to implement this if you plan on using plain alloc/init with your subclass a lot since 
 * alloc/init will pull this in as default script if no script source was supplied to the designated 
 * initalizer.
 */
- (NSString *) defaultScriptSourceForLanguage; 

@end

/**
 * A decorator class to NSTask in connection with a protocol for providing an easily reusable driver
 * to various command line tools and interfaces.
 */
@interface BMScript : NSObject <NSCopying, NSCoding> {
@public
    NSString * script;
    NSDictionary * options;
@protected
    id delegate;
@private
    NSString * lastResult;
    BOOL isTemplate;
    NSMutableArray * history;
    NSTask * task;
    NSPipe * pipe;
    NSTask * bgTask;
    NSPipe * bgPipe;
}

// MARK: Initializer Methods

/**
 * Initialize a new BMScript instance. If no options are specified calls 
 * the subclass' or BMScript's  implementation of defaultOptionsForLanguage.
 * @param scriptSource a string containing commands to execute
 */
- (id) initWithScriptSource:(NSString *)scriptSource;
/**
 * Initialize a new BMScript instance. The designated initializer.
 * @param scriptSource a string containing commands to execute
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;     /* designated initializer */
/**
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a file on disk. The contents of this file will be used as source script.
 */
- (id) initWithContentsOfFile:(NSString *)path;
/**
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a file on disk. The contents of this file will be used as source script.
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
/**
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a <i>template</i> file on disk. 
 * The contents of this file will be used as template which must be <b>saturated</b> before calling BMScript.execute or one of its variants.
 * @see #saturateTemplateWithArgument: et al.
 */
- (id) initWithContentsOfTemplateFile:(NSString *)path;
/**
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a <i>template</i> file on disk. 
 * The contents of this file will be used as template which must be <b>saturated</b> before calling BMScript.execute or one of its variants.
 * @param scriptOptions a dictionary containing the task options
 * @see #saturateTemplateWithArgument: et al.
 */
- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;

// MARK: Factory Methods

/**
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithSource:(NSString *)scriptSource;
/**
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;
/**
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfFile:(NSString *)path;
/**
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
/**
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfTemplateFile:(NSString *)path;
/**
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;

// MARK: Templates

/**
 * Replaces a single %{} construct in the template.
 * @param tArg the value that should be inserted
 * @return YES if the replacement was successful, NO on error
 */
- (BOOL) saturateTemplateWithArgument:(NSString *)tArg;
/**
 * Replaces multiple %{} constructs in the template.
 * @param firstArg the first value which should be inserted
 * @param ... the remaining values to be inserted in order of occurrence
 * @return YES if the replacements were successful, NO on error
 */
- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ...;
/**
 * Replaces multiple %{<i>KEY</i>} constructs in the template. 
 * The <i>KEY</i> phrase is a variant and describes the name of a key in the dictionary passed to this method.
 * If the key is found in the dictionary its corresponding value will be used to replace the magic token in the template.
 * @param dictionary a dictionary with keys and their values which should be inserted
 * @return YES if the replacements were successful, NO on error
 */
- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary;

// MARK: Execution

/**
 * Executes the script with a synchroneous (blocking) task. You get the result with BMScript.lastResult.
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) execute;
/**
 * Executes the script with a synchroneous (blocking) task and stores the result in &result.
 * @param result a pointer to an NSString where the result should be written to
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) executeAndReturnResult:(NSString **)result;
/**
 * Executes the script with a synchroneous (blocking) task. To get the result call BMScript.lastResult.
 * @param error a pointer to an NSError where any errors should be written to
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) executeAndReturnError:(NSError **)error;
/**
 * Executes the script with a synchroneous (blocking) task. To get the result call BMScript.lastResult.
 * @param result a pointer to an NSString where the result should be written to
 * @param error a pointer to an NSError where errors should be written to
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) executeAndReturnResult:(NSString **)result error:(NSError **)error;
/**
 * Executes the script with a asynchroneous (non-blocking) task. The result will be posted with the help of a notifcation item.
 * @see @link bmScriptNotificationExample.m @endlink
 */
- (void) executeInBackgroundAndNotify; 

// MARK: History

/**
 * Returns a cached script source from the history. 
 * @param index index of the item to return. May return nil if the history does not contain any objects.
 */
- (NSString *) scriptSourceFromHistoryAtIndex:(int)index;
/**
 * Returns a cached result from the history. 
 * @param index index of the item to return. May return nil if the history does not contain any objects.
 */
- (NSString *) resultFromHistoryAtIndex:(int)index;
/**
 * Returns the last cached script source from the history. 
 * May return nil if the history does not contain any objects.
 */
- (NSString *) lastScriptSourceFromHistory;
/**
 * Returns the last cached result from the history. 
 * May return nil if the history does not contain any objects.
 */
- (NSString *) lastResultFromHistory;

// MARK: Equality

/**
 * Returns YES if the source script is equal.
 */
- (BOOL) isEqual:(BMScript *)other;
/**
 * Returns YES if the source script and launch path are equal.
 */
- (BOOL) isEqualToScript:(BMScript *)other;

// MARK: Accessors

/**
 * Returns the script instance variable. Uses copy/autorelease.
 */
- (NSString *)script;
/**
 * Sets the script instance variable. Uses release/copy.
 * @param newScript new value for script.
 */
- (void)setScript:(NSString *)newScript;
/**
 * Returns the options instance variable. Uses retain/autorelease.
 */
- (NSDictionary *)options;
/**
 * Sets the options instance variable. Uses release/retain.
 * @param newOptions new value for options.
 */
- (void)setOptions:(NSDictionary *)newOptions;
/**
 * Returns the lastResult instance variable. Uses copy/autorelease.
 */
- (NSString *)lastResult;
/**
 * Returns the history instance variable. Uses retain/autorelease.
 * Wraps access with a pthread_mutex_lock if BMSCRIPT_THREAD_SAFE is 1.
 */
- (NSMutableArray *)history;

// MARK: Protected Accessors

/**
 * Returns the script instance variable. Uses simple assignment.
 */
- (id)delegate;
/**
 * Sets the delegate instance variable. Uses simple assignment.
 * Wraps access with a pthread_mutex_lock if BMSCRIPT_THREAD_SAFE is 1.
 * @param newDelegate new value for delegate.
 */
- (void)setDelegate:(id)newDelegate;

// MARK: Delegate Methods

/**
 * @ingroup delegate
 * @{
 */
/** 
 * Called in the setter if implemented. Delegate methods beginning with <i>should</i> 
 * give the delegate the power to abort an operation by returning NO. 
 *
 * @param anItem the item that will be set as new value in setter if this method returns YES.
 */
- (BOOL) shouldAddItemToHistory:(id)anItem;
/** 
 * Called in the getter if implemented. Delegate methods beginning with <i>should</i> 
 * give the delegate the power to abort an operation by returning NO. 
 *
 * @param anItem the item that will be returned from getter if this method returns YES.
 */
- (BOOL) shouldReturnItemFromHistory:(id)anItem;
/** 
 * Called in the setter if implemented. Delegate methods beginning with <i>should</i> 
 * give the delegate the power to abort an operation by returning NO.
 *
 * @param aString the string that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetLastResult:(NSString *)aString;
/** 
 * Called multiple times during async execution in background whenever there is new data available if implemented. 
 * @note This delegate is not called during initialization of a new instance. 
 * It is only triggered when calling the BMScript.setScript: accessor method.
 *
 * @param string the string that will be used as new value if this method returns YES.
 */
- (BOOL) shouldAppendPartialResult:(NSString *)string;
/** 
 * Called in the setter if implemented. Delegate methods beginning with <i>should</i> 
 * give the delegate the power to abort an operation by returning NO.
 * @param aScript the script that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetScript:(NSString *)aScript;
/** 
 * Called in the setter if implemented. Delegate methods beginning with <i>should</i> 
 * give the delegate the power to abort an operation by returning NO.
 * @param opts the dictionary that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetOptions:(NSDictionary *)opts;
/** @} */

@end

/** 
 * A category on BMScript adding some default factory methods for convenience.
 * The task options use default paths (for 10.5 and 10.6) for the task launch path.
 */
@interface BMScript(CommonScriptLanguagesFactories)
/** 
 * Returns an autoreleased Ruby script ready for execution.
 *
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) rubyScriptWithSource:(NSString *)scriptSource;
/** 
 * Returns an autoreleased Ruby script from a file ready for execution.
 *
 * @param path path to a file containing the commands to execute.
 */
+ (id) rubyScriptWithContentsOfFile:(NSString *)path;
/** 
 * Returns an autoreleased Ruby script template ready for saturation.
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path;
/** 
 * Returns an autoreleased Python script ready for execution.
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) pythonScriptWithSource:(NSString *)scriptSource;
/** 
 * Returns an autoreleased Python script from a file ready for execution.
 * @param path path to a file containing the commands to execute.
 */
+ (id) pythonScriptWithContentsOfFile:(NSString *)path;
/** 
 * Returns an autoreleased Python script template ready for saturation.
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path;
/** 
 * Returns an autoreleased Perl script ready for execution.
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) perlScriptWithSource:(NSString *)scriptSource;
/** 
 * Returns an autoreleased Perl script from a file ready for execution.
 * @param path path to a file containing the commands to execute.
 */
+ (id) perlScriptWithContentsOfFile:(NSString *)path;
/** 
 * Returns an autoreleased Perl script template ready for saturation.
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path;
@end

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
/** A category on NSString providing compatibility for missing methods on 10.4 (Tiger). */
@interface NSString (BMScriptNSString10_4Compatibility)
/** 
 * An implementation of the 10.5 (Leopard) method of NSString. 
 * Replaces all occurrences of a string with another string with the ability to define the search range and other comparison options.
 * @param target the string to replace
 * @param replacement the string to replace target with
 * @param options on 10.5 this parameter is of type NSStringCompareOptions an untagged enum. On 10.4 you can use the following options:
 *  - 1  (NSCaseInsensitiveSearch)
 *  - 2  (NSLiteralSearch: Exact character-by-character equivalence)
 *  - 4  (NSBackwardsSearch: Search from end of source string)
 *  - 8  (NSAnchoredSearch: Search is limited to start (or end, if NSBackwardsSearch) of source string)
 *  - 64 (NSNumericSearch: Numbers within strings are compared using numeric value, that is, Foo2.txt < Foo7.txt < Foo25.txt)
 * @param searchRange an NSRange defining the location and length the search should be limited to
 * @deprecated Deprecated in 10.5 (Leopard) in favor of NSString's own implementation.
 */
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)options range:(NSRange)searchRange; DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER
/** 
 * An implementation of the 10.5 (Leopard) method of NSString. Replaces all occurrences of a string with another string. 
 * Calls stringByReplacingOccurrencesOfString:withString:options:range: with default options 0 and searchRange the full length of the searched string.
 * @deprecated Deprecated in 10.5 (Leopard) in favor of NSString's own implementation.
 */
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement; DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER
@end
#endif

/** 
 * A category on NSString providing some handy utility functions
 * for end user display of strings. 
 */
@interface NSString (BMScriptStringUtilities)
/** Replaces all occurrences of newlines, carriage returns, double quotes etc. with their escaped versions */ 
- (NSString *) quote;
/** Truncates a string to 20 characters plus ellipsis. Uses NSSTRING_TRUNCATE_LENGTH if defined. */ 
- (NSString *) truncate;
/** Truncates a string to len characters plus ellipsis.
 * @param len new length. ellipsis will be added.
 */ 
- (NSString *) truncateToLength:(NSInteger)len;
/** Counts the number of occurrences of a string in another string */
- (NSInteger) countOccurrencesOfString:(NSString *)aString;
@end

/** A category on NSDictionary providing handy utility and convenience functions. */
@interface NSDictionary (BMScriptUtilities)
/** 
 * Returns a new dictionary by adding another object. 
 * @param object the object to add
 * @param key the key to add it for
 */
- (NSDictionary *) dictionaryByAddingObject:(id)object forKey:(id)key;
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
