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
 * <hr>
 * @par Introduction
 *
 * BMScript is an Objective-C class set to make it easier to utilize the
 * power and flexibility of a whole range of scripting languages that already
 * come with modern Macs. BMScript does not favor any particular scripting
 * language or UNIX™ command line tool for that matter, instead it was written
 * as an abstraction layer to NSTask, and as such supports any command line tool,
 * provided that it is available on the target system.
 *
 * @par Usage
 *
 * First off, to use BMScript in your own project, all you need to do is add the three
 * files that comprise BMScript:
 *
 * -# BMDefines.h
 * -# BMScript.h
 * -# BMScript.m
 *
 * Then BMScript can be used in in your own code one of two ways:
 *
 * -# Use it directly
 * -# Guided by the BMScriptLanguageProtocol, make a subclass from it
 *
 * The easiest way to use BMScript is, of course, to instantiate it directly:
 *
 * @include bmScriptCreationMethods.m
 *
 * You typically use the designated initializer for which you supply the script
 * source and task options yourself.<br>
 * The options dictionary then looks like this:
 *
 * @include bmScriptOptionsDictionary.m
 *
 * There's two constant keys. These are the only keys you need to define values for.
 * #BMScriptOptionsTaskLaunchPathKey stores the path to the tool's executable and
 * #BMScriptOptionsTaskArgumentsKey is a nil-terminated variable list of parameters
 * to be used as arguments to the task which will load and execute the tool found at
 * the launch path specified for the other key.
 *
 * It is very important to note that the script source string should <b>NOT</b> be
 * supplied in the array for the #BMScriptOptionsTaskArgumentsKey, as it will be added
 * later by the class after performing tests and delegation which could alter the script
 * in ways needed to safely execute it. This is in the delegate object's responsibility.
 *
 * A macro function called #BMSynthesizeOptions(path, args) is available to ease
 * the declaration of the options.<br>
 * Here is the definition:
 *
 * @include bmScriptSynthesizeOptions.m
 *
 * Notice how you must supply <b>at least two parameters</b> to the macro function. Supply an empty string for the arguments if you do not need to set any.
 *
 * If you initialize BMScript directly without specifying options and script source
 * (e.g. using <span class="sourcecode">[[BMScript alloc] init]</span>) the options
 * will default to <span class="sourcecode">BMSynthesizeOptions(\@&quot;/bin/echo&quot;, &quot;&quot;)</span> 
 * and the script source will default to <span class="sourcecode">\@&quot;&apos;&lt;script source placeholder&gt;&apos;&quot;</span>.
 *
 * <div class="box warning">
 *      <div class="table">
 *          <div class="row">
 *              <div class="label cell">Warning:</div>
 *              <div class="message cell">
 *                  If you let your end-users, the consumers of your application, supply the
 *                  script source without defining exact task options this can be very dangerous as anything
 *                  passed to <span class="sourcecode">/bin/echo</span> is not checked by default! This is a
 *                  good reason to use the BMScriptDelegateProtocol methods for error/security checking or to
 *                  subclass BMScript instead of using it directly.
 *              </div>
 *          </div>
 *      </div>
 *  </div>
 *
 * There are also convenience methods for the most common scripting languages, which have
 * their options set to OS default values:
 *
 * @include bmScriptConvenienceMethods.m
 *
 * As you can see loading scripts from source files is also supported, including a small
 * and lightweight template system. Before moving on to templates, though, it is important
 * to note that BMScript always expects any external data (files) to be in <b>UTF-8</b> encoding.
 * If you are unsure about the file's encoding, it is suggested to try to read in the file contents
 * yourself (using NSString API for example) and then use BMScript through its designated initializer 
 * to set the script source.
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
 * token strings bound to get replaced. If you are familiar with Xcode text macros, the
 * magic token literals look like .xctxtmacro replacement tokens:
 *
 * @verbatim <##> @endverbatim
 *
 * If this pattern structure is empty (like shown) it will be replaced in the order of occurrence. 
 * The first two saturate methods are good for this.
 * If the magic tokens wrap other values, a more flexible dictionary based system can be used
 * with the third saturate method. There, the magic tokens must wrap names of keys defined in the
 * dictionary. The keys will correspond to what the replacement value will be. <br>
 *
 * Here is an example of a Ruby script template, which converts octal or hexadecimal values to their decimal representation:
 *
 * @include convertToDecimalTemplate.rb
 *
 * Here's a short example how you'd use keyword based templates:
 *
 * @include TemplateKeywordSaturationExample.m
 *
 * @note In BMScript v0.1 the magic token was equivalent to one form of Ruby's double qouted string literal: <span class="sourcecode">%{}</span>.
 * The idea behind this was that the concept should be somewhat familiar and easy to grasp. I have since changed this as it introduced too many 
 * back and forth escapings of the percent signs in order to be used as format strings, besides being generally confusing. 
 *
 * Instead I have decided to use Xcode's text macro tokens. 
 * There are two benefits to this:
 *
 *      -# No escaping necessary to use as format strings.
 *      -# Xcode shows them graphically in the source text as replacement values.
 *
 * If you want to change the magic token string to something else you can either change the #BMSCRIPT_TEMPLATE_TOKEN_START and #BMSCRIPT_TEMPLATE_TOKEN_END defines,
 * or, if you are using the dictionary based saturation method (BMScript#saturateTemplateWithDictionary:) you can set two keys in the dictionary which correspond to the defines
 * mentioned previously. The keys are #BMScriptTemplateTokenStartKey and #BMScriptTemplateTokenEndKey respectively.
 * 
 * I am also thinking about including an additional set of saturation methods which will allow you to pass in magic token start and end strings for the sequential saturation methods.
 * If there is demand for it I will try to include them in the next version.
 *
 * @par Subclassing BMScript
 *
 * You can also see BMScript as a sort of abstract superclass and customize its
 * behaviour by making a subclass which knows about the details of the particular
 * command line tool that you want to use. Your subclass must implement the
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
 * This can be done by telling it to excute synchroneously (blocking), <b>or</b> asynchroneously (non-blocking).
 * Note the <b>or</b>: you should not use the same BMScript instance for blocking and non-blocking execution
 * at the same time. It is far safer to use one BMScript instance for blocking and another for non-blocking
 * execution.
 *
 * @include bmScriptExecution.m
 *
 * Using the blocking execution model you can either pass a pointer to NSString where the result will be
 * written to (including NSError if needed), or just use plain BMScript.execute. 
 * This will return the script's ExecutionStatus, giving you an indication if the script was executed, 
 * if it is executing, if an exception was encountered or if it finished successfully.
 * You can then obtain the script execution result by accessing BMScript.result by calling <span class="sourcecode">lastResult</span>.
 *
 * The non-blocking execution model works by means of <a href="http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CocoaFundamentals/CommunicatingWithObjects/CommunicateWithObjects.html#//apple_ref/doc/uid/TP40002974-CH7-SW7" class="external">notifications</a>.
 * You register your class as observer with the default notification center for a notification called
 * #BMScriptTaskDidEndNotification passing a selector to execute once the notification arrives. If you have
 * multiple BMScript instances you can also pass the instance you want to register the notification for as
 * the object paramater (see inline example below).
 *
 * Then you tell the BMScript instance to BMScript.executeInBackgroundAndNotify. When execution finishes and your
 * selector is called it will be passed an NSNotification object which encapsulates an NSDictionary with three keys:
 *
 * <div class="box hasRows noshadow">
 *      <div class="row odd firstRow">
 *          <span class="cell left firstCell">#BMScriptNotificationTaskResults</span>
 *          <span class="cell rightCell lastCell">contains the results returned by the execution.</span>
 *      </div>
 *      <div class="row even">
 *          <span class="cell left firstCell">#BMScriptNotificationTaskReturnValue</span>
 *          <span class="cell rightCell lastCell">contains the underlying task's exit code (aka return value)</span>
 *      </div>
 *      <div class="row odd">
 *          <span class="cell left firstCell">#BMScriptNotificationExecutionStatus</span>
 *          <span class="cell rightCell lastCell">contains the script's execution status</span>
 *      </div>
 * </div>
 *
 * To make that clearer here's an example with the relevant parts thrown together:
 *
 * @include NonBlockingExecutionExample.m
 *
 * It is important to note at this point that the underlying tasks and pipes for a blocking and non-blocking execution
 * are tracked by seperate instance variables. This was done to make re-using a blocking BMScript instance as non-blocking
 * safer and vice versa. While I said earlier you should use one BMScript instance for blocking and non-blocking execution
 * this meant not using the same instance for both models <b>at the same time</b>. It should be safe to use the same instance 
 * for the other execution model once it has finished and completed successfully.
 *
 * @par On The Topic Of Concurrency
 *
 * All access to global data, shared variables and mutable objects has been
 * locked with <a href="x-man-page://pthread" class="external">pthread_mutex_locks</a> <small>*</small>.
 * This is done by a macro wrapper which will avaluate to nothing if #BMSCRIPT_THREAD_AWARE is not <span class="sourcecode">1</span>.
 * #BMSCRIPT_THREAD_AWARE will also set #BM_ATOMIC to <span class="sourcecode">1</span> which will make all accessors atomic.
 * 
 * However, to make it clear: <b>currently BMScript is not classified as being thread-safe!</b>
 * 
 * Especially as there haven't been enough tests in a multi-threaded environment yet as to say much 
 * about BMScript's thread-safety status. 
 *
 * That doesn't mean that you can't use BMScript in a threaded application. It really depends on the usage.
 * Be very careful, though, about passing around a single BMScript instance from thread to thread and also restrict
 * shared access to one BMScript instance. BMScript was designed such that each instance can fully encapsulate
 * the behaviour and state it needs to do its thing.
 *
 * BMScript was also designed such that re-use is possible. Unfortunately this does not automatically mean it 
 * intrinsically promotes re-entrant code. 
 *
 * You are encouraged to look through the source code in order to determine how you may use BMScript safely in a threaded
 * application.
 *
 * <small>*) in Xcode: right-click and choose "Open Link in Browser"</small>.
 *
 * @par Delegate Methods
 *
 * BMScript also features a delegate protocol (BMScriptDelegateProtocol) providing instances posing as the delegate
 * with the opportunity to have a say in wether a script should get added or removed from the instance local history,
 * whether or not partialData should be appended to the final result for continuously executing background tasks
 * and also providing them with the power to change the resulting data, which is perfect for validation of end-user 
 * enterred data, or data coming from a command line interface that's historically manifold. Employing delegates allow
 * you to customize the behavior of BMScript instances without the need to make a domain-specific subclass. 
 *
 * As a general rule of thumb, methods starting with <span class="sourcecode">should...</span> will be passed some data 
 * for the delegate to inspect and validate and expect a BOOL in return. If the return value is YES, the operation continues 
 * (e.g. the history item is added to the instance local history). 
 *
 * Methods starting with <span class="sourcecode">will...</span> cannot stop the operation but they can modify the data 
 * passed in and the returned modified data is then used for the remainder of the operation.
 *
 * @include bmScriptDelegateMethods.m
 *
 * @par Instance Local Execution History
 *
 * And last but not least, BMScript features an execution cache, called its history. This works like the Shell history
 * in that it will keep script sources as well as the results of the execution of those sources.
 * To access the history you may use the following methods:
 *
 * @include bmScriptHistory.m
 *
 */

