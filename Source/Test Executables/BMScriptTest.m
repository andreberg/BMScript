//
//  BMScriptTest.m
//  BMScriptTest
//
//  Created by Andre Berg on 29.09.09.
//  Copyright 2008 Berg Media. All rights reserved.
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

//#define BMSCRIPT_THREAD_AWARE

#import <Foundation/Foundation.h>

#import "BMDefines.h"
#import "BMScript.h"
#import "BMRubyScript.h"
#import "ScriptRunner.h"

#include <unistd.h>
#include <sys/param.h>
#include <objc/objc-auto.h>


#if (DEBUG && (!defined(NS_BLOCK_ASSERTIONS) && !defined(BM_BLOCK_ASSERTIONS)))
    #define BMAssertLog(_COND_) if (!(_COND_)) \
        NSLog(@"*** AssertionFailure: %s should be YES but is %@", #_COND_, ((_COND_) ? @"YES" : @"NO"))
    #define BMAssertThrow(_COND_, _DESC_) if (!(_COND_)) \
        @throw [NSException exceptionWithName:@"*** AssertionFailure" reason:[NSString stringWithFormat:@"%s should be YES but is %@", #_COND_, (_DESC_)] userInfo:nil]
#else
    #define BMAssertLog(_COND_)
    #define BMAssertThrow(_COND_, _DESC_)
    #define NS_BLOCK_ASSERTIONS 1
#endif

#ifdef PATHFOR
    #define OLD_PATHFOR PATHFOR
    #undef PATHFOR
#endif
#define PATHFORTEMPLATE(_NAME_) ([[[[[NSString stringWithUTF8String:(__FILE__)]                                 \
                                        stringByDeletingLastPathComponent]                                      \
                                            stringByAppendingFormat:@"/../../Unit Tests/Resources/Templates"]   \
                                                stringByStandardizingPath]                                      \
                                                   stringByAppendingPathComponent:(_NAME_)])

#define PATHFORSCRIPT(_NAME_) ([[[[[NSString stringWithUTF8String:(__FILE__)]                              \
                                      stringByDeletingLastPathComponent]                                   \
                                          stringByAppendingFormat:@"/../../Unit Tests/Resources/Scripts"]  \
                                              stringByStandardizingPath]                                   \
                                                  stringByAppendingPathComponent:(_NAME_)])



#define RUBY19_EXE_PATH @"/usr/local/bin/ruby1.9"


// ---------------------------------------------------------------------------------------- 
// MARK: main
// ---------------------------------------------------------------------------------------- 

