//
//  BMScript.h
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

// MARK: Docs: Mainpage

/*!
 * @mainpage BMScript: Harness The Power Of Shell Scripts
 * 
 * BMScript is an Objective-C class set to make it easier to utilize the
 * power and flexibility of a whole range of scripting languages that already
 * come with modern Macs. BMScript does not favor any particular scripting
 * language or UNIX™ command line tool for that matter, instead it was written
 * as an abstraction layer to NSTask, and as such supports any command line tool, 
 * provided that it is available on the target system.
 *
 * BMScript can be used in two ways:
 *
 * -# Use it directly
 * -# Guided by the BMScriptLanguageProtocol, subclass it
 * 
 * The easiest way to employ BMScript is, of course, using it directly:
 *
 * @include bmScriptCreationMethods.m
 *
 * You typically use the designated initializer for which you supply the script
 * source and script options yourself. 
 * 
 * The options dictionary then looks like this:
 *
 * @include bmScriptOptionsDictionary.m
 * 
 * There's two constant keys. These are the only keys you need to define values for.
 * #BMScriptOptionsTaskLaunchPathKey stores the path to the tool's executable and 
 * #BMScriptOptionsTaskArgumentsKey is a nil-terminated variadic list of parameters 
 * to be used as arguments.
 * 
 * It is very important to note that the script source string should <b>NOT</b> be 
 * supplied in the array for the #BMScriptOptionsTaskArgumentsKey, as it will be added 
 * later by the class after performing some tests and replacements.
 *
 * A macro function called #BMSynthesizeOptions(path, args) is available to ease 
 * the declaration of the options. 
 * 
 * Here is the definition:
 *
 * @include bmScriptSynthesizeOptions.m
 *
 * @attention Don't forget the <b><span class="stringliteral">nil</span></b> at the end even 
 * if you don't need to supply any task arguments.
 *
 * If you initialize BMScript directly without specifying options and script source 
 * (e.g. using <span class="stringliteral">[[BMScript alloc] init]</span>) the options
 * will default to <span class="stringliteral">BMSynthesizeOptions(@"/bin/sh", @"-c", nil)</span>
 * and the script source will default to <span class="stringliteral">@"echo '<script source placeholder>'"</span>.
 *
 * @attention If you let your end-users, the consumers of your application, supply the 
 * script source without defining exact task options this can be very dangerous as anything
 * passed to /bin/sh is not checked by default! This might be a good reason to subclass BMScript
 * instead of using it directly.
 *
 * There are also convenience methods for the most common scripting languages, which have
 * their options set to OS default values:
 *
 * @include bmScriptConvenienceMethods.m
 *
 * As you can see loading scripts from source files is also supported, including a small
 * and lightweight template system. 
 * 
 * @par Templates
 * 
 * Using templates can be a good way to add domain-specific problem solving to a class. 
 * To utilize the template system, three steps are required:
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
 * If this pattern structure is empty it will be replaced in the order of occurrence. The first 
 * two saturate methods are good for this. 
 * If the magic token wraps other values, a more flexible dictionary based system can be used
 * with the third saturate method. There, the magic token must wrap names of keys defined in the
 * dictionary which will correspond to what the replacement value will be. Here is an example of a
 * Ruby script template, which converts octal or hexadecimal values to their decimal representation:
 *
 * @include convertToDecimalTemplate.rb
 *
 * @par Subclassing BMScript
 *
 * You can also see BMScript as a sort of abstract superclass and customize its 
 * behaviour by making a subclass which knows about the details of the particular 
 * command line tool that you want to utilize. Your subclass must implement the 
 * BMScriptLanguageProtocol. It only has one required and one optional method:
 *
 * @include bmScriptLanguageProtocol.m
 *
 * The first method should return default values, e.g. for launch path and task arguments, 
 * which are sensible and specific to the command line tool your subclass wants to utilize.
 * Here you may again use #BMSynthesizeOptions(path, args) as the options dictionary has the
 * same format as shown above.
 *
 * The second (optional) method should provide a default script source containing commands to execute
 * by the command line tool. If you do not implement this method the script source will be set
 * to the default script source of BMScript (see above).
 *
 * If you subclass BMScript and do not use the designated initializer through which 
 * you supply options and script source yourself, the BMScriptLanguageProtocol-p.defaultOptionsForLanguage 
 * method will be called on your subclass. If it is missing an exception of type 
 * #BMScriptLanguageProtocolMethodMissingException is thrown.
 *
 * @par Execution
 *
 * After you have obtained and configured a BMScript instance, you need to tell it to execute.
 * This can be done by telling it to excute synchroneously (blocking), or asynchroneously (non-blocking):
 *
 * @include bmScriptExecution.m
 *
 * Using the blocking execution model you can either pass a pointer to NSString where the result will be
 * written to (including NSError if needed), or just use plain BMScript.execute followed by BMScript.lastResult.
 * 
 * The non-blocking execution model works by means of <a href="http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CocoaFundamentals/CommunicatingWithObjects/CommunicateWithObjects.html#//apple_ref/doc/uid/TP40002974-CH7-SW7" class="code">notifications</a>.
 * You register your class as observer with the default notification center for a notification called 
 * #BMScriptTaskDidEndNotification passing a selector to execute once the notification arrives. If you have 
 * multiple BMScript instances you can also pass the instance you want to register the notification for as
 * the object paramater (see inline example below). 
 * 
 * Then you tell the BMScript instance to BMScript.executeInBackgroundAndNotify. When execution finishes and your
 * selector is called it will be passed an NSNotification object which encapsulates an NSDictionary with two keys:
 *
 * -# #BMScriptNotificationTaskResults              contains the results returned by the execution as NSString.
 * -# #BMScriptNotificationTaskTerminationStatus    contains the termination status (aka return/exit code)
 * 
 * To make that clearer here's an example with the relevant parts thrown together:
 *
 * @include bmScriptNotificationExample.m
 *
 * It is important to note at this point that the blocking and non-blocking tasks are tracked by seperate instance variables.
 * This was done to minimize the risk of race conditions when BMScript would be used in a multi-threaded environment. 
 *
 * @par On The Topic Of Concurrency
 * 
 * All access to global data, shared variables and mutable objects has been 
 * locked with <a href="x-man-page://pthread" class="code">pthread_mutex_locks</a> 
 * (in Xcode: right-click and choose "Open Link in Browser"). 
 * This is done by a macro wrapper which will avaluate to nothing if #BMSCRIPT_THREAD_SAFE is not 1. 
 * Note that there haven't been enough tests yet to say that BMScript is
 * thread-safe. It is likely to be thread-safe enough, but if that will be enough for your own application will 
 * unfortunately have to be tested by you. 
 *
 * @par Delegate Methods
 * 
 * BMScript also features a delegate protocol (BMScriptDelegateProtocol) providing descriptions for methods 
 * your subclass or another class posing as delegate can implement:
 * 
 * @include bmScriptDelegateMethods.m
 *
 * And last but not least, BMScript features an execution cache, called its history. This works like the Shell history
 * in that it will keep script sources as well as the results of the execution of those sources.
 * To access the history you may use the following methods:
 *
 * @include bmScriptHistory.m
 *
 * @example BMScriptExampleSubclassing.m
 * Example of subclassing BMScript. 
 * This subclass provides specifics about executing Ruby scripts. 
 * Of course this example is a bit of a moot point because BMScript 
 * already comes with convenience constructors for all the major 
 * scripting languages. Nevertheless, it nicely illustrates the bare minimum 
 * needed to subclass BMScript. From a somewhat more realistic 
 * and practical point of view, reasons to subclass BMScript may include:
 *
 * - You need to give your end-users the ability to supply script sources
 *   and want to implement much more robust error checking in order to do so.
 *
 * - You want to be able to also support NSTask's environment dictionary
 *   as this is currently not recognized by BMScript.
 *
 * - You want to initialize BMScript's ivars based on different criteria.
 * 
 * @example BMScriptExamples1.m
 * Assorted usage examples.
 *
 */