// MARK: Docs: Examples

/*!
 * @example SubclassingExample.m
 *
 * Example of subclassing BMScript.
 *
 * This subclass provides specifics about executing Ruby scripts.
 * Of course this example is a bit of a moot point because BMScript
 * already comes with convenience constructors for all the major
 * scripting languages. Nevertheless, it nicely illustrates the bare minimum
 * needed to subclass BMScript. From a somewhat more realistic
 * and practical point of view, reasons to subclass BMScript may include:
 *
 * - You need to give your end-users the ability to supply script sources
 *   and want to employ much more robust error checking than the delegation
 *   system around BMScriptDelegateProtocol-p can provide to you.
 *
 * - You want to be able to also make use of NSTask's environment dictionary
 *   as this is currently unused by BMScript.
 *
 * - You want to initialize BMScript's ivars based on different criteria.
 *
 */

/*!
 * @example BlockingExecutionExamples.m
 * Usage examples for the blocking execution model.
 * 
 * This is the default way of using BMScript:
 * Initialize with the designated initializer and supply script and options
 * 
 * @include BlockingExecutionExamples1.m
 * 
 * Another way of using the blocking execution model:
 * 
 * @include BlockingExecutionExamples2.m
 * 
 * You can of course change the script source of an instance after the fact.
 * Normally NSTasks are one-shot (not for re-use), so it is convenient that
 * BMScript handles all the boilerplate setup for you in an opaque way.
 *
 * @include BlockingExecutionExamples3.m
 *
 * Any execution and its corresponding result are stored in the instance local
 * execution cache, also called its history. Usage is pretty self explanatory. 
 * Take a look at BMScript#scriptSourceFromHistoryAtIndex: et al.
 * You can a script source from history by supplying an index or you can get the 
 * last one executed. Same goes for the execution results.
 * 
 * Currently the return values (exit codes) are not stored in the history. Might
 * be added at a later time, but for now you can just save the value returned by
 * BMScript#lastReturnValue in a variable of your own before you do anything else with your 
 * BMScript instance.
 * 
 */

/*!
 * @example NonBlockingExecutionExample.m
 * Shows how to setup the non-blocking execution model. <br>
 * This shows just one possible way out of many to utilize the notification send from the async execution.
 */