int main (int argc, const char * argv[]) {
    #pragma unused(argc, argv)
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 

    NSLog(@"NOTE: To get the complete output you need to look at Console.app since for BMScript instances using /bin/sh");
    NSLog(@"redirecting their underlying task's standard out to the pipe created within seems to overwrite Xcode's debugger console output.");
    NSLog(@"However, it should all be there in the system console. I'd be interested in a way around that.");
     
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 

    #ifdef ENABLE_MACOSX_GARBAGE_COLLECTION
        objc_startCollectorThread();
        NSLog(@"ENABLE_MACOSX_GARBAGE_COLLECTION = YES");
    #endif
    
    NSLog(@"MAC_OS_X_VERSION_MIN_REQUIRED = %i", MAC_OS_X_VERSION_MIN_REQUIRED);
    NSLog(@"MAC_OS_X_VERSION_MAX_ALLOWED = %i", MAC_OS_X_VERSION_MAX_ALLOWED);
    NSLog(@"BMSCRIPT_THREAD_AWARE = %i", BMSCRIPT_THREAD_AWARE);
    NSLog(@"BMSCRIPT_FAST_LOCK = %i", BMSCRIPT_FAST_LOCK);
    NSLog(@"GarbageCollector enabled? %@", BMNSStringFromBOOL([[NSGarbageCollector defaultCollector] isEnabled]));
    
    BOOL success = NO;
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 

    BMRubyScript * script2 = [[BMRubyScript alloc] initWithScriptSource:@"puts 1+2" options:nil];

    NSLog(@"Test non-blocking execution through ScriptRunner");
    
    ScriptRunner * sr1 = [[ScriptRunner alloc] init];
    ScriptRunner * sr2 = [[ScriptRunner alloc] initWithExecutionMode:SRNonBlockingExecutionMode];
    [sr1 run];
    [sr2 run];

    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 

    NSLog(@"Test Protocol conformance");
    
    // test BMScriptLanguageProtocol conformance
    BOOL respondsToDefaultOpts                  = [script2 respondsToSelector:@selector(defaultOptionsForLanguage)];
    BOOL respondsToDefaultScript                = [script2 respondsToSelector:@selector(defaultScriptSourceForLanguage)];

    // test BMScriptDelegateProtocol conformance
    BOOL respondsToShouldSetScript              = [sr1 respondsToSelector:@selector(shouldSetScript:)];
    BOOL respondsToShouldLastResult             = [sr1 respondsToSelector:@selector(shouldSetResult:)];
    BOOL respondsToShouldAddItemToHistory       = [sr1 respondsToSelector:@selector(shouldAddItemToHistory:)];
    BOOL respondsToShouldReturnItemFromHistory  = [sr1 respondsToSelector:@selector(shouldReturnItemFromHistory:)];
    BOOL respondsToShouldAppendPartialResult    = [sr1 respondsToSelector:@selector(shouldAppendPartialResult:)];
    BOOL respondsToShouldSetOptions             = [sr1 respondsToSelector:@selector(shouldSetOptions:)];
    
    NSLog(@"ScriptRunner conforms to BMScriptLanguageProtocol? %@", BMNSStringFromBOOL([ScriptRunner conformsToProtocol:@protocol(BMScriptLanguageProtocol)]));
    NSLog(@"BMRubyScript conforms to BMScriptLanguageProtocol? %@", BMNSStringFromBOOL([script2 conformsToProtocol:@protocol(BMScriptLanguageProtocol)]));
    NSLog(@"BMRubyScript implements required methods for %@? %@", @"BMScriptLanguageProtocol", BMNSStringFromBOOL(respondsToDefaultOpts));
    NSLog(@"BMRubyScript implements all methods for %@? %@", @"BMScriptLanguageProtocol", BMNSStringFromBOOL(respondsToDefaultOpts && respondsToDefaultScript));

    NSLog(@"ScriptRunner conforms to BMScriptDelegateProtocol? %@", BMNSStringFromBOOL([ScriptRunner conformsToProtocol:@protocol(BMScriptDelegateProtocol)]));
    NSLog(@"ScriptRunner implements some methods for %@? %@", @"BMScriptLanguageProtocol", 
          BMNSStringFromBOOL(respondsToShouldSetScript 
                           || respondsToShouldLastResult 
                           || respondsToShouldAddItemToHistory 
                           || respondsToShouldReturnItemFromHistory 
                           || respondsToShouldAppendPartialResult 
                           || respondsToShouldSetOptions));
    NSLog(@"ScriptRunner implements all methods for %@? %@", @"BMScriptLanguageProtocol", 
          BMNSStringFromBOOL(respondsToShouldSetScript 
                           && respondsToShouldLastResult 
                           && respondsToShouldAddItemToHistory 
                           && respondsToShouldReturnItemFromHistory 
                           && respondsToShouldAppendPartialResult 
                           && respondsToShouldSetOptions));
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test BMScript alloc init");
    
    NSError * error = nil;
    ExecutionStatus status = BMScriptNotExecuted;

    BMScript * script1 = [[BMScript alloc] init];
    [script1 execute];

    NSString * result1 = [[script1 lastResult] contentsAsString];
    NSLog(@"script1 (alloc init) result = %@", result1);
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test BMRubyScript subclass");
    
    NSData * result2;
    success = [script2 executeAndReturnResult:&result2];
   
    if (success == BMScriptFinishedSuccessfully) {
        NSLog(@"script2 (BMRubyScript 'puts 1+2') result = %@", [result2 contentsAsString]);
    };
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:RUBY19_EXE_PATH]) {
        
        NSLog(@"Test changing the script source after execution and re-executing");
        
        NSArray * newArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
        NSDictionary * newOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                            RUBY19_EXE_PATH, BMScriptOptionsTaskLaunchPathKey, 
                                                    newArgs, BMScriptOptionsTaskArgumentsKey, nil];
        
        NSData * newResult1 = nil;
        
        [script1 setSource:@"puts \"newScript1 executed\\n ...again with \\\"ruby 1.9\\\"!\""];
        [script1 setOptions:newOptions];
        status = [script1 executeAndReturnResult:&newResult1 error:&error];
        
        if (status == BMScriptFinishedSuccessfully) {
            NSLog(@"script1 new result (unquoted) = %@ (%@)", [[newResult1 contentsAsString] quotedString], [newResult1 contentsAsString]);
        } else {
            NSLog(@"script1 status = %d", status);
        }
    } else {
        NSLog(@"Skipping Ruby 1.9 based test, because ruby1.9 was not found at path: '%@'", RUBY19_EXE_PATH);
    }
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test Convert to Oct.rb and Convert To Hex Template.rb");
    
    NSString * path = PATHFORTEMPLATE(@"Convert To Oct.rb");
    
    BMRubyScript * script3 = [BMRubyScript scriptWithContentsOfTemplateFile:path options:nil];
    [script3 saturateTemplateWithArgument:@"100"];
    [script3 execute];
    
    NSLog(@"script3 (convert '100' to octal) result = %@", [[script3 lastResult] contentsAsString]);
    
    path = PATHFORTEMPLATE(@"Convert To Hex Template.rb");
    
    BMRubyScript * script9 = [BMRubyScript scriptWithContentsOfTemplateFile:path options:nil];
    [script9 saturateTemplateWithArgument:[NSString stringWithFormat:@"%li", NSIntegerMax]];
    [script9 execute];
    
    NSLog(@"script9 (convert 'NSIntegerMax' to hex) result = %@", [[script9 lastResult] contentsAsString]);
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result4 = nil;
    
    path = PATHFORTEMPLATE(@"Multiple Tokens Template.rb");
    
    BMRubyScript * script4 = [BMRubyScript scriptWithContentsOfTemplateFile:path options:nil];
    [script4 saturateTemplateWithArguments:@"template", @"1", @"tokens"];
    [script4 execute];
    
    result4 = [[script4 lastResult] contentsAsString];
    NSLog(@"script4 (sequential token template saturation) result = %@", result4);
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:RUBY19_EXE_PATH]) {
        
        NSLog(@"Test re-executing a new script with last script source from the history of another script");

        NSData * result5 = nil;
        NSData * result6 = nil;
        
        // alternative options (ruby 1.9)
        NSArray * alternativeArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
        NSDictionary * alternativeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        RUBY19_EXE_PATH, BMScriptOptionsTaskLaunchPathKey, 
                                                        alternativeArgs, BMScriptOptionsTaskArgumentsKey, nil];
            
        BMRubyScript * script5 = [BMRubyScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
        [script5 executeAndReturnResult:&result5];
            
        BMRubyScript * script6 = [BMRubyScript scriptWithSource:[script5 lastScriptSourceFromHistory] options:alternativeOptions];
        [script6 execute];
        result6 = [script6 lastResult];
        
        BMAssertLog([result5 isEqualToData:result6]);
        
        if (![result5 isEqualToData:result6]) {
            NSLog(@"*** AssertionFailure: result5 should be equal to result6!");
        }
        
        NSLog(@"script5 (alternative options) result = %@", [result5 contentsAsString]);
        NSLog(@"script6 (execute last script source from history) result = %@", [result6 contentsAsString]);
        
        BMAssertLog([[script5 history] isEqualToArray:[script6 history]]);
        if (![[script5 history] isEqualToArray:[script6 history]]) {
            NSLog(@"*** AssertionFailure: [result5 history] should be equal to [result6 history]");
        }
    } else {
        NSLog(@"Skipping Ruby 1.9 based test, because ruby1.9 was not found at path: '%@'", RUBY19_EXE_PATH);
    }
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test multiple defined and multiple define custom token templates");
    
    BMScript * script7 = [BMScript rubyScriptWithContentsOfTemplateFile:PATHFORTEMPLATE(@"Multiple Defined Tokens Template.rb")];
    
    NSDictionary * templateDict = [NSDictionary dictionaryWithObjectsAndKeys:@"template", @"TEMPLATE", @"1", @"NUM", @"tokens", @"TOKENS", nil];
    [script7 saturateTemplateWithDictionary:templateDict];
    [script7 execute];
    
    NSData * result7 = [script7 lastResult];
    
    BMAssertLog([[script4 lastResult] isEqualToData:result7]);
    
    NSLog(@"script7 (keyword args template saturation) result = %@", [result7 contentsAsString]);
    
    BMScript * script10 = [BMScript rubyScriptWithContentsOfTemplateFile:PATHFORTEMPLATE(@"Multiple Defined Custom Tokens Template.rb")];
    templateDict = [templateDict dictionaryByAddingObject:@"<%" forKey:BMScriptTemplateTokenStartKey];
    templateDict = [templateDict dictionaryByAddingObject:@"%>" forKey:BMScriptTemplateTokenEndKey];
    
    [script10 saturateTemplateWithDictionary:templateDict];
    [script10 execute];
    
    NSData * result10 = [script10 lastResult];
    
    NSLog(@"script10 (keyword args template saturation w custom tokens) result = %@", [result10 contentsAsString]);
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Results should appear with 'CHANGED' suffix as added by delegate methods");
    
    NSLog(@"ScriptRunner 1 (sr1) results = %@", [[sr1.results contentsAsString] quotedString]);
    NSLog(@"ScriptRunner 2 (sr2) results = %@", [[sr2.results contentsAsString] quotedString]);
    
    BMAssertLog([[sr1.results contentsAsString] isEqualToString:@"\"this is ScriptRunner\'s script calling...\" CHANGED"]);
    BMAssertLog([[sr2.results contentsAsString] isEqualToString:@"515377520732011331036461129765621272702107522001\n CHANGED"]);    

    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test a simple Perl script (print 2**64;)");
    
    NSData * result8 = nil;
    
    BMScript * script8 = [BMScript perlScriptWithSource:@"print 2**64;"];
    [script8 executeAndReturnResult:&result8 error:&error];
    
    BMAssertLog([[result8 contentsAsString] isEqualToString:@"1.84467440737096e+19"]);    
    NSLog(@"result8 = %@", [result8 contentsAsString]);
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test script equality");
    
    NSLog(@"The following should return NO: isEqual is only true if both scriptSource and task launchPath are equal to both instances.");
    NSLog(@"[script4 isEqual:script7]? %@", BMNSStringFromBOOL([script4 isEqual:script7]));

    NSLog(@"The following should return YES, obviously...");
    NSLog(@"[script4 isEqual:script4]? %@", BMNSStringFromBOOL([script4 isEqual:script4]));

    NSLog(@"The following should return NO: isEqualToScript is true if the scriptSource is equal to both instances.");
    NSLog(@"[script4 isEqualToScript:script7]? %@", BMNSStringFromBOOL([script4 isEqualToScript:script7]));
    
    NSLog(@"Setting script4's source equal to script7's...");
    script4.source = script7.source;
    
    NSLog(@"The following should now return YES");
    NSLog(@"[script4 isEqualToScript:script7]? %@", BMNSStringFromBOOL([script4 isEqualToScript:script4]));
    
    NSLog(@"[script4 lastResult] = %@", [[[script4 lastResult] contentsAsString] quotedString]);
    NSLog(@"[script7 lastResult] = %@", [[[script7 lastResult] contentsAsString] quotedString]);
    
    
    NSString * pathForRubyHexScript = PATHFORTEMPLATE(@"Convert To Hex Template.rb");
    
    NSString * unquotedString = [NSString stringWithContentsOfFile:pathForRubyHexScript 
                                                          encoding:NSUTF8StringEncoding 
                                                             error:&error];
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Try copying BMScript to test conformance to NSCopying. Changing the copy should not affect the source.");
    
    BMScript * script11 = [script1 copy];
    BMAssertLog([script11.source isEqualToString:script1.source]);
    BMAssertLog([script11.options isEqualToDictionary:script1.options]);
    BMAssertLog([script11 lastReturnValue] == [script1 lastReturnValue]);
    
    script11.source = @"assign a new source";
    
    BOOL isNotEqual = (![script11.source isEqualToString:script1.source ]);
    BMAssertLog(isNotEqual);
    
    if (!isNotEqual) {
        NSLog(@"Error: script1.source was also changed when changing script11.source");
    } else {
        NSLog(@"PASS: script11's changed source is different than script1.source");
    }
    
    [script11 release], script11 = nil;
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 

    NSLog(@"Test fully data based output (e.g. data that cannot be converted to string easily)");
    NSLog(@"Attempting roundtrip Base64 conversion of /System/Library/CoreServices/SystemVersion.plist");
    
    error = nil;
    
    BMScript * script12 = [BMScript shellScriptWithSource:@"cat /System/Library/CoreServices/SystemVersion.plist | openssl enc -base64"];
    status = [script12 execute];
    
    BMAssertLog(status == BMScriptFinishedSuccessfully);
    
    NSData * base64EncodedData = [script12 lastResult];
    NSString * tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"BMScriptBase64EncodingTest.txt"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:tmpFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpFile error:nil];
    }
    
    [base64EncodedData writeToFile:tmpFile options:NSAtomicWrite error:&error];
    
    script12.source = [NSString stringWithFormat:@"cat \"%@\" | openssl enc -d -base64", tmpFile];
    
    status = [script12 execute];
    
    BMAssertLog(status == BMScriptFinishedSuccessfully);
    
    NSData * base64DecodedData = [script12 lastResult];
    
    NSLog(@"script12 base64DecodedData contents = %@", [base64DecodedData contentsAsString]);

    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 

    NSLog(@"Test NSString category methods");
   
    NSLog(@"unquotedString      = '%@'", unquotedString);
    NSLog(@"quotedString        = '%@'", [unquotedString quotedString]);
    NSLog(@"escapedString first = '%@'", [unquotedString stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderFirst]);
    NSLog(@"escapedString last  = '%@'", [unquotedString stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderLast]);
    NSLog(@"truncatedString     = '%@'", [unquotedString truncatedString]);
    
    NSString * testString1 = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.    Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.";
    
    NSString * testString2 = @"This is an urgent \bbackspace \aalert that was \fform fed into a \vvertical \ttab by \rreturning a \nnew line. \"Quick!\", shouts the 'single to the \"double quote. \"Engard\u00e9!\", ye scuvvy \\backslash";
    
    NSLog(@"testString1 = %@", testString1);
    NSLog(@"testString2 = %@", testString2);
    
    NSString * truncatedTestString1       = [testString1 stringByTruncatingToLength:50 mode:BMNSStringTruncateModeCenter indicator:nil];
    NSString * truncatedTestString1Target = @"Lorem ipsum dolor sit ame\u2026ex ea commodo consequat.";
    
    // Note: logging format for all tests goes something like this:
    //
    // 1. varName [mode]
    // 2. varName target
    // 3. varName equal? BOOL
    //
    // The first entry is to introduce the printed variable, also including, if applicable, the mode it was obtained with (i.e. truncatedString has three modes when using the long methods).
    // The second if for showing a printed version of the hardcoded target.
    // The final entry should print a boolean because it compares the hardcoded result to the result obtained by applying the tested method.
    
    NSLog(@"truncatedTestString1 center   = '%@'", truncatedTestString1);
    NSLog(@"truncatedTestString1 target   = '%@'", truncatedTestString1Target);
    NSLog(@"truncatedTestString1 equal?      %@ ", BMNSStringFromBOOL([truncatedTestString1 isEqualToString:truncatedTestString1Target]));
    
    NSString * quotedTestString2          = [testString2 quotedString];
    NSString * quotedTestString2Target    = @"This is an urgent \bbackspace \aalert that was \fform fed into a \vvertical \\ttab by \\rreturning a \\nnew line. \\\"Quick!\\\", shouts the 'single to the \\\"double quote. \\\"Engard\u00e9!\\\", ye scuvvy \\\\backslash";
    
    NSLog(@"quotedTestString2             = '%@'", quotedTestString2);
    NSLog(@"quotedTestString2 target      = '%@'", quotedTestString2Target);
    NSLog(@"quotedTestString2 equal?         %@ ", BMNSStringFromBOOL([quotedTestString2 isEqualToString:quotedTestString2Target]));
    
    NSString * escapedTestString2         = [testString2 stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderLast];
    NSString * escapedTestString2Target   = @"This is an urgent \\\\bbackspace \\\\aalert that was \\\\fform fed into a \\\\vvertical \\\\ttab by \\\\rreturning a \\\\nnew line. \\\\\"Quick!\\\\\", shouts the 'single to the \\\\\"double quote. \\\\\"Engard\u00e9!\\\\\", ye scuvvy \\\\backslash";
    
    NSLog(@"escapedTestString2 last       = '%@'", escapedTestString2);
    NSLog(@"escapedTestString2 target     = '%@'", escapedTestString2Target);
    NSLog(@"escapedTestString2 equal?        %@ ", BMNSStringFromBOOL([escapedTestString2 isEqualToString:escapedTestString2Target]));
    
    escapedTestString2 = [testString2 escapedString]; // same as: [testString2 stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderFirst];
    escapedTestString2Target = @"This is an urgent \\bbackspace \\aalert that was \\fform fed into a \\vvertical \\ttab by \\rreturning a \\nnew line. \\\"Quick!\\\", shouts the 'single to the \\\"double quote. \\\"Engard\u00e9!\\\", ye scuvvy \\\\backslash";
    
    NSLog(@"escapedTestString2 first      = '%@'", escapedTestString2);
    NSLog(@"escapedTestString2 target     = '%@'", escapedTestString2Target);
    NSLog(@"escapedTestString2 equal?        %@ ", BMNSStringFromBOOL([escapedTestString2 isEqualToString:escapedTestString2Target]));
    
    NSString * escapedUnescapedString = [[testString2 escapedString] unescapedStringUsingOrder:BMNSStringEscapeTraversingOrderFirst];

    NSLog(@"testString2                   = '%@'", testString2);
    NSLog(@"escaped/unescaped testString2 = '%@'", escapedUnescapedString);
    NSLog(@"escaped/unescaped equal?         %@ ", BMNSStringFromBOOL([escapedUnescapedString isEqualToString:testString2]));
    
    NSLog(@"Note: NO is ok for this result. Unfortunately a escape/unescape roundtrip currently cannot be conservative if it includes a backspace escape (\\b) because upon unescaping it performs its function of deleting one character.");
    
    NSString * stringWithManyPercents   = @"A string with a b%%%tload of %ercent %%%%%% signs %%%%%%%%%%%%%%%%%%%%%% and a random German ß!";
    NSString * stringPercentsTarget     = @"A string with a b%tload of %ercent % signs % and a random German ß!";
    NSString * stringWithSinglePercents = [stringWithManyPercents stringByNormalizingPercentSigns];
    
    NSLog(@"(too) many percent signs      = '%@'", stringWithManyPercents);
    NSLog(@"normalized percent signs      = '%@'", stringWithSinglePercents);
    NSLog(@"normalized target equal?      = '%@'", BMNSStringFromBOOL([stringPercentsTarget isEqualToString:stringWithSinglePercents]));
    

    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"Test some scripts we read from actual files");

    // Perl
    
    NSLog(@"Test Perl Low Complexity Script.pl");
    
    NSString * plLCScriptPath = PATHFORSCRIPT(@"Perl Low Complexity Script.pl");
    BMScript * plLCScript = [BMScript perlScriptWithContentsOfFile:plLCScriptPath];
    
    status = [plLCScript execute];
    
    NSData * plLCScriptResult = [plLCScript lastResult];
    NSInteger plLCScriptRetVal = [plLCScript lastReturnValue];
    
    NSLog(@"Perl low complexity script status = %@", BMNSStringFromExecutionStatus(status));
    NSLog(@"Perl low complexity script result = %@", [plLCScriptResult contentsAsString]);
    NSLog(@"Perl low complexity script retval = %d", plLCScriptRetVal);

    // Ruby
    
    NSLog(@"Test Ruby Low Complexity Script.rb");

    NSString * rbLCScriptPath = PATHFORSCRIPT(@"Ruby Low Complexity Script.rb");
    BMScript * rbLCScript = [BMScript rubyScriptWithContentsOfFile:rbLCScriptPath];
    
    status = [rbLCScript execute];
    
    NSData * rbLCScriptResult = [rbLCScript lastResult];
    NSInteger rbLCScriptRetVal = [rbLCScript lastReturnValue];
    
    NSLog(@"Ruby low complexity script status = %@", BMNSStringFromExecutionStatus(status));
    NSLog(@"Ruby low complexity script result = %@", [rbLCScriptResult contentsAsString]);
    NSLog(@"Ruby low complexity script retval = %d", rbLCScriptRetVal);
    
    // Python
    
    NSLog(@"Test Python Low Complexity Script.py");

    NSString * pyLCScriptPath = PATHFORSCRIPT(@"Python Low Complexity Script.py");
    BMScript * pyLCScript = [BMScript pythonScriptWithContentsOfFile:pyLCScriptPath];
    
    status = [pyLCScript execute];
    
    NSData * pyLCScriptResult = [pyLCScript lastResult];
    NSInteger pyLCScriptRetVal = [pyLCScript lastReturnValue];
    
    NSLog(@"Python low complexity script status = %@", BMNSStringFromExecutionStatus(status));
    NSLog(@"Python low complexity script result = %@", [pyLCScriptResult contentsAsString]);
    NSLog(@"Python low complexity script retval = %d", pyLCScriptRetVal);
    
    // Shell
    
    NSLog(@"Test Shell Low Complexity Script.sh");
              
    NSString * shLCScriptPath = PATHFORSCRIPT(@"Shell Low Complexity Script.sh");
    BMScript * shLCScript = [BMScript shellScriptWithContentsOfFile:shLCScriptPath];
    
    status = [shLCScript execute];
    
    NSData * shLCScriptResult = [shLCScript lastResult];
    NSInteger shLCScriptRetVal = [shLCScript lastReturnValue];
    
    NSLog(@"Shell low complexity script status = %@", BMNSStringFromExecutionStatus(status));
    NSLog(@"Shell low complexity script result = %@", [shLCScriptResult contentsAsString]);
    NSLog(@"Shell low complexity script retval = %d", shLCScriptRetVal);
    
        
    [sr1 release], sr1 = nil;
    [sr2 release], sr2 = nil;
    [script1 release], script1 = nil;
    [script2 release], script2 = nil;
        
    [pool drain];
    
    return EXIT_SUCCESS;
}

#undef PATHFOR
#define PATHFOR OLD_PATHFOR