/*!
 * @file BMScript.h
 * Class interface of BMScript.
 * Also includes the documentation mainpage.
 */

#import <Cocoa/Cocoa.h>
#import "BMDefines.h"
#include <AvailabilityMacros.h>

/*!
 * @addtogroup defines Defines
 * @{
 */

#ifndef BMSCRIPT_THREAD_SAFE
    /*!
     * @def BMSCRIPT_THREAD_SAFE
     * Toggles synchronization locks. 
     * Set this to 1 to wrap globals, shared data and immutable objects with locks. 
     * Noop if set to 0.
     */
    #define BMSCRIPT_THREAD_SAFE 1
    #ifndef BMSCRIPT_FAST_LOCK
        /*!
         * @def BMSCRIPT_FAST_LOCK
         * Toggles usage of <span class="stringliteral">pthread_mutex_lock()</span> as opposed to <span class="stringliteral">\@synchronized(self)</span>.
         *
         * Set this to 1 to use the pthread library directly instead of Cocoa's \@synchronized directive which is reported to live a bit on the slow side.
         * @see <a href="http://googlemac.blogspot.com/2006/10/synchronized-swimming.html">Synchronized Swimming (Google Mac Blog)</a>
         * 
         * (If the article still holds true, you'd have to evaluate that yourself)
         */
        #define BMSCRIPT_FAST_LOCK 1
    #endif