/*!
 * @example TemplateKeywordSaturationExample.m
 * Shows how to saturate a keyword based template.
 */


/*!
 * @file BMScript.h
 * Class interface of BMScript.
 * Also includes the documentation mainpage.
 */
#import "BMDefines.h"
#import <Cocoa/Cocoa.h>
#include <AvailabilityMacros.h>

/*!
 * @addtogroup defines Defines
 * @{
 */

// Note: Doxygen 1.6.3 seems to have an issue with the order of the defines.
// To get BMSCRIPT_THREAD_AWARE to show up at all I have to put its define block
// up front but with empty doc comment. Further down you will see that I undefine
// it and define it again with the same define construct but this time with non-empty
// doc comment. Apparently for this file this was the only way so that it shows up
// and properly at that - meaning: it doesn't shuffle the doc comment descriptions around
// between the other defines defined here.

/*!
 * 
 */
#ifndef BMSCRIPT_THREAD_AWARE
    #define BMSCRIPT_THREAD_AWARE 0
#else
    #undef BMSCRIPT_THREAD_AWARE
    #define BMSCRIPT_THREAD_AWARE 1
#endif

/*!
 * Enables synchronization locks and toggles the atomicity attribute of property declarations. 
 * If not defined, synchronization locks will be noop and properties will be nonatomic.
 */
#ifndef BMSCRIPT_THREAD_AWARE
    #define BMSCRIPT_THREAD_AWARE 0
#endif

/*!
 * Toggles the atomicity attribute for Objective-C 2.0 properties. 
 * Will be set to <span class="sourcecode">nonatomic,</span> if ::BMSCRIPT_THREAD_AWARE is 0, otherwise noop.
 */
#if BMSCRIPT_THREAD_AWARE
    #define BM_ATOMIC 
#else
    #define BM_ATOMIC nonatomic,
#endif

/*!
 * Toggles usage of <a href="x-man-page://pthread_mutex_lock" class="external">pthread_mutex_lock(3) *</a>
 * as opposed to <a href="http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/ObjectiveC/Articles/ocThreading.html" class="external">\@synchronized(self)</a>.
 *
 *
 * Set this to 1 to use the pthread library directly instead of Cocoa's <span class="sourcecode">\@synchronized</span> directive which is reported to live a bit on the slow side.
 * @see <a href="http://googlemac.blogspot.com/2006/10/synchronized-swimming.html" class="external">Synchronized Swimming (Google Mac Blog)</a>
 * 
 * You may have to evaluate yourself if the article still holds true. I'm mearly pointing you to it. <br>
 * (Though, utilizing the locking DTrace probes, I couldn't find much of a difference between the two).
 *<br/>
 *<hr>
 <small>%*) In Xcode right-click and choose Open Link in Browser</small>
 */
#if BMSCRIPT_THREAD_AWARE
    #ifndef BMSCRIPT_FAST_LOCK
        #define BMSCRIPT_FAST_LOCK 0
    #else
        #undef BMSCRIPT_FAST_LOCK
        #define BMSCRIPT_FAST_LOCK 1
    #endif
#else
    #define BMSCRIPT_FAST_LOCK 0
#endif

/*! Toggle for DTrace probes. */
#ifndef BMSCRIPT_ENABLE_DTRACE
    #define BMSCRIPT_ENABLE_DTRACE 0
#endif



/*! 
 * DTrace probe macro. Combines testing if a probe is enabled and actually calling this probe. 
 * If #BMSCRIPT_ENABLE_DTRACE is not set to 1 this macro evaluates to nothing.
 * @param name name of the dtrace probe (macro expanded and concatenated between BMSCRIPT_ and _ENABLED()). 
 * @param ... arguments to supply to the dtrace probe.
 * @returns if construct with expanded dtrace probe name
 */
