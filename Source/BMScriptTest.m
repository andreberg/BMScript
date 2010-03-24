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

#import <Foundation/Foundation.h>
#import "BMScript.h"
#import "BMRubyScript.h"
#import "ScriptRunner.h"
#include <unistd.h>

#if (!defined(NS_BLOCK_ASSERTIONS) && !defined(BM_BLOCK_ASSERTIONS) && DEBUG)
    #define BMAssertLog(_COND_) if (!(_COND_)) \
        NSLog(@"*** AssertionFailure: %s should be YES but is %@", #_COND_, ((_COND_) ? @"YES" : @"NO"))
    #define BMAssertThrow(_COND_, _DESC_) if (!(_COND_)) \
        @throw [NSException exceptionWithName:@"*** AssertionFailure" reason:[NSString stringWithFormat:@"%s should be YES but is %@", #_COND_, (_DESC_)] userInfo:nil]
#else
    #define BMAsssertLog
    #define BMAssertThrow
    #define NS_BLOCK_ASSERTIONS 1
#endif

#ifdef PATHFOR
    #define OLD_PATHFOR PATHFOR
#undef PATHFOR
    #endif
#define PATHFOR(_CLASS_, _NAME_, _TYPE_) ([[NSBundle bundleForClass:[(_CLASS_) class]] pathForResource:(_NAME_) ofType:(_TYPE_)])

#include <unistd.h>
#include <sys/param.h>

// MARK: PATHS

#define BASEPATH ([[NSFileManager defaultManager] currentDirectoryPath])
#define TEMPLATEPATH [NSString stringWithFormat:@"%@%@", BASEPATH, @"/Unit Tests/Resources/Templates"]
#define RUBY19_EXE_PATH @"/usr/local/bin/ruby1.9"



// ---------------------------------------------------------------------------------------- 
// MARK: MAIN
// ---------------------------------------------------------------------------------------- 


int main (int argc, const char * argv[]) {
#pragma unused(argc, argv)
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"MAC_OS_X_VERSION_MIN_REQUIRED = %i", MAC_OS_X_VERSION_MIN_REQUIRED);
    NSLog(@"MAC_OS_X_VERSION_MAX_ALLOWED = %i", MAC_OS_X_VERSION_MAX_ALLOWED);
    NSLog(@"BMSCRIPT_THREAD_SAFE = %i", BMSCRIPT_THREAD_SAFE);
    NSLog(@"BMSCRIPT_FAST_LOCK = %i", BMSCRIPT_FAST_LOCK);
    NSLog(@"GarbageCollector enabled? %@", BMStringFromBOOL([[NSGarbageCollector defaultCollector] isEnabled]));
    NSLog(@"NSFileManager currentDirectoryPath = %@", [[NSFileManager defaultManager] currentDirectoryPath]);
    
    BOOL success = NO;
    
    // ---------------------------------------------------------------------------------------- 
    
    ScriptRunner * sr1 = [[ScriptRunner alloc] init];
    ScriptRunner * sr2 = [[ScriptRunner alloc] initWithExecutionMode:SRNonBlockingExecutionMode];
    [sr1 run];
    [sr2 run];
        
    // test BMScriptLanguageProtocol conformance
    BOOL respondsToDefaultOpts                  = [sr1 respondsToSelector:@selector(defaultOptionsForLanguage)];
    BOOL respondsToDefaultScript                = [sr1 respondsToSelector:@selector(defaultScriptSourceForLanguage)];

    // test BMScriptDelegateProtocol conformance
    BOOL respondsToShouldSetScript              = [sr1 respondsToSelector:@selector(shouldSetScript:)];
    BOOL respondsToShouldLastResult             = [sr1 respondsToSelector:@selector(shouldSetResult:)];
    BOOL respondsToShouldAddItemToHistory       = [sr1 respondsToSelector:@selector(shouldAddItemToHistory:)];
    BOOL respondsToShouldReturnItemFromHistory  = [sr1 respondsToSelector:@selector(shouldReturnItemFromHistory:)];
    BOOL respondsToShouldAppendPartialResult    = [sr1 respondsToSelector:@selector(shouldAppendPartialResult:)];
    BOOL respondsToShouldSetOptions             = [sr1 respondsToSelector:@selector(shouldSetOptions:)];
    
    NSLog(@"ScriptRunner conforms to BMScriptLanguageProtocol? %@", BMStringFromBOOL([ScriptRunner conformsToProtocol:@protocol(BMScriptLanguageProtocol)]));
    NSLog(@"ScriptRunner implements required methods for %@? %@", @"BMScriptLanguageProtocol", BMStringFromBOOL(respondsToDefaultOpts));
    NSLog(@"ScriptRunner implements all methods for %@? %@", @"BMScriptLanguageProtocol", BMStringFromBOOL(respondsToDefaultOpts && respondsToDefaultScript));

    NSLog(@"ScriptRunner conforms to BMScriptDelegateProtocol? %@", BMStringFromBOOL([ScriptRunner conformsToProtocol:@protocol(BMScriptDelegateProtocol)]));
    NSLog(@"ScriptRunner implements some methods for %@? %@", @"BMScriptLanguageProtocol", 
          BMStringFromBOOL(respondsToShouldSetScript 
                           || respondsToShouldLastResult 
                           || respondsToShouldAddItemToHistory 
                           || respondsToShouldReturnItemFromHistory 
                           || respondsToShouldAppendPartialResult 
                           || respondsToShouldSetOptions));
    NSLog(@"ScriptRunner implements all methods for %@? %@", @"BMScriptLanguageProtocol", 
          BMStringFromBOOL(respondsToShouldSetScript 
                           && respondsToShouldLastResult 
                           && respondsToShouldAddItemToHistory 
                           && respondsToShouldReturnItemFromHistory 
                           && respondsToShouldAppendPartialResult 
                           && respondsToShouldSetOptions));
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    

     BMScript * script1 = [[BMScript alloc] init];
     [script1 execute];
     NSString * result1 = [script1 lastResult];
     printf("script1 result = %s", [result1 UTF8String]);
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    BMRubyScript * script2 = [[BMRubyScript alloc] initWithScriptSource:@"puts 1+2" options:nil];
    NSString * result2;
    success = [script2 executeAndReturnResult:&result2];
   
    if (success == BMScriptFinishedSuccessfullyTerminationStatus) {
        NSLog(@"script2 result = %@", result2);
    };
    
    NSArray * newArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    NSDictionary * newOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                 RUBY19_EXE_PATH, BMScriptOptionsTaskLaunchPathKey, 
                                                   newArgs, BMScriptOptionsTaskArgumentsKey, nil];

    NSError * error;
    NSString * newResult1;
    
    [script1 setScript:@"puts \"newScript1 executed\\n ...again with \\\"ruby 1.9\\\"!\""];
    [script1 setOptions:newOptions];
    success = [script1 executeAndReturnResult:&newResult1 error:&error];
    
    if (success) {
        NSLog(@"script1 new result (unquoted) = %@ (%@)", [newResult1 quote], newResult1);
    }
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    
    NSString * path = [TEMPLATEPATH stringByAppendingPathComponent:@"Convert To Oct.rb"];
    
    BMRubyScript * script3 = [BMRubyScript scriptWithContentsOfTemplateFile:path options:nil];
    [script3 saturateTemplateWithArgument:@"100"];
    [script3 execute];
    
    NSLog(@"script3 (convert '100' to octal) result = %@", [script3 lastResult]);
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result4;
    
    path = [TEMPLATEPATH stringByAppendingPathComponent:@"Multiple Tokens Template.rb"];
    
    BMRubyScript * script4 = [BMRubyScript scriptWithContentsOfTemplateFile:path options:nil];
    [script4 saturateTemplateWithArguments:@"template", @"1", @"tokens"];
    [script4 execute];
    
    result4 = [script4 lastResult];
    NSLog(@"script4 (sequential token template saturation) result = %@", result4);
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result5;
    NSString * result6;
    
    // alternative options (ruby 1.9)
    NSArray * alternativeArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    NSDictionary * alternativeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                          RUBY19_EXE_PATH, BMScriptOptionsTaskLaunchPathKey, 
                                                    alternativeArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    BMRubyScript * script5 = [BMRubyScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
    [script5 executeAndReturnResult:&result5];
        
    BMRubyScript * script6 = [BMRubyScript scriptWithSource:[script5 lastScriptSourceFromHistory] options:alternativeOptions];
    [script6 execute];
    result6 = [script6 lastResult];
    
    BMAssertLog([result5 isEqualToString:result6]);    
    if (![result5 isEqualToString:result6]) {
        NSLog(@"*** AssertionFailure: result3 should be equal to result4!");
    }
    
    NSLog(@"script5 (alternative options) result = %@", result5);
    NSLog(@"script6 (execute last script source from history) result = %@", result6);
    
    BMAssertLog([[script5 history] isEqual:[script6 history]]);
    if (![[script5 history] isEqual:[script6 history]]) {
        NSLog(@"*** AssertionFailure: [result5 history] should be equal to [result6 history]");
    }
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    BMScript * script7 = [BMScript rubyScriptWithContentsOfTemplateFile:[TEMPLATEPATH stringByAppendingPathComponent:@"Multiple Defined Tokens Template.rb"]];
    NSDictionary * templateDict = [NSDictionary dictionaryWithObjectsAndKeys:@"template", @"TEMPLATE", @"1", @"NUM", @"tokens", @"TOKENS", nil];
    [script7 saturateTemplateWithDictionary:templateDict];
    [script7 execute];
    NSString * result7 = [script7 lastResult];
    
    BMAssertLog([[script4 lastResult] isEqualToString:result7]);
    
    NSLog(@"script7 (keyword args template saturation) result = %@", result7);
    
    
    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"ScriptRunner 1 (sr1) results = %@", [sr1.results quote]);
    NSLog(@"ScriptRunner 2 (sr2) results = %@", [sr2.results quote]);
    
    BMAssertLog([sr1.results isEqualToString:@"\"this is ScriptRunner\'s script calling...\" CHANGED"]);
    BMAssertLog([sr2.results isEqualToString:@"515377520732011331036461129765621272702107522001\n CHANGED"]);
    
    [sr1 release];
    [sr2 release];
    

    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result8;
    
    BMScript * script8 = [BMScript perlScriptWithSource:@"print 2**64;"];
    [script8 executeAndReturnResult:&result8 error:&error];
    
    BMAssertLog([result8 isEqualToString:@"1.84467440737096e+19"]);    
    NSLog(@"result8 = %@", result8);
    

    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"The following should return NO: isEqual is only true if both scriptSource and task launchPath are equal.");
    NSLog(@"[script4 isEqual:script7]? %@", BMStringFromBOOL([script4 isEqual:script7]));

    NSLog(@"The following should return YES, obviously...");
    NSLog(@"[script4 isEqual:script4]? %@", BMStringFromBOOL([script4 isEqual:script4]));

    NSLog(@"The following should return NO: isEqual is only true if both scriptSource and task launchPath are equal.");
    NSLog(@"[script4 isEqualToScript:script7]? %@", BMStringFromBOOL([script4 isEqualToScript:script7]));

    NSLog(@"The following should return YES, obviously...");
    NSLog(@"[script4 isEqualToScript:script4]? %@", BMStringFromBOOL([script4 isEqualToScript:script4]));
    
    NSLog(@"[script4 lastResult] = %@", [[script4 lastResult] quote]);
    NSLog(@"[script7 lastResult] = %@", [[script7 lastResult] quote]);
    

    NSLog(@"----------------------------------------------------------------------------------------");
    // ---------------------------------------------------------------------------------------- 
    
    [script1 release];
    [script2 release];
        
    [pool drain];
    
    if (DEBUG) {
        NSLog(@"Press return to exit...");
        getchar();
    }
    return 0;
}

#undef PATHFOR
#define PATHFOR OLD_PATHFOR