#endif

/*!
 * @def BM_ATOMIC
 * Toggles the atomicity attribute for Objective-C 2.0 properties. 
 * Will be set to <span class="stringliteral">nonatomic,</span> if #BMSCRIPT_THREAD_SAFE is 0, otherwise noop.
 */
#if !BMSCRIPT_THREAD_SAFE
    #define BM_ATOMIC nonatomic,
#else
    #define BM_ATOMIC 
#endif


/*!
 * @def BMSynthesizeOptions(path, ...)
 * Used to synthesize a valid options dictionary. 
 * You can use this convenience macro to generate the boilerplate code for the options dictionary containing both the BMScriptOptionsTaskLaunchPathKey and BMScriptOptionsTaskArgumentsKey keys.
 */
#define BMSynthesizeOptions(path, ...) \
    [NSDictionary dictionaryWithObjectsAndKeys:(path), BMScriptOptionsTaskLaunchPathKey, \
               [NSArray arrayWithObjects:__VA_ARGS__], BMScriptOptionsTaskArgumentsKey, nil]

/*! 
 * @def BM_PROBE(name, ...) 
 * DTrace probe macro. Combines testing if a probe is enabled and actually calling this probe. 
 */
#define BM_PROBE(name, ...) \
    if (BMSCRIPT_ ## name ## _ENABLED()) BMSCRIPT_ ## name(__VA_ARGS__)

/*! 
 * @} 
 */

/*! Provides a clearer indication of the task's termination status than simple integers.￼￼ */
typedef NSInteger TerminationStatus;

enum {
    /*! task not executed yet */
    BMScriptNotExecutedTerminationStatus = -1,
    /*! task finished successfully */
    BMScriptFinishedSuccessfullyTerminationStatus = 0,
    /*! task failed */
    BMScriptFailedTerminationStatus
    /* all else indicates erroneous termination status as returned by the task */
};

/*!
 * @addtogroup functions Functions and Global Variables
 * @{
 */

/*!
 * Creates an NSString from BOOL.
 * @param b the boolean to convert
 */
NS_INLINE NSString * BMStringFromBOOL(BOOL b) { return (b ? @"YES" : @"NO"); }
/*!
 * Creates an NSString from TerminationStatus.
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
            return [NSString stringWithFormat:@"task finished with return code %d", status];
            break;
    }
}

/*! 
 * @} 
 */

/*!
 * @addtogroup constants Constants
 * @{
 */

/*! Notficiation sent when the background task has ended */
OBJC_EXPORT NSString * const BMScriptTaskDidEndNotification;
/*! Key incorporated by the notification's userInfo dictionary. Contains the result string of the finished task */
OBJC_EXPORT NSString * const BMScriptNotificationTaskResults;
/*! Key incorporated by the notification's userInfo dictionary. Contains the termination status of the finished task */
OBJC_EXPORT NSString * const BMScriptNotificationTaskTerminationStatus;

/*! Key incorporated by the options dictionary. Contains the launch path string for the task */
OBJC_EXPORT NSString * const BMScriptOptionsTaskLaunchPathKey;
/*! Key incorporated by the options dictionary. Contains the arguments array for the task */
OBJC_EXPORT NSString * const BMScriptOptionsTaskArgumentsKey;
/*! currently unused */
OBJC_EXPORT NSString * const BMScriptOptionsVersionKey; /* currently unused */

/*!
 * Thrown when the template is not saturated with an argument. 
 * Call BMScript.saturateTemplateWithArgument: before calling BMScript.execute or one of its variants 
 */
OBJC_EXPORT NSString * const BMScriptTemplateArgumentMissingException;
/*!
 * Thrown when the template is not saturated with arguments. 
 * Call BMScript.saturateTemplateWithArguments: before calling BMScript.execute or one of its variants 
 */
OBJC_EXPORT NSString * const BMScriptTemplateArgumentsMissingException;

/*!
 * Thrown when a subclass promises to conform to the BMScriptLanguageProtocol 
 * but consequently fails to declare the proper header. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolDoesNotConformException;
/*!
 * Thrown when a subclass promises to conform to the BMScriptLanguageProtocol 
 * but consequently fails to implement all required methods. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolMethodMissingException;
/*!
 * Thrown when a subclass accesses implemention details in an improper way. 
 * Currently unused. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolIllegalAccessException;

/*! 
 * @} 
 */

/*!
 * @addtogroup protocols Protocols
 * @{
 */

/*!
 * @protocol BMScriptLanguageProtocol
 * Must be implemented by subclasses to provide sensible defaults for language or tool specific values.
 */
@protocol BMScriptLanguageProtocol
/*!
 * Returns the options dictionary. This is required.
 * @see #BMSynthesizeOptions and @link bmScriptOptionsDictionary.m @endlink
 */
- (NSDictionary *) defaultOptionsForLanguage;
@optional
/*!
 * Returns the default script source. This is optional and will be set to a placeholder if absent.
 * You might want to implement this if you plan on using plain alloc/init with your subclass a lot since 
 * alloc/init will pull this in as default script if no script source was supplied to the designated initalizer.
 */
- (NSString *) defaultScriptSourceForLanguage; 
@end

/*!
 * @protocol BMScriptDelegateProtocol
 * Objects conforming to this protocol may pose as delegates for BMScript.
 */
@protocol BMScriptDelegateProtocol
@optional
/*!
 * If implemented, called whenever a history item is about to be added to the history. 
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 *
 * @param anItem the item that will be set as new value in setter if this method returns YES.
 */
- (BOOL) shouldAddItemToHistory:(NSArray *)historyItem;
/*!
 * If implemented, called whenever a history item is about to be returned from the history.
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 *
 * @param anItem the item that will be returned from getter if this method returns YES.
 */
- (BOOL) shouldReturnItemFromHistory:(NSString *)historyItem;
/*!
 * If implemented, called whenever BMScript.result is about to change.
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 *
 * @param aString the string that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetResult:(NSString *)aString;
/*!
 * If implemented, called during execution in background (non-blocking) whenever new data is available.
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 * @param string the string that will be used as new value if this method returns YES.
 */
- (BOOL) shouldAppendPartialResult:(NSString *)string;
/*!
 * If implemented, called  whenever BMScript.script is set to a new value.  
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 * Can be used to guard against malicious cases if the script comes directly from the end-user.
 * @note This delegate is not called during initialization of a new instance. It is only triggered when changing BMScript.script after initialization is complete.
 * @param aScript the script that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetScript:(NSString *)aScript;
/*!
 * If implemented, called  whenever BMScript.options is set to a new value.  
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 * Can be used to guard against malicious cases if the options come directly from the end-user.
 * @param opts the dictionary that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetOptions:(NSDictionary *)opts;
/*!
 * If implemented, called before right before a new item is finally added to the history. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param anItem the string that will be added
 */
- (NSString *) willAddItemToHistory:(NSString *)anItem;
/*!
 * If implemented, called before right before an item is finally returned from the history. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param anItem the string that will be returned
 */
- (NSString *) willReturnItemFromHistory:(NSString *)anItem;
/*!
 * If implemented, called before right before a string is appended to BMScript.partialResult. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param string the string that will be appended
 */
- (NSString *) willAppendPartialResult:(NSString *)string;
/*!
 * If implemented, called before right before BMScript.result is set to a new value. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param aString the string that will be used as result
 */
- (NSString *) willSetResult:(NSString *)aString;
/*!
 * If implemented, called before right before BMScript.script is set to a new value. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param aScript the string that will be used as script
 */
- (NSString *) willSetScript:(NSString *)aScript;
/*!
 * If implemented, called before right before BMScript.options is set to a new value. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param opts the dictionary that will be used as options
 */
- (NSDictionary *) willSetOptions:(NSDictionary *)opts;

@end

/*! @} */

/*!
 * @class BMScript
 * A decorator class to NSTask providing elegant and easy access to the shell.
 */
@interface BMScript : NSObject <NSCoding, NSCopying, NSMutableCopying, BMScriptDelegateProtocol> {
 @protected
    NSString * script;
    NSDictionary * options;
    NSString * lastResult;
    __weak id delegate; 
 @private
    NSString * result;
    NSString * partialResult;
    __strong BOOL isTemplate;
    NSMutableArray * history;
    NSTask * task;
    NSPipe * pipe;
    NSTask * bgTask;
    NSPipe * bgPipe;
}

// Doxygen seems to "swallow" the first property item and not generate any documentation for it
// even if we put a proper documentation comment in front of it. It is unclear if that is the case
// only for this particular file or if there is a bug that globally causes it. As a workaround
// we take one of the hidden properties and put it up front to be swallowed since we don't want it
// to appear in the docs anyway.
@property (BM_ATOMIC retain) NSMutableArray * history;

/*! Gets and sets the script instance variable. */
@property (BM_ATOMIC copy) NSString * script;
/*! Gets and sets the options instance variable. */
@property (BM_ATOMIC retain) NSDictionary * options;
/*! Gets the last execution result. */
@property (nonatomic, readonly, copy) NSString * lastResult;
/*! Gets and sets the delegate instance variable. */
@property (BM_ATOMIC assign) __weak id<BMScriptDelegateProtocol> delegate;


// MARK: Initializer Methods

/*!
 * Initialize a new BMScript instance. If no options are specified calls the subclass' 
 * implementations of BMScriptLanguageProtocol-p.defaultScriptSourceForLanguage and BMScriptLanguageProtocol-p.defaultOptionsForLanguage.
 * BMScript.init on the other hand defaults to <span class="stringliteral">@"/bin/sh", @"-c"</span>, 
 * and <span class="stringliteral">@"echo \<script placeholder\>"</span>.
 */
- (id) init;
/*!
 * Initialize a new BMScript instance with a script source. If no options are specified calls 
 * the subclass' or BMScript's  implementation of BMScriptLanguageProtocol-p.defaultOptionsForLanguage.
 * @param scriptSource a string containing commands to execute
 */
- (id) initWithScriptSource:(NSString *)scriptSource;
/*!
 * Initialize a new BMScript instance with a script source. This is the designated initializer.
 * @param scriptSource a string containing commands to execute
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;     /* designated initializer */
/*!
 * Initialize a new BMScript instance with a template source. 
 * A template needs to be saturated ("filling in the blanks") before it can be used. 
 * @see saturateTemplateWithArgument: and variants.
 * @param templateSource a string containing a template with magic tokens (@see mainpage) to saturate resulting in commands to execute.
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithTemplateSource:(NSString *)templateSource options:(NSDictionary *)scriptOptions;
/*!
 * Initialize a new BMScript instance with contents of a file. 
 * @param path a string pointing to a file on disk. The contents of this file will be used as source script.
 */
- (id) initWithContentsOfFile:(NSString *)path;
/*!
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a file on disk. The contents of this file will be used as source script.
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
/*!
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a <i>template</i> file on disk. 
 * The contents of this file will be used as template which must be <b>saturated</b> before calling BMScript.execute or one of its variants.
 * @see #saturateTemplateWithArgument: et al.
 */
- (id) initWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Initialize a new BMScript instance. 
 * @param path a string pointing to a <i>template</i> file on disk. 
 * The contents of this file will be used as template which must be <b>saturated</b> before calling BMScript.execute or one of its variants.
 * @param scriptOptions a dictionary containing the task options
 * @see #saturateTemplateWithArgument: et al.
 */
- (id) initWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;

// MARK: Factory Methods

/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
//+ (id) scriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;
/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
//+ (id) scriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
//+ (id) scriptWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;

// MARK: Templates

/*!
 * Replaces a single %{} construct in the template.
 * @param tArg the value that should be inserted
 * @return YES if the replacement was successful, NO on error
 */
- (BOOL) saturateTemplateWithArgument:(NSString *)tArg;
/*!
 * Replaces multiple %{} constructs in the template.
 * @param firstArg the first value which should be inserted
 * @param ... the remaining values to be inserted in order of occurrence
 * @return YES if the replacements were successful, NO on error
 */
- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ...;
/*!
 * Replaces multiple %{<i>KEY</i>} constructs in the template. 
 * The <i>KEY</i> phrase is a variant and describes the name of a key in the dictionary passed to this method.
 * If the key is found in the dictionary its corresponding value will be used to replace the magic token in the template.
 * @param dictionary a dictionary with keys and their values which should be inserted
 * @return YES if the replacements were successful, NO on error
 */
- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary;

// MARK: Execution

/*!
 * Executes the script with a synchroneous (blocking) task. You get the result with BMScript.lastResult.
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) execute;
/*!
 * Executes the script with a synchroneous (blocking) task and stores the result in &result.
 * @param result a pointer to an NSString where the result should be written to
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) executeAndReturnResult:(NSString **)results;
/*!
 * Executes the script with a synchroneous (blocking) task. To get the result call BMScript.lastResult.
 * @param result a pointer to an NSString where the result should be written to
 * @param error a pointer to an NSError where errors should be written to
 * @return YES if the execution was successful, NO on error
 */
- (BOOL) executeAndReturnResult:(NSString **)results error:(NSError **)error;
/*!
 * Executes the script with a asynchroneous (non-blocking) task. The result will be posted with the help of a notifcation item.
 * @see @link bmScriptNotificationExample.m @endlink
 */
- (void) executeInBackgroundAndNotify; 

// MARK: History

/*!
 * Returns a cached script source from the history. 
 * @param index index of the item to return. May return nil if the history does not contain any objects.
 */
- (NSString *) scriptSourceFromHistoryAtIndex:(int)index;
/*!
 * Returns a cached result from the history. 
 * @param index index of the item to return. May return nil if the history does not contain any objects.
 */
- (NSString *) resultFromHistoryAtIndex:(int)index;
/*!
 * Returns the last cached script source from the history. 
 * May return nil if the history does not contain any objects.
 */
- (NSString *) lastScriptSourceFromHistory;
/*!
 * Returns the last cached result from the history. 
 * May return nil if the history does not contain any objects.
 */
- (NSString *) lastResultFromHistory;

// MARK: Equality

/*!
 * Returns YES if the source script is equal.
 */
- (BOOL) isEqual:(BMScript *)other;
/*!
 * Returns YES if the source script and launch path are equal.
 */
- (BOOL) isEqualToScript:(BMScript *)other;

@end



/*!
 * A category on BMScript adding default factory methods for Ruby, Python and Perl.
 * The task options use default paths (for 10.5 and 10.6) for the task launch path.
 */
@interface BMScript(CommonScriptLanguagesFactories)
/*!
 * Returns an autoreleased Ruby script ready for execution.
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) rubyScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Ruby script from a file ready for execution.
 * @param path path to a file containing the commands to execute.
 */
+ (id) rubyScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Ruby script template ready for saturation.
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Returns an autoreleased Python script ready for execution.
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) pythonScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Python script from a file ready for execution.
 * @param path path to a file containing the commands to execute.
 */