#ifdef BMSCRIPT_ENABLE_DTRACE
    #define BM_PROBE(name, ...) \
        if (BMSCRIPT_ ## name ## _ENABLED()) BMSCRIPT_ ## name(__VA_ARGS__)
#else
    #define BM_PROBE(name, ...)
#endif

/*! 
 * The insertion token sandwiched between start and end token. 
 * As this is passed as an NSString format string the insertion token should always be <span class="sourcecode">\@&quot;%\@&quot;</span>. 
 * It is then used by template initialization and saturation methods to mark locations where a replacement should occur.
 */
#define BMSCRIPT_INSERTION_TOKEN        @"%@"
/*!
 * The beginning part of the magic (replacement) token that wraps the insertion token. 
 * Thus used in templates together with the end token to precisely indicate the location of an insertion token. 
 * Note: with dictionary based saturation methods you can specify start and end tokens yourself without changing both start and end defines.
 * @sa BMScriptTemplateTokenStartKey, BMScriptTemplateTokenEndKey
 */
#define BMSCRIPT_TEMPLATE_TOKEN_START   @"<#"
/*!
 * The ending part of the magic (replacement) token that wraps the insertion token. 
 * Thus used in templates together with the start token to precisely indicate the location of an insertion token. 
 * Note: with dictionary based saturation methods you can specify start and end tokens yourself without changing both start and end defines.
 * @sa BMScriptTemplateTokenStartKey, BMScriptTemplateTokenEndKey
 */
#define BMSCRIPT_TEMPLATE_TOKEN_END     @"#>"

/*!
 * Used to synthesize a valid options dictionary. 
 * You can use this convenience macro to generate the boilerplate code for the options dictionary 
 * containing both the #BMScriptOptionsTaskLaunchPathKey and #BMScriptOptionsTaskArgumentsKey keys.
 *
 * The variadic parameter (...) is passed directly to <span class="sourcecode">[NSArray arrayWithObjects:...]</span>
 * <div class="box important">
        <div class="table">
            <div class="row">
                <div class="label cell">Important:</div>
                <div class="message cell">
                    The macro will terminate the variable argument list with <b>nil</b>, which means you need to make sure
                    you always pass some value for it. If you don't, you will create <span class="sourcecode">__NSArray0</span> pseudo objects which are 
                    not released in a Garbage Collection enabled environment. If you do not want to set any task args 
                    simply pass an empty string, e.g. <span class="sourcecode">BMSynthesizeOptions(@"/bin/echo", @"")</span>
                </div>
            </div>
        </div>
 * </div>
 * 
 */
#define BMSynthesizeOptions(path, ...) \
    [NSDictionary dictionaryWithObjectsAndKeys:(path), BMScriptOptionsTaskLaunchPathKey, \
          [NSArray arrayWithObjects:__VA_ARGS__, nil], BMScriptOptionsTaskArgumentsKey, nil]
/*! 
 * @} 
 */

/// @cond HIDDEN
#define BMSCRIPT_UNIT_TEST (int) (getenv("BMScriptUnitTestsEnabled") || getenv("BMSCRIPT_UNIT_TEST_ENABLED"))
/// @endcond

/*! Provides a default indicator of the script's execution status.
 *
 * Unfortunately there is no universally accepted return code for a failed task. 
 * Read the UNIX™ tool's man page to get the value for it's various failed stati 
 * and then compare it to the value returned by BMScript#lastReturnValue.
 * @sa BMNSStringFromExecutionStatus
 ￼￼*/
typedef enum {
    /*! script not executed yet */
    BMScriptNotExecuted = (NSInteger)-(NSIntegerMax-10),
    /*! script finished successfully */
    BMScriptFinishedSuccessfully = (NSInteger)0,
    /*! script task failed with an exception */
    BMScriptFailedWithException = (NSInteger)(NSIntegerMax-10)
} ExecutionStatus;

/*!
 * @addtogroup functions Functions and Global Variables
 * @{
 */

// MARK: Functions

/*!
 * Creates an NSString representaton from a BOOL.
 * @param b the boolean to convert
 */
NS_INLINE NSString * BMNSStringFromBOOL(BOOL b) { return (b ? @"YES" : @"NO"); }
/*!
 * Converts an ExecutionStatus to a human-readable form.
 * @param status the ExecutionStatus to convert
 */
NS_INLINE NSString * BMNSStringFromExecutionStatus(ExecutionStatus status) {
    switch (status) {
        case BMScriptNotExecuted:
            return @"script not executed";
            break;
        case BMScriptFinishedSuccessfully:
            return @"script finished successfully";
            break;
        case BMScriptFailedWithException:
            return @"script task failed with an exception. check if launch path and/or arguments are appropriate";
            break;
        default:
            return [NSString stringWithFormat:@"script terminated", status];
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

/*! Notification sent when the background task has ended */
OBJC_EXPORT NSString * const BMScriptTaskDidEndNotification;
/*! Key incorporated by the notification's userInfo dictionary. Contains the result data of the finished task */
OBJC_EXPORT NSString * const BMScriptNotificationTaskResults;
/*! 
 * Key incorporated by the notification's userInfo dictionary. 
 * Contains the execution status of the finished script. 
 * @note This is <b><i>NOT</i></b> the same as the task's exit code (return value). 
 * For the exit code see #BMScriptNotificationTaskReturnValue.
 */
OBJC_EXPORT NSString * const BMScriptNotificationExecutionStatus;
/*! Key incorporated by the notification's userInfo dictionary. Contains the termination status of the finished task */
OBJC_EXPORT NSString * const BMScriptNotificationTaskReturnValue;

/*! Key incorporated by the options dictionary. Contains the launch path string for the task */
OBJC_EXPORT NSString * const BMScriptOptionsTaskLaunchPathKey;
/*! Key incorporated by the options dictionary. Contains the arguments array for the task */
OBJC_EXPORT NSString * const BMScriptOptionsTaskArgumentsKey;
/*! 
 * Used by the template saturation dictionary to define the start (first part) of a custom magic (replacement) token. 
 * The default token is '<##>' where '<#' would be the start and '#>' the end. 
 */
OBJC_EXPORT NSString * const BMScriptTemplateTokenStartKey;
/*! 
 * Used by the template saturation dictionary to define the end (second part) of a custom magic (replacement) token. 
 * The default token is '<##>' where '<#' would be the start and '#>' the end. 
 */
OBJC_EXPORT NSString * const BMScriptTemplateTokenEndKey;

/*!
 * Thrown during BMScript execution when a template is not saturated with an argument. 
 * Call BMScript.saturateTemplateWithArgument: before calling BMScript.execute or one of its variants 
 */
OBJC_EXPORT NSString * const BMScriptTemplateArgumentMissingException;
/*!
 * Thrown when a subclass promises to conform to the BMScriptLanguageProtocol 
 * but consequently fails to declare the proper \@interface header (forgot to append <span class="sourcecode">&lt;BMScriptLanguage&gt;</span>). 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolDoesNotConformException;
/*!
 * Thrown when a subclass promises to conform to the BMScriptLanguageProtocol 
 * but consequently fails to implement all required methods. 
 */
OBJC_EXPORT NSString * const BMScriptLanguageProtocolMethodMissingException;

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
@protocol BMScriptLanguageProtocol <NSObject>
@required
/*!
 * Returns the options dictionary. This is required.
 * @see #BMSynthesizeOptions and bmScriptOptionsDictionary.m
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
@protocol BMScriptDelegateProtocol <NSObject>
@optional
/*!
 * If implemented, called whenever a history item is about to be added to the history. 
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 *
 * @param historyItem a history item is an NSArray with two entries: the script and the result when that script was executed.
 */
- (BOOL) shouldAddItemToHistory:(NSArray *)historyItem;
/*!
 * If implemented, called whenever a history item is about to be returned from the history.
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 *
 * @param historyItem a history item is an NSArray with two entries: the script and the result when that script was executed.
 */
- (BOOL) shouldReturnItemFromHistory:(NSArray *)historyItem;
/*!
 * If implemented, called whenever BMScript.result is about to change.
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 *
 * @param data the data that will be used as new value if this method returns YES.
 */
- (BOOL) shouldSetResult:(NSData *)data;
/*!
 * If implemented, called during execution in background (non-blocking) whenever new data is available.
 * Delegation methods beginning with <i>should</i> give the delegate the power to abort the operation by returning NO. 
 * @param data the data that will be used as new value if this method returns YES.
 */
- (BOOL) shouldAppendPartialResult:(NSData *)data;
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
 * @param anItem the history item that will be added
 */
- (NSArray *) willAddItemToHistory:(NSArray *)anItem;
/*!
 * If implemented, called before right before an item is finally returned from the history. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param anItem the history item that will be returned
 */
- (NSArray *) willReturnItemFromHistory:(NSArray *)anItem;
/*!
 * If implemented, called before right before a string is appended to BMScript.partialResult. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param data the data that will be appended
 */
- (NSData *) willAppendPartialResult:(NSData *)data;
/*!
 * If implemented, called before right before BMScript.result is set to a new value. 
 * Delegation methods beginning with <i>will</i> give the delegate the power to change the value that will be used for the set/get operation by mutating the value passed in. 
 * @param data the data that will be used as result
 */
- (NSData *) willSetResult:(NSData *)data;
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
@interface BMScript : NSObject <NSCoding, NSCopying, BMScriptDelegateProtocol> {
 @protected
    NSString * source;
    NSDictionary * options;
    id<BMScriptDelegateProtocol> delegate;
 @private
    NSData * result;
    NSMutableData * partialResult;
    BOOL isTemplate;
    NSMutableArray * _history;
    NSTask * task;
    NSPipe * pipe;
    NSTask * bgTask;
    NSPipe * bgPipe;
    NSInteger returnValue;
}

// Doxygen seems to "swallow" the first property item and not generate any documentation for it
// even if we put a proper documentation comment in front of it. It is unclear if that is the case
// only for this particular file or if there is a bug that globally causes it. As a workaround
// we take one of the hidden properties and put it up front to be swallowed since we don't want it
// to appear in the docs anyway.
//@property (BM_ATOMIC readonly, copy) NSArray * history;


/*! Gets or sets the script source to execute. It's safe to change the script source after a preceeding execution. */
@property (BM_ATOMIC copy) NSString * source;
/*! 
 * Gets or sets (task) options for the command line tool used to execute the script. 
 * The options consist of a dictionary with two keys:
 * - #BMScriptOptionsTaskLaunchPathKey which is used to set the path to the executable of the tool, and
 * - #BMScriptOptionsTaskArgumentsKey an NSArray of strings to supply as the arguments to the tool
 * 
 * <div class="box important">
        <div class="table">
            <div class="row">
                <div class="label cell">Important:</div>
                <div class="message cell">
                    <b>DO NOT</b> supply the script source as part of the task arguments, as it 
                    will be added later by the class. If you add the script source directly with
                    the task arguments you rob the delegate of a chance to review the script and
                    change it or abort in case of problems.
                </div>
            </div>
        </div>
 * </div>
 *
 * @sa #BMSynthesizeOptions(path, args) 
 */
@property (BM_ATOMIC retain) NSDictionary * options;
/*! 
 * Gets and sets the delegate for BMScript. It is not enforced that the object passed to the accessor conforms 
 * to the BMScriptLanguageProtocol. A compiler warning however should be issued. 
 */
@property (BM_ATOMIC assign) id<BMScriptDelegateProtocol> delegate;

/** 
 * Gets the last execution result (getter=<b>lastResult</b>). 
 * May return nil if the script hasn't been executed yet.
 */
@property (BM_ATOMIC copy, readonly, getter=lastResult) NSData * result;

// MARK: Initializer Methods


/*!
 * Initialize a new BMScript instance. If no options are specified and the class is a descendant of BMScript it will call the class' 
 * implementations of BMScriptLanguageProtocol-p.defaultOptionsForLanguage and, if implemented, BMScriptLanguageProtocol-p.defaultScriptSourceForLanguage.
 * BMScript (meta) on the other hand defaults to <span class="sourcecode">\@&quot;/bin/echo&quot;</span> and <span class="sourcecode">\@&quot;&lt;script source placeholder&gt;&quot;</span>.
 */
- (id) init;
/*!
 * Initialize a new BMScript instance with a script source. This is the designated initializer.
 * @throw BMScriptLanguageProtocolDoesNotConformException thrown when a subclass of BMScript does not conform to the BMScriptLanguageProtocol
 * @throw BMScriptLanguageProtocolMethodMissingException thrown when a subclass of BMScript does not implement all required methods of the BMScriptLanguageProtocol
 * @param scriptSource a string containing commands to execute
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithScriptSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;     /* designated initializer */
/*!
 * Initialize a new BMScript instance with a template source. 
 * A template needs to be saturated before it can be used. 
 * @param templateSource a string containing a template with magic tokens to saturate resulting in commands to execute.
 * @param scriptOptions a dictionary containing the task options
 * @see saturateTemplateWithArgument: and variants.
 */
- (id) initWithTemplateSource:(NSString *)templateSource options:(NSDictionary *)scriptOptions;
/*!
 * Initialize a new BMScript instance. 
 * <div class="box important">
        <div class="table">
            <div class="row">
                <div class="label cell">Important:</div>
                <div class="message cell">
                    All BMScript creation methods that take content from files expect the file to have UTF-8 string encoding!
                </div>
            </div>
        </div>
 * </div>
 * @param path a string pointing to a file on disk. The contents of this file will be used as source script.
 * @param scriptOptions a dictionary containing the task options
 */
- (id) initWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
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
+ (id) scriptWithSource:(NSString *)scriptSource options:(NSDictionary *)scriptOptions;
/*!
 * Returns an autoreleased instance of BMScript.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfFile:(NSString *)path options:(NSDictionary *)scriptOptions;
/*!
 * Returns an autoreleased instance of BMScript. 
 * 
 * If you use this method you need to saturate the script template with values in order to 
 * turn it into an executable script source.
 *
 * @see #saturateTemplateWithArgument: at al.
 * @see #initWithScriptSource:options: et al.
 */
+ (id) scriptWithContentsOfTemplateFile:(NSString *)path options:(NSDictionary *)scriptOptions;


// MARK: Execution


/*!
 * Executes the script with a synchroneous (blocking) task. To get the result call BMScript.lastResult.
 * @note the blocking task is allowed a maximum of 10 seconds to execute and finish before being interrupted.
 * If you need longer time periods use the non-blocking execution model (e.g. #executeInBackgroundAndNotify).
 * @throws BMScriptTemplateArgumentMissingException thrown when the BMScript instance was initialized with a template which hasn't been saturated prior to execution
 * @returns the script's execution status
 * @see ExecutionStatus
 */
- (ExecutionStatus) execute;
/*!
 * Executes the script with a synchroneous (blocking) task and stores the result in &results.
 * If the BMScript instance was initialized with a template, the template must first be saturated
 * before the BMScript instance can be executed.
 * @note the blocking task is allowed a maximum of 10 seconds to execute and finish before being interrupted.
 * If you need longer time periods use the non-blocking execution model (e.g. #executeInBackgroundAndNotify).
 * @param results a pointer to an NSData where the result should be written to
 * @throws BMScriptTemplateArgumentMissingException thrown when the BMScript instance was initialized with a template which hasn't been saturated prior to execution
 * @returns the script's execution status 
 * @see ExecutionStatus
 */
- (ExecutionStatus) executeAndReturnResult:(NSData **)results;
/*!
 * Executes the script with a synchroneous (blocking) task and stores the result in the string pointed to by results.
 * @note the blocking task is allowed a maximum of 10 seconds to execute and finish before being interrupted.
 * If you need longer time periods use the non-blocking execution model (e.g. #executeInBackgroundAndNotify).
 * @param results a pointer to an NSData where the result should be written to
 * @param error a pointer to an NSError where errors should be written to
 * @throws BMScriptTemplateArgumentMissingException thrown when the BMScript instance was initialized with a template which hasn't been saturated prior to execution
 * @returns the script's execution status
 * @see ExecutionStatus
 */
- (ExecutionStatus) executeAndReturnResult:(NSData **)results error:(NSError **)error;
/*!
 * Executes the script with a asynchroneous (non-blocking) task. 
 * The script's execution status, results (string) and the task's return value will be posted with a notifcation.
 * @throws BMScriptTemplateArgumentMissingException thrown when the BMScript instance was initialized with a template which hasn't been saturated prior to execution
 * @see @link NonBlockingExecutionExample.m @endlink
 * @sa BMScriptNotificationExecutionStatus, BMScriptNotificationTaskReturnValue, BMScriptNotificationTaskResults
 */
- (void) executeInBackgroundAndNotify; 

// MARK: Virtual (Readonly) Getters

/*!
 * Returns an immutable copy of the receiver's instance local execution cache (aka its history).
 * @returns an NSArray copied from the local execution history.
 */
- (NSArray *) history;

/*!
 * Returns the value returned by the last execution of the underlying NSTask. 
 * Can be used to compare to expected return codes from various UNIX™ tools.
 * This has to be exposed to the user of the class since there is no universally 
 * agreed to meaning to return codes. Mostly its 0 for successful execution and
 * 1 for faulty execution. Apart from this, each tool defines their own code ranges.
 * @returns return code from the underlying NSTask as NSInteger or #BMScriptNotExecuted if the script wasn't executed yet. 
 */
- (NSInteger) lastReturnValue;


// MARK: Templates


/*!
 * Replaces a single <##> construct in the template.
 * @param tArg the value that should be inserted
 * @returns YES if the replacement was successful, NO on error
 */
- (BOOL) saturateTemplateWithArgument:(NSString *)tArg;
/*!
 * Replaces multiple <##> constructs in the template in the order of occurrence.
 * @param firstArg the first value which should be inserted
 * @param ... the remaining values to be inserted in order of occurrence
 * @returns YES if the replacements were successful, NO on error
 */
- (BOOL) saturateTemplateWithArguments:(NSString *)firstArg, ...;
/*!
 * Replaces multiple <span class="sourcecode">&lt;\#KEY\#&gt;</span> constructs in the template. 
 * The <span class="sourcecode">KEY</span> phrase is a variant and describes the name of a key in the dictionary passed to this method.<br/>
 * If the key is found in the dictionary its corresponding value will be used to replace the magic token in the template.
 * @param dictionary a dictionary with keys and their values which should be inserted
 * @returns YES if the replacements were successful, NO on error
 */
- (BOOL) saturateTemplateWithDictionary:(NSDictionary *)dictionary;

// MARK: History

/*!
 * Returns a cached script source from the history. 
 * @param index index of the item to return. May return nil if the history does not contain any objects.
 */
- (NSString *) scriptSourceFromHistoryAtIndex:(NSUInteger)index;
/*!
 * Returns a cached result from the history. 
 * @param index index of the item to return. May return nil if the history does not contain any objects.
 */
- (NSData *) resultFromHistoryAtIndex:(NSUInteger)index;
/*!
 * Returns the last cached script source from the history. 
 * May return nil if the history does not contain any objects.
 */
- (NSString *) lastScriptSourceFromHistory;
/*!
 * Returns the last cached result from the history. 
 * May return nil if the history does not contain any objects.
 */
- (NSData *) lastResultFromHistory;

// MARK: Equality

/*!
 * Returns YES if the source script and launch path are equal.
 */
- (BOOL) isEqual:(BMScript *)other;
/*!
 * Returns YES if both script sources are equal.
 */
- (BOOL) isEqualToScript:(BMScript *)other;

@end



/*!
 * @category BMScript(CommonScriptLanguagesFactories)
 * A category on BMScript adding default factory methods for Ruby, Python and Perl.
 * The task options use default paths (for 10.5 and 10.6) for the task launch path.
 */
@interface BMScript(CommonScriptLanguagesFactories)
/*!
 * Returns an autoreleased Ruby script ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) rubyScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Ruby script from a file ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a file containing the commands to execute.
 */
+ (id) rubyScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Ruby script template ready for saturation.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Returns an autoreleased Python script ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) pythonScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Python script from a file ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a file containing the commands to execute.
 */
+ (id) pythonScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Python script template ready for saturation.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Returns an autoreleased Perl script ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) perlScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Perl script from a file ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a file containing the commands to execute.
 */
+ (id) perlScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Perl script template ready for saturation.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path;
/*!
 * Returns an autoreleased Shell script ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param scriptSource the script source containing the commands to execute.
 */
+ (id) shellScriptWithSource:(NSString *)scriptSource;
/*!
 * Returns an autoreleased Shell script from a file ready for execution.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a file containing the commands to execute.
 */
+ (id) shellScriptWithContentsOfFile:(NSString *)path;
/*!
 * Returns an autoreleased Shell script template ready for saturation.
 * @note Expects the file contents to be in UTF-8 encoding! 
 * @param path path to a template file containing the tokens to replace.
 */
+ (id) shellScriptWithContentsOfTemplateFile:(NSString *)path;
@end

/*! 
 * @category NSString(BMScriptStringUtilities)
 * A category on NSString providing some handy utility functions for end user display of strings. 
 */
@interface NSString (BMScriptStringUtilities)

/*!
 * Defines a specific type of NSArray used for mapping target characters (which should be escaped) to their replacement counterparts.
 * If you choose to make your own mappings, you need to adhere to a specific format: an NSArray containing 2-part NSArrays, which contain 
 * (<span class="sourcecode">objectAtIndex:0</span>) the target string and
 * (<span class="sourcecode">objectAtIndex:1</span>) the replacement string.
 * @sa BMNSStringC99EscapeCharacterMapping
 * @sa BMNSStringCommonEscapeCharacterMapping
 */
typedef NSArray BMNSStringEscapeCharacterMapping;

/*! 
 * ￼Defines an escape character mapping that includes almost all of standard C99's escape sequences minus di- and trigraphs, hexadecimal, octal and unicode literal notations. 
 * This is because in order to use those notations in an NSString you need to escape them anyway, which means replacements made with targeting the 
 * escape character itself (backslash) will also add another level of escaping to these notations. This is the default mapping used internally by <span class="sourcecode">escapedString</span>, 
 * <span class="sourcecode">unescapedStringUsingOrder</span>, <span class="sourcecode">stringByEscapingStringUsingOrder:</span> and <span class="sourcecode">stringByEscapingStringUsingMapping:order:</span>. 
 * This mapping was put in the public header file to make it easier to infer the format needed for constructing new <span class="sourcecode">BMNSStringEscapeCharacterMapping</span> instances 
 * which can be passed to <span class="sourcecode">stringByEscapingStringUsingMapping:order:</span>  
 * <div class="box important">
        <div class="table">
            <div class="row">
                <div class="label cell">Note:</div>
                <div class="message cell">
                As you may have noticed by the inclusion of the <span class="sourcecode">order</span> paramater for several escaping methods, depending on the mapping, the order in which the mapping is traversed (and thus affecting how replacements are made) does matter.
                The index of the escape character used by NSString literals (backslash) in the mapping also matters since it may happen that already escaped characters will be escaped again.
                </div>
            </div>
        </div>
 * </div>
 * @sa BMNSStringCommonEscapeCharacterMapping
 */
#define BMNSStringC99EscapeCharacterMapping  [NSArray arrayWithObjects:                         \
                                                [NSArray arrayWithObjects:@"\\", @"\\\\", nil], \
                                                [NSArray arrayWithObjects:@"\n", @"\\n", nil],  \
                                                [NSArray arrayWithObjects:@"\r", @"\\r", nil],  \
                                                [NSArray arrayWithObjects:@"\t", @"\\t", nil],  \
                                                [NSArray arrayWithObjects:@"\f", @"\\f", nil],  \
                                                [NSArray arrayWithObjects:@"\a", @"\\a", nil],  \
                                                [NSArray arrayWithObjects:@"\v", @"\\v", nil],  \
                                                [NSArray arrayWithObjects:@"\b", @"\\b", nil],  \
                                                [NSArray arrayWithObjects:@"\"", @"\\\"", nil], \
                                             nil]
