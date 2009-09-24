#import <Foundation/Foundation.h>
#import "BMScript.h"
#import "BMRubyScript.h"
#import "TaskObserver.h"
#include <unistd.h>

#if (!defined(NS_BLOCK_ASSERTIONS) && !defined(BM_BLOCK_ASSERTIONS))
    #define BMAssertLog(_COND_) if (!(_COND_)) \
        NSLog(@"*** AssertionFailure: %s should be YES but is %@", #_COND_, ((_COND_) ? @"YES" : @"NO"))
    #define BMAssertThrow(_COND_, _DESC_) if (!(_COND_)) \
        @throw [NSException exceptionWithName:@"*** AssertionFailure" reason:[NSString stringWithFormat:@"%s should be YES but is %@", #_COND_, (_DESC_)] userInfo:nil]
#else
    #define BMAsssertLog
    #define BMAssertThrow
#endif

#ifdef PATHFOR
    #define OLD_PATHFOR PATHFOR
#undef PATHFOR
    #endif
#define PATHFOR(_CLASS_, _NAME_, _TYPE_) ([[NSBundle bundleForClass:[(_CLASS_) class]] pathForResource:(_NAME_) ofType:(_TYPE_)])

#define DEBUG 1

// ---------------------------------------------------------------------------------------- 
// MARK: MAIN
// ---------------------------------------------------------------------------------------- 


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"MAC_OS_X_VERSION_MIN_REQUIRED = %i", MAC_OS_X_VERSION_MIN_REQUIRED);
    NSLog(@"MAC_OS_X_VERSION_MAX_ALLOWED = %i", MAC_OS_X_VERSION_MAX_ALLOWED);
    
    NSLog(@"GarbageCollector enabled? %@", BMStringFromBOOL([[NSGarbageCollector defaultCollector] isEnabled]));
    
    BOOL success = NO;
    
    // ---------------------------------------------------------------------------------------- 
    
    TaskObserver * to = [[TaskObserver alloc] init];
        
    // test protocol conformance
    BOOL respondsToDefaultOpts = [to respondsToSelector:@selector(defaultOptionsForLanguage)];
    BOOL respondsToDefaultScript = [to respondsToSelector:@selector(defaultScriptSourceForLanguage)];
    BOOL respondsToTaskFinishedCallback = [to respondsToSelector:@selector(taskFinishedCallback:)];
    
    NSLog(@"TaskObserver conforms to BMScriptLanguageProtocol? %@", BMStringFromBOOL([TaskObserver conformsToProtocol:@protocol(BMScriptLanguageProtocol)]));
    NSLog(@"TaskObserver implements all required methods for %@? %@", @"BMScriptLanguageProtocol", BMStringFromBOOL(respondsToDefaultOpts));
    NSLog(@"TaskObserver implements all methods for %@? %@", @"BMScriptLanguageProtocol", BMStringFromBOOL(respondsToDefaultOpts && respondsToDefaultScript && respondsToTaskFinishedCallback));

    [to performSelector:@selector(checkTaskHasFinished:) withObject:to afterDelay:0.2];

    // ---------------------------------------------------------------------------------------- 

    BMScript * script1 = [[BMScript alloc] init];
    [script1 execute];
    NSString * result1 = [script1 lastResult];
    NSLog(@"script1 result = %@", result1);
    
    // ---------------------------------------------------------------------------------------- 
    
    BMRubyScript * script2 = [[BMRubyScript alloc] initWithScriptSource:@"puts 1+2"];
    NSString * result2;
    success = [script2 executeAndReturnResult:&result2];
   
    if (success) {
        NSLog(@"script2 result = %@", result2);
    };
    
    NSArray * newArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    NSDictionary * newOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"/usr/local/bin/ruby1.9", BMScriptOptionsTaskLaunchPathKey, 
                                                   newArgs, BMScriptOptionsTaskArgumentsKey, nil];

    NSError * error;
    NSString * newResult1;
    
    [script1 setScript:@"puts \"newScript1 executed\\n ...again with \\\"ruby 1.9\\\"!\""];
    [script1 setOptions:newOptions];
    success = [script1 executeAndReturnResult:&newResult1 error:&error];
    
    if (success) {
        NSLog(@"script1 new result (unquoted) = %@ (%@)", [newResult1 quote], newResult1);
    }
    
    // ---------------------------------------------------------------------------------------- 
    
    NSString * path = @"/Users/andre/Documents/Xcode/CommandLineUtility/Foundation/+Tests/BMScriptTestSVN/trunk/Convert To Oct.rb";
    
    BMRubyScript * script3 = [BMRubyScript scriptWithContentsOfTemplateFile:path];
    [script3 saturateTemplateWithArgument:@"100"];
    [script3 execute];
    
    NSLog(@"script3 result = %@", [script3 lastResult]);
    
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result4;
    
    path = @"/Users/andre/Documents/Xcode/CommandLineUtility/Foundation/+Tests/BMScriptTest/Multiple Tokens Template.rb";
    
    BMRubyScript * script4 = [BMRubyScript scriptWithContentsOfTemplateFile:path];
    [script4 saturateTemplateWithArguments:@"template", @"1", @"tokens"];
    [script4 execute];
    
    result4 = [script4 lastResult];
    NSLog(@"script4 result = %@", result4);
    
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result5;
    NSString * result6;
    
    // alternative options (ruby 1.9)
    NSArray * alternativeArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    NSDictionary * alternativeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"/usr/local/bin/ruby1.9", BMScriptOptionsTaskLaunchPathKey, 
                                                    alternativeArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    // ---------------------------------------------------------------------------------------- 
    
    BMRubyScript * script5 = [BMRubyScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
    [script5 executeAndReturnResult:&result5];
        
    BMRubyScript * script6 = [BMRubyScript scriptWithSource:[script5 lastScriptSourceFromHistory] options:alternativeOptions];
    [script6 execute];
    result6 = [script6 lastResult];
    
    if (![result5 isEqualToString:result6]) {
        NSLog(@"*** AssertionFailure: result3 should be equal to result4!");
    }
    
    if (![[script5 history] isEqual:[script6 history]]) {
        NSLog(@"*** AssertionFailure: [result3 history] should be equal to [result4 history]");
    }

    // ---------------------------------------------------------------------------------------- 
    
    BMScript * script7 = [BMScript rubyScriptWithContentsOfTemplateFile:@"/Users/andre/Documents/Xcode/CommandLineUtility/Foundation/+Tests/BMScriptTestSVN/trunk/Multiple Defined Tokens Template.rb"];
    NSDictionary * templateDict = [NSDictionary dictionaryWithObjectsAndKeys:@"template", @"TEMPLATE", @"1", @"NUM", @"tokens", @"TOKENS", nil];
    [script7 saturateTemplateWithDictionary:templateDict];
    [script7 execute];
    NSString * result7 = [script7 lastResult];
    
    BMAssertLog([[script4 lastResult] isEqualToString:result7]);
    
    NSLog(@"script7 result = %@", result7);
    
    // ---------------------------------------------------------------------------------------- 
    
    BMAssertLog([to.bgResults isEqualToString:@"515377520732011331036461129765621272702107522001\n"]);
    [to release];
    
    // ---------------------------------------------------------------------------------------- 
    
    NSString * result8;
    
    BMScript * script8 = [BMScript perlScriptWithSource:@"print 2**64;"];
    [script8 executeAndReturnResult:&result8 error:&error];
    
    NSLog(@"result8 = %@", result8);
    
    // ---------------------------------------------------------------------------------------- 
    
    NSLog(@"[script4 isEqual:script7]? %@", BMStringFromBOOL([script4 isEqual:script7]));
    NSLog(@"[script4 isEqual:script4]? %@", BMStringFromBOOL([script4 isEqual:script4]));
    NSLog(@"[script4 isEqualToScript:script7]? %@", BMStringFromBOOL([script4 isEqualToScript:script7]));
    NSLog(@"[script4 isEqualToScript:script4]? %@", BMStringFromBOOL([script4 isEqualToScript:script4]));
    
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