+ (id) pythonScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Python script template ready for saturation.
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Returns an autoreleased Perl script ready for execution.
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) perlScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Perl script from a file ready for execution.
 * @param path path to a file containing the commands to execute.
 */
+ (id) perlScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Perl script template ready for saturation.
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path;
@end

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
/*!A category on NSString providing compatibility for missing methods on 10.4 (Tiger). */
@interface NSString (BMScriptNSString10_4Compatibility)
/*!
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
/*!
 * An implementation of the 10.5 (Leopard) method of NSString. Replaces all occurrences of a string with another string. 
 * Calls stringByReplacingOccurrencesOfString:withString:options:range: with default options 0 and searchRange the full length of the searched string.
 * @deprecated Deprecated in 10.5 (Leopard) in favor of NSString's own implementation.
 */
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement; DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER
@end
#endif

/*!
 * A category on NSString providing some handy utility functions
 * for end user display of strings. 
 */
@interface NSString (BMScriptStringUtilities)
/*!
 * Replaces all occurrences of newlines, carriage returns, double quotes etc. with their escaped versions 
 * @return the quoted string
 */ 
- (NSString *) quote;
/*!
 * Truncates a string to 20 characters plus ellipsis. Uses BM_NSSTRING_TRUNCATE_LENGTH if defined. 
 * @return the truncated string
 */ 
- (NSString *) truncate;
/*! 
 * Truncates a string to len characters plus ellipsis.
 * @param len new length. ellipsis will be added.
 * @return the truncated string
 */ 
- (NSString *) truncateToLength:(NSUInteger)len;
/*!
 * Counts the number of occurrences of a string in another string 
 * @param aString the string to count occurrences of
 * @return NSInteger with the amount of occurrences
 */
- (NSInteger) countOccurrencesOfString:(NSString *)aString;
@end

/*! A category on NSDictionary providing handy utility and convenience functions. */
@interface NSDictionary (BMScriptUtilities)
/*!
 * Returns a new dictionary by adding another object. 
 * @param object the object to add
 * @param key the key to add it for
 * @return the modified dictionary
 */
- (NSDictionary *) dictionaryByAddingObject:(id)object forKey:(id)key;
@end