/*! 
 * ￼Defines an escape character mapping that includes the most common escapable characters for an NSString. This mapping is used internally by <span class="sourcecode">quotedString</span> and <span class="sourcecode">unquotedString</span>.
 * It was put in the public header file to make it easier to infer the format needed for constructing new <span class="sourcecode">BMNSStringEscapeCharacterMapping</span> instances which can be passed to <span class="sourcecode">stringByEscapingStringUsingMapping:order:</span>.
 * Contrary to #BMNSStringC99EscapeCharacterMapping the order here is not as important since <span class="sourcecode">quotedString</span> traverses the mapping in first order.
 * @sa BMNSStringC99EscapeCharacterMapping
 */
#define BMNSStringCommonEscapeCharacterMapping [NSArray arrayWithObjects:                         \
                                                  [NSArray arrayWithObjects:@"\\", @"\\\\", nil], \
                                                  [NSArray arrayWithObjects:@"\n", @"\\n", nil],  \
                                                  [NSArray arrayWithObjects:@"\r", @"\\r", nil],  \
                                                  [NSArray arrayWithObjects:@"\t", @"\\t", nil],  \
                                                  [NSArray arrayWithObjects:@"\"", @"\\\"", nil], \
                                               nil]

/*! String truncation modes￼￼ */
typedef enum {
    /*! &lt;string_start&gt;…&lt;string_end&gt;. */
    BMNSStringTruncateModeCenter = 0,
    /*! …&lt;string_end&gt;. */
    BMNSStringTruncateModeStart = 1,
    /*! &lt;string_start&gt;…*/
    BMNSStringTruncateModeEnd = 2
} BMNSStringTruncateMode;

/*!
 * ￼String escaping modes￼￼. Since we are replacing all occurences of an escapable character at once, the order in which the replacements occur is important.
 */
typedef enum {
    /*! Traverses the character mapping from bottom up (starting at <span class="sourcecode">objectAtIndex:0</span>). This is the order used by #quotedString. */
    BMNSStringEscapeTraversingOrderFirst = 0,
    /*! Traverses the character mapping from top down (starting at <span class="sourcecode">objectAtIndex:[mapping count]</span>). Reversing the order can at rare times be useful when the escape character mapping includes replacements for the escape character itself which is also included by all the other replacements in the mapping. In that case the output depends on the traversing order. Typically though, there is not much incentive to use a reverse order. */
    BMNSStringEscapeTraversingOrderLast = 1
} BMNSStringEscapeTraversingOrder;

/*!
 * Escapes all occurrences according to the specified escape character mapping. If nil is passed for the mapping, by default #BMNSStringC99EscapeCharacterMapping is used as the mapping. 
 * The C99 mapping currently includes \\a (alert), \\b (backspace), \\f (form feed), \\n (newline), \\r (return), \\t (tab), \\v (vertical tab), \" (double quote) and \\ (backslash). 
 * The remaining sequences such as hexadecimal, octal and unicode notations need to be specified already escaped anyway when constructing the script source via NSStrings. 
 * Those sequences will then be escaped when the default escape character is transformed (the default escape character is the backslash character). If you read script sources from file, 
 * depending on the behaviour of NSString in how it treats escaped sequences when reading the file data in, you may have to specifically escape any unicode literals yourself. 
 * You can use #stringByEscapingUnicodeCharacters for this.
 * 
 * <i>Implementation note: before thinking about escape sequences and how to do the replacements some thought needs to be put in about what even needs escaping.
 * By this I do not mean what parts of a string do need escaping, but rather the angle we are coming from. i.e.: when utilizing Ruby scripts 
 * do we need to follow the conventions of the Ruby language for what needs escaping? My first instinct told me yes, but I have thought 
 * long and hard about this: actually the carrier for transporting those scripts sources around is after all an NSString. 
 * So regardless of what language we use for our sources, when feeding the script sources into Objective-C land we need to escape all entities 
 * that need escaping in an NSString literal. However, while the assumption may be correct, it is also somewhat of a moot point since any and all 
 * modern interpreted languages follow the C style for escape sequences anyway, as does Objective-C.</i>
 *
 * @param   mapping   a #BMNSStringEscapeCharacterMapping value which specifies the mapping of escapable characters to their escaped counterparts.
 * @param   order     a #BMNSStringEscapeTraversingOrder value which specifies the order in which the escape character mapping should be traversed: first (normal) or last (reverse).
 * @returns  the escaped string
 * @sa #quotedString
 */ 
- (NSString *) stringByEscapingStringUsingMapping:(BMNSStringEscapeCharacterMapping *)mapping order:(BMNSStringEscapeTraversingOrder)order;

/*! 
 * Calls #stringByEscapingStringUsingMapping:order: passing nil for mapping (and obviously <span class="sourcecode">order</span> for <span class="sourcecode">order</span>). 
 * If nil is passed for the <span class="sourcecode">mapping</span> parameter, #BMNSStringC99EscapeCharacterMapping is used by default. 
 * @sa #stringByEscapingStringUsingMapping:order:
 */
- (NSString *) stringByEscapingStringUsingOrder:(BMNSStringEscapeTraversingOrder)order;

/*!
 * Escapes all <span class="sourcecode">unichar</span> characters with their representation in \\uxxxx notation. 
 * For example: é becomes \\u00e9. Can be used to escape unichars in script sources read from file.
 * Note: The need for this depends on the behaviour of NSString when reading in the file.
 */
- (NSString *) stringByEscapingUnicodeCharacters;
/*! 
 * Replaces all % signs with %%. 
 * This would be useful if you want to use a string as a format string for one of the NSString creation methods. 
 */
- (NSString *) stringByEscapingPercentSigns;
/*! 
 * Replaces all %% signs with %. 
 * The reverse of <span class="sourcecode">stringByEscapingPercentSigns</span>. 
 */
- (NSString *) stringByUnescapingPercentSigns;
/*! 
 * Swallows multiple consecutive percent signs and replaces each multi-occurrence with one sign.
 * Can be useful if, again, the need arises to use it as an NSString format or argument string. 
 */
- (NSString *) stringByNormalizingPercentSigns;
/*! 
 * A convenience method for stripping off a trailing newline character.
 * The method checks if the last character actually is a new line character (<span class="sourcecode">\\n</span> or <span class="sourcecode">\\r</span>, 
 * but not <span class="sourcecode">\\r\\n</span>!) and either modifies it to strip the new line character or it doesn't if there is no new line character.
 * @returns string with newline character chopped of or unmodified string if string doesn't end with newline (\\n or \\r) character.
 */
- (NSString *) chomp;
/*! 
 * Calls #stringByEscapingStringUsingOrder: passing #BMNSStringEscapeTraversingOrderFirst as <span class="sourcecode">order</span> argument. 
 */
- (NSString *) escapedString;
/*! 
 * Loops through #BMNSStringC99EscapeCharacterMapping performing the same operation as #escapedString while switching <span class="sourcecode">objectAtIndex:</span>(0) with (1) thus reversing the escaping replacements.
 */
- (NSString *) unescapedStringUsingOrder:(BMNSStringEscapeTraversingOrder)order;
/*!
 * Escapes a small subset of the C standard escape sequence set, specifically \\ (backslash), \\n (newline), \\r (return) and \" (double quotes), in that order.
 * This is the little brother of #stringByEscapingStringUsingOrder: and most of the time sufficient for day-to-day work with script sources supplied in NSStrings.
 * @returns the quoted string
 * @sa #stringByEscapingStringUsingOrder:
 */ 
- (NSString *) quotedString;
/*! 
 * Loops through #BMNSStringCommonEscapeCharacterMapping performing the same operation as #quotedString while switching <span class="sourcecode">objectAtIndex:</span>(0) with (1) thus reversing the escaping replacements.
 */
- (NSString *) unquotedString;
/*!
 * Truncates a string to 20 characters (by default) and adds a horizontal ellipsis … (U+2026) character.
 * @returns the truncated string
 * @sa stringByTruncatingToLength:
 */ 
- (NSString *) truncatedString;
/*! 
 * Truncates a string to len characters plus horizontal ellipsis.
 * @param len new length. ellipsis will be added.
 * @returns the truncated string
 * @sa stringByTruncatingToLength:mode:indicator:
 */ 
- (NSString *) stringByTruncatingToLength:(NSUInteger)len;
/*! 
 * Truncates a string to length characters while giving control over where the
 * indicator should appear: start, middle or end.
 * The indicator itself is also specifyable.
 * @param length            new length including ellipsis.
 * @param mode              the truncate mode. start, center or end.
 * @param indicatorString   the indicator string (typically an ellipsis sysmbol, if nil an NSString containing 3 periods will be used)
 * @returns the truncated string
 */ 
- (NSString *) stringByTruncatingToLength:(NSUInteger)length mode:(BMNSStringTruncateMode)mode indicator:(NSString *)indicatorString;
/*!
 * Counts the number of occurrences of a string in another string 
 * @param aString the string to count occurrences of
 * @returns NSInteger with the amount of occurrences
 */
- (NSInteger) countOccurrencesOfString:(NSString *)aString;
/*!
 * Returns a string wrapped in single quotes. 
 */
- (NSString *) stringByWrappingSingleQuotes;
/*!
 * Returns a string wrapped in double quotes. 
 */
- (NSString *) stringByWrappingDoubleQuotes;
/*! 
 * Returns an array of strings representing the reciever's bytes in hexadecimal or decimal notation. 
 * Uses getBytes:maxLength:usedLength:encoding:options:range:remainingRange: with option NSStringEncodingConversionExternalRepresentation to get the BOM included (if needed).
 * See NSString.h for more details.
 * @param enc Usually you want NSUTF8StringEncoding but if you're interested in the BOM pass NSUnicodeStringEncoding or NSUTF16StringEncoding (which is an alias for the former)
 * @param asHex specify YES if for example you want "0x42" for 'A' ("65" if NO)
 */
- (NSArray *) bytesForEncoding:(NSStringEncoding)enc asHex:(BOOL)asHex;
/*!
 * From the String Programming Guide. Adjusts a range so that it includes composed grapheme clusters at the range's boundaries. 
 * Needed for any UTF/Unicode string.
 * @param aRange an arbitrary NSRange on a string, captured without consideration of grapheme clusters.
 * @returns the adjusted range, now including composed character sequences at the beginning and end of the range.
 */
- (NSRange) adjustRangeToIncludeComposedCharacterSequencesForRange:(NSRange)aRange;
@end

/*! 
 * @category NSDictionary(BMScriptUtilities)
 * A category on NSDictionary providing handy utility and convenience functions. 
 */
@interface NSDictionary (BMScriptUtilities)
/*!
 * Returns a new dictionary by adding another object. 
 * @param object the object to add
 * @param key the key to add it for
 * @returns the modified dictionary
 */
- (NSDictionary *) dictionaryByAddingObject:(id)object forKey:(id)key;
@end

/*! 
 * @category NSObject(BMScriptUtilities)
 * A category on NSObject. Provides introspection and other utility methods. 
 */
@interface NSObject (BMScriptUtilities)

/*!
 * Returns YES if self is a descendant (and only a descendant) of another class.
 *
 * This differs from <span class="sourcecode">-[NSObject isMemberOfClass:someClass]</span> 
 * and <span class="sourcecode">-[NSObject isKindOfClass:someClass]</span> in that it
 * excludes anotherClass (the parent) in the comparison. Normally -isKindOfClass: returns 
 * YES for all instances, and -isMemberOfClass: for all instances plus inherited subclasses,
 * both including their parent class anotherClass. Here we return NO if <span class="sourcecode">[self class]</span>
 * is equal to <span class="sourcecode">[anotherClass class]</span>.
 *
 * @param anotherClass the class type to check against
 */
- (BOOL) isDescendantOfClass:(Class)anotherClass;

@end

/*! 
 * @category NSArray(BMScriptUtilities)
 * A category on NSArray. Provides introspection and other utility methods. 
 */
@interface NSArray (BMScriptUtilities)
/*! Returny YES if the array consists only of empty strings. */
- (BOOL) isEmptyStringArray;
/*! Returns YES if the array was created with no objects. <span class="sourcecode">[NSArray arrayWithObjects:nil]</span> for example can do this. */
- (BOOL) isZeroArray;
@end


/*!
 * @category NSData(BMScriptUtilities)
 * A category on NSData. Provides introspection and other utility methods.
 */
@interface NSData (BMScriptUtilities)
/*! 
 * Provides a way of logging data returned by a script's underlying task in a human-readable format. 
 * @note This method is intended strictly for logging purposes! If you need to convert the data to a 
 * string, use the proper NSString API and provide the correct string encoding.
 * @returns contents as string, if the data can be converted using NSUTF8StringEncoding. 
 * Otherwise returns string from <span class="sourcecode">[self description]</span>.
 */
- (NSString *) contentsAsString;
@end


