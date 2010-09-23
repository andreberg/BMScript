//
//  BMScriptUnitTests.m
//  BMScriptTest
//
//  Created by Andre Berg on 21.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

//  IMPORTANT: When evaluating the output from escaping/unescaping
//  operations within the SenTestingKit, keep in mind that the 
//  display alone of the result in the Xcode developer console 
//  swallows on level of escapes!
//  So if you see @"A string with an \\\"escape\\\"" compared to 
//  @"A string with an \"escape\"" - it's actually correct!

#import <SenTestingKit/SenTestingKit.h>
#import "BMScript.h"
#import "BMRubyScript.h"    /* needed for testing isDescendantOfClass */

#ifdef PATHFOR
    #define OLD_PATHFOR PATHFOR
    #undef PATHFOR
#endif
#define PATHFOR(_NAME_, _TYPE_) ([[NSBundle bundleForClass:[self class]] pathForResource:(_NAME_) ofType:(_TYPE_)])

#define HELLIPSIS "\u2026"

@interface BMScriptUnitTests : SenTestCase {
    NSDictionary * rubyDefaultOptions;
    NSDictionary * alternativeOptions;    
    
    NSString * rubyDefaultScript;
    NSString * rubyHexScript;
    NSString * rubyDecScript;
    NSString * rubyConvertToOctPath;
    NSString * rubyConvertToHexTemplatePath;
    NSString * rubyConvertToDecimalTemplatePath;
    
    NSString * testString1;
    NSString * testString2;
    
    NSString * bgResults;
    ExecutionStatus bgStatus;
}

@end

@implementation BMScriptUnitTests

- (void) setUp {
    
    // default ruby options (ruby 1.8)
    NSArray * rubyDefaultArgs = [NSArray arrayWithObjects:@"-Ku", @"-e", nil];
    rubyDefaultOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"/usr/bin/ruby", BMScriptOptionsTaskLaunchPathKey, 
                          rubyDefaultArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    // alternative ruby options (ruby 1.9)
    NSArray * rubyAlternativeArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    alternativeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"/usr/local/bin/ruby1.9", BMScriptOptionsTaskLaunchPathKey, 
                          rubyAlternativeArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    // a few ruby scripts to play with...
    rubyDefaultScript = @"print \"Ruby Version #{RUBY_VERSION}\"";
    
    rubyHexScript = [NSString stringWithFormat:@"str = %%{%@}\n"
                     @"begin\n"
                     @"  print \"%%#x\" %% str\n"
                     @"rescue\n"
                     @"  #print 'Error: Cannot convert to hexadecimal. String not a number?'\n"
                     @"  print str\n"
                     @"end\n", 
                     @"255"];
    
    rubyDecScript = [NSString stringWithFormat:@"str = %%{%@}\n"
                     @"def decimal(x)\n"
                     @"  if /^0x[abcdefABCDEF0123456789]+$/ =~ x\n"
                     @"    x.hex\n"
                     @"  elsif /^0\\\\d+$/ =~ x\n"
                     @"    x.oct\n"
                     @"  else\n"
                     @"    #'Error: Cannot convert to decimal. String not a hexadecimal or octal number?'\n"
                     @"    x\n"
                     @"  end\n"
                     @"end\n"
                     @"puts decimal(str)", 
                     @"0xff"];
    
    // a few rb file paths to play with...
    rubyConvertToOctPath = PATHFOR(@"Convert To Oct", @"rb");
    rubyConvertToHexTemplatePath = PATHFOR(@"Convert To Hex Template", @"rb");
    rubyConvertToDecimalTemplatePath = PATHFOR(@"Convert To Decimal Template", @"rb");
    
    testString1 = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.    Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit.";
    
    testString2 = @"This is an urgent \bbackspace \aalert that was \fform fed into a \vvertical \ttab by \rreturning a \nnew line. \"Quick!\", shouts the 'single to the \"double quote. \"Engard\u00e9!\", ye scuvvy \\backslash";
}

- (void) tearDown {
    rubyDefaultOptions = nil;
    rubyDefaultScript = nil;
    rubyHexScript = nil;
    rubyDecScript = nil;
    rubyConvertToOctPath = nil;
    rubyConvertToHexTemplatePath = nil;
    rubyConvertToDecimalTemplatePath = nil;
    testString1 =  nil;
    testString2 =  nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) testInitializers {
    
    BMScript * script1 = [[BMScript alloc] init];
    BMScript * script2 = [[BMScript alloc] initWithScriptSource:rubyDefaultScript options:nil];      
    BMScript * script3 = [[BMScript alloc] initWithScriptSource:rubyDefaultScript options:rubyDefaultOptions];
    BMScript * script4 = [[BMScript alloc] initWithContentsOfFile:rubyConvertToOctPath options:nil];      
    BMScript * script5 = [[BMScript alloc] initWithContentsOfFile:rubyConvertToOctPath options:rubyDefaultOptions];
    
    STAssertNotNil(script1, @"script1 should not be nil but is %@", script1);
    STAssertNotNil(script2, @"script2 should not be nil but is %@", script2);
    STAssertNotNil(script3, @"script3 should not be nil but is %@", script3);
    STAssertNotNil(script4, @"script4 should not be nil but is %@", script4);
    STAssertNotNil(script5, @"script5 should not be nil but is %@", script5);
    
    STAssertTrue([script1 isKindOfClass:[BMScript class]], @"");
    STAssertTrue([script2 isKindOfClass:[BMScript class]], @"");
    STAssertTrue([script3 isKindOfClass:[BMScript class]], @"");
    STAssertTrue([script4 isKindOfClass:[BMScript class]], @"");
    STAssertTrue([script5 isKindOfClass:[BMScript class]], @"");
}

- (void) testFactories {
    
    NSString * result;
    
    BMScript * script1 = [BMScript scriptWithContentsOfFile:rubyConvertToOctPath options:rubyDefaultOptions];
    [script1 execute];
    result = [[script1 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"0377"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script2 = [BMScript scriptWithContentsOfFile:rubyConvertToOctPath options:rubyDefaultOptions];
    [script2 execute];
    result = [[script2 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"0377"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script3 = [BMScript scriptWithSource:rubyDecScript options:rubyDefaultOptions];
    [script3 execute];
    result = [[[script3 lastResult] contentsAsString] chomp];
    
    STAssertTrue([result isEqualToString:@"255"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script4 = [BMScript scriptWithSource:rubyHexScript options:rubyDefaultOptions];
    [script4 execute];
    result = [[script4 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"0xff"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script5 = [BMScript perlScriptWithSource:@"print 2**16;"];
    [script5 execute];
    result = [[script5 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"65536"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script6 = [BMScript rubyScriptWithSource:@"%w(1 2 3 4).each do |x| puts x end"];
    [script6 execute];
    result = [[script6 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"1\n2\n3\n4\n"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);

    BMScript * script7 = [BMScript pythonScriptWithSource:@"import this"];
    [script7 execute];
    result = [[script7 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"The Zen of Python, by Tim Peters\n"
                                         @"\n"
                                         @"Beautiful is better than ugly.\n"
                                         @"Explicit is better than implicit.\n"
                                         @"Simple is better than complex.\n"
                                         @"Complex is better than complicated.\n"
                                         @"Flat is better than nested.\n"
                                         @"Sparse is better than dense.\n"
                                         @"Readability counts.\n"
                                         @"Special cases aren't special enough to break the rules.\n"
                                         @"Although practicality beats purity.\n"
                                         @"Errors should never pass silently.\n"
                                         @"Unless explicitly silenced.\n"
                                         @"In the face of ambiguity, refuse the temptation to guess.\n"
                                         @"There should be one-- and preferably only one --obvious way to do it.\n"
                                         @"Although that way may not be obvious at first unless you're Dutch.\n"
                                         @"Now is better than never.\n"
                                         @"Although never is often better than *right* now.\n"
                                         @"If the implementation is hard to explain, it's a bad idea.\n"
                                         @"If the implementation is easy to explain, it may be a good idea.\n"
                                         @"Namespaces are one honking great idea -- let's do more of those!\n"
                                         @""], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script8 = [BMScript shellScriptWithSource:@"echo 'foo bar baz' | awk '{print $2}'"];
    [script8 execute];
    result = [[script8 lastResult] contentsAsString];
    
    STAssertTrue([result isEqualToString:@"bar\n"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    
}

- (void) testTemplates {
    
    NSData * result;
    NSError * error;
    NSString * path;
    
    path = [[NSBundle bundleForClass:[BMScriptUnitTests class]] pathForResource:@"Convert To Hex Template" ofType:@"rb"];
    BMScript * script1 = [BMScript rubyScriptWithContentsOfTemplateFile:path];
    
    STAssertNotNil(script1, @"but instead is %@", script1);
    
    [script1 saturateTemplateWithArgument:[NSString stringWithFormat:@"%li", NSIntegerMax ]];
    [script1 executeAndReturnResult:&result error:&error];
    
    #if __LP64__ || NS_BUILD_32_LIKE_64
        STAssertTrue([[result contentsAsString] isEqualToString:@"0x7fffffffffffffff"], @"but instead is %@", [result contentsAsString]);
    #else
        STAssertTrue([[result contentsAsString] isEqualToString:@"0x7fffffff"], @"but instead is %@", [result contentsAsString]);
    #endif
    
    path = [[NSBundle bundleForClass:[BMScriptUnitTests class]] pathForResource:@"Multiple Tokens Template" ofType:@"rb"];
    BMScript * script2 = [BMScript scriptWithContentsOfTemplateFile:path options:rubyDefaultOptions];
    
    STAssertNotNil(script2, @"but instead is %@", script2);
    
    [script2 saturateTemplateWithArguments:@"template", @"1", @"token"];
    [script2 executeAndReturnResult:&result];
    
    STAssertTrue([[result contentsAsString] isEqualToString:@"a string template with more than 1 replacement also called token\nawesome\n"], @"but instead is '%@'", [[result contentsAsString] quotedString]);
    
    // test exception thrown when template has undefined arguments
    BMScript * script3 = [BMScript rubyScriptWithContentsOfTemplateFile:rubyConvertToHexTemplatePath];
    //[script1 saturateTemplateWithArgument:@"255"];
    STAssertThrowsSpecificNamed([script3 execute], NSException, BMScriptTemplateArgumentMissingException, @"", nil);
    
    // test saturation by keyword dict
    BMScript * script4 = [[BMScript alloc] initWithTemplateSource:@"This is a <#KEYWORD#> template. <#ADJECTIVE#> stuff." 
                                                          options:BMSynthesizeOptions(@"/bin/echo", @"-n")];
    
    STAssertThrowsSpecificNamed([script4 execute], NSException, BMScriptTemplateArgumentMissingException, @"", nil);
    
    NSDictionary * keywordDict = [NSDictionary dictionaryWithObjectsAndKeys:@"keyword-based", @"KEYWORD", 
                                                                            @"Neat", @"ADJECTIVE", nil];
    
    [script4 saturateTemplateWithDictionary:keywordDict];
    ExecutionStatus status = [script4 execute];
    result = [script4 lastResult];
    
    STAssertTrue([[result contentsAsString] isEqualToString:@"This is a keyword-based template. Neat stuff."], @"but instead is '%@'", [[result contentsAsString] quotedString]);
    STAssertTrue(status == BMScriptFinishedSuccessfully, @"but instead is %d", status);
}

- (void) testExecution {
    
    ExecutionStatus success;
    
    // Case 1: 
    // test initalizer for default values
    
    BMScript * script1 = [[BMScript alloc] init];
    success = [script1 execute];
    
    STAssertTrue(success != BMScriptFailedWithException && success != BMScriptNotExecuted, @"script1 execution should return YES, but returned %@", (success ? @"YES" : @"NO"));
    STAssertFalse([[[script1 lastResult] contentsAsString] isEqualToString:@""], @"script1's lastResult shouldn't be equal to an empty string");
    
    [script1 release];    

    // Case 2: 
    // a slightly more complicated script which uses compound return method (more likely real-world scenario)
    
    NSData * result2;
    BMScript * script2 = [[BMScript alloc] initWithScriptSource:rubyHexScript options:rubyDefaultOptions];
    success = [script2 executeAndReturnResult:&result2];
    
    STAssertTrue([[result2 contentsAsString] isEqualToString:@"0xff"], @"script2Result is \"%@\"", [result2 contentsAsString]);
    
    NSLog(@"script2 success = %@", BMNSStringFromBOOL(success));
    
    [script2 release];

    // Case 3: 
    // a slightly more complicated script and use compound return method with out error 
    
    NSData * result3;
    NSError * outError = nil;
    
    BMScript * script3 = [[BMScript alloc] initWithScriptSource:rubyDecScript options:rubyDefaultOptions];
    success = [script3 executeAndReturnResult:&result3 error:&outError];
    
    NSString * result3String = [[[script3 lastResult] contentsAsString] chomp];
    
    STAssertTrue([result3String isEqualToString:@"255"], @"script3Result is \"%@\", outError is \"%@\"", result3String, outError);
    
    NSLog(@"script3 success = %@", BMNSStringFromBOOL(success));
    
    [script3 release];

}

- (void) testStateChangeAfterExecution {
    
    BMScript * script1 = [BMScript rubyScriptWithSource:rubyHexScript];
    [script1 execute];
    
    NSString * script1ResultString = [[script1 lastResult] contentsAsString];
    
    STAssertTrue([script1ResultString isEqualToString:@"0xff"], @"but is '%@'", script1ResultString);
    
    NSError * error = nil;
    
    [script1 setSource:rubyDecScript];
    [script1 executeAndReturnResult:nil error:&error];
    
    STAssertTrue([[[[script1 lastResult] contentsAsString] chomp] isEqualToString:@"255"], @"but is '%@'", [[[script1 lastResult] contentsAsString] chomp]);
}

- (void) testHistory {
    
    NSString * result1;
    NSString * result2;
    BMScript * script1 = [BMScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
    [script1 execute];
    result1 = [[script1 lastResult] contentsAsString];
    
    STAssertTrue([[script1 history] count] > 0, @"");
    
    BMScript * script2 = [BMScript scriptWithSource:[script1 lastScriptSourceFromHistory] options:alternativeOptions];
    [script2 execute];
    result2 = [[script2 lastResult] contentsAsString];
    
    // Would need to chop off the "[objc $PID]:" part from the messages which SenTestKit is outputting to stderr. 
    // Since we have told BMScript's out pipes to write to stdout and stderr what will spoil the test is that 
    // although the output written from BMScript's results is fine, the $PID part from the messages send by SenTestKit 
    // will cause the test to fail since testing the two instances causes it to spawn two test threads with a PID of 
    // one apart from the other. 
    // Edit: Unfortunately this is not possible: It appears that these will be run twice once for GC_ON and once for GC_OFF
    // and only the GC_OFF case has this problem attached.
    STAssertTrue([result2 isEqualToString:result1], @"instead '%@' != '%@'", [[result2 quotedString] truncatedString], [[result1 quotedString] truncatedString]);
    STAssertTrue([[[script1 lastResultFromHistory] contentsAsString] isEqualToString:[[script2 lastResultFromHistory] contentsAsString]], @"");
    
    STAssertEqualObjects([script1 history], [script2 history], @"");
    
    STAssertTrue([[script1 history] isKindOfClass:[NSMutableArray class]], @"but is '%@'", NSStringFromClass([[script1 history] class]));
    STAssertTrue([[script2 history] isKindOfClass:[NSMutableArray class]], @"but is '%@'", NSStringFromClass([[script2 history] class]));
    
}

- (void) testStringUtilities {
    
    NSError * error = nil;
    NSString * unquotedString = [NSString stringWithContentsOfFile:rubyConvertToHexTemplatePath encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"unquotedString = %@", unquotedString);
    
    STAssertNil(error, @"");
    NSString * quotedString = [unquotedString quotedString];
    
    STAssertTrue([quotedString isEqualToString:@"str = %{<##>}\\n"
                                               @"begin\\n"
                                               @"   print \\\"%#x\\\" % str\\n"
                                               @"rescue\\n"
                                               @"   print 'Cannot convert to hexadecimal. String not a number?'\\n"
                                               @"   print str\\n"
                                               @"end"], @"but is '%@'", quotedString);
    
    // if truncate length unspecifified uses a default of 20 or BMNSSTRING_TRUNCATE_LENGTH if defined
    NSString * truncatedQuotedString = [quotedString truncatedString];
    
    STAssertTrue([truncatedQuotedString isEqualToString:@"str = %{<##>}\\n"
                                                        @"begin"
                                                        @""HELLIPSIS""], @"but is '%@'", truncatedQuotedString);
    
    // test that too large length returns unmodified string
    NSString * truncatedQuotedString2 = [quotedString stringByTruncatingToLength:200];
    
    STAssertTrue([truncatedQuotedString2 isEqualToString:quotedString], @"but is '%@'", truncatedQuotedString2);
    
    NSString * truncatedQuotedString3 = [quotedString stringByTruncatingToLength:30];
    
    STAssertTrue([truncatedQuotedString3 isEqualToString:@"str = %{<##>}\\n"
                                                         @"begin\\n"
                                                         @"   print"HELLIPSIS""], @"but is '%@'", truncatedQuotedString3);
    
    NSInteger numPercentageChars = [unquotedString countOccurrencesOfString:@"%"];
    
    STAssertTrue(numPercentageChars == 3, @"but is %i", numPercentageChars);
    
    NSInteger numAUmlautChars = [quotedString countOccurrencesOfString:@"ä"];
    
    STAssertTrue(numAUmlautChars == NSNotFound, @"but is %i", numAUmlautChars);
    
    STAssertTrue([@"'test'" isEqualToString:[@"test" stringByWrappingSingleQuotes]], @"but is %i", [@"'test'" isEqualToString:[@"test" stringByWrappingSingleQuotes]]);
    
    STAssertTrue([@"\"test\"" isEqualToString:[@"test" stringByWrappingDoubleQuotes]], @"but is %i", [@"'test'" isEqualToString:[@"test" stringByWrappingDoubleQuotes]]);
    
    NSInteger l = 50;    
    STAssertEquals([[testString1 stringByTruncatingToLength:l mode:BMNSStringTruncateModeCenter indicator:nil] 
                    isEqualToString:@"Lorem ipsum dolor sit ame"HELLIPSIS"erit in voluptate velit."], YES, @"center mode");
    STAssertEquals([[testString1 stringByTruncatingToLength:l mode:BMNSStringTruncateModeStart indicator:nil] 
                    isEqualToString:@""HELLIPSIS" irure dolor in reprehenderit in voluptate velit."], YES, @"start mode");
    STAssertEquals([[testString1 stringByTruncatingToLength:l mode:BMNSStringTruncateModeEnd indicator:nil] 
                    isEqualToString:@"Lorem ipsum dolor sit amet, consectetur adipisici"HELLIPSIS""], YES, @"end mode");
    
    STAssertThrows([testString1 stringByTruncatingToLength:l mode:-1 indicator:nil], @"this should throw an NSInvalidArgumentException");
    
    // Unfortunately it seems we can't test the reverse traversing order with SenTestingKit since it seems to display different output 
    // than what is actually there when 'it' thinks there are illegal escape sequences. However we can test it over in BMScriptTest.m.
    
    // NSString * orderLastEscapedString = [testString2 stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderLast];
    // STAssertTrue([orderLastEscapedString isEqualToString:[NSString stringWithString:@"This is an urgent \\bbackspace \\aalert that was \\fform fed into a \\vvertical \\ttab by \\rreturning a \\nnew line. \\\"Quick!\\\", shouts the 'single to the \\\"double quote. \\\"Engardé!\\\", ye scuvvy \\backslash"]], @" but is '%@'", orderLastEscapedString);

    NSString * orderFirstEscapedString = [testString2 stringByEscapingStringUsingOrder:BMNSStringEscapeTraversingOrderFirst];
    NSString * escapedString = [testString2 escapedString];

    STAssertTrue([orderFirstEscapedString isEqualToString:@"This is an urgent \\bbackspace \\aalert that was \\fform fed into a \\vvertical \\ttab by \\rreturning a \\nnew line. \\\"Quick!\\\", shouts the 'single to the \\\"double quote. \\\"Engard\u00e9!\\\", ye scuvvy \\\\backslash"], @" but is %@", 
                 [orderFirstEscapedString stringByWrappingSingleQuotes]);

    STAssertTrue([orderFirstEscapedString isEqualToString:escapedString], @" escapedString stringByEscapingStringUsingMode with mode BMNSStringEscapeTraversingOrderFirst should produce equal output, but are: %@ and %@", 
                 [orderFirstEscapedString stringByWrappingSingleQuotes], [escapedString stringByWrappingSingleQuotes]);

    NSString * quotedString2 = [testString2 quotedString];
    
    STAssertTrue([quotedString2 isEqualToString:@"This is an urgent \bbackspace \aalert that was \fform fed into a \vvertical \\ttab by \\rreturning a \\nnew line. \\\"Quick!\\\", shouts the 'single to the \\\"double quote. \\\"Engard\u00e9!\\\", ye scuvvy \\\\backslash"], @" but is '%@'", quotedString2);
    
    STAssertTrue([[@"Andr\u00e9" stringByEscapingUnicodeCharacters] isEqualToString:@"Andr\\u00e9"], @" but is: %@", [@"Andr\u00e9" stringByEscapingUnicodeCharacters]);
    
}

- (void) testDictionaryUtilities {
    NSDictionary * someDict = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"1key", @"2", @"2key", nil];
    STAssertTrue([[someDict allKeys] count] == 2, @"but is %d", [[someDict allKeys] count]);
    
    someDict = [someDict dictionaryByAddingObject:@"3" forKey:@"3key"];
    
    STAssertTrue([[someDict allKeys] count] == 3, @"but is %d", [[someDict allKeys] count]);
    STAssertTrue([[someDict objectForKey:@"3key"] isEqualToString:@"3"], @"but is %@", [[someDict objectForKey:@"3key"] isEqualToString:@"3"]);
}

- (void) testObjectUtilities {
    STAssertFalse([self isDescendantOfClass:[BMScriptUnitTests class]], 
                 @"but is '%@'", BMNSStringFromBOOL([self isDescendantOfClass:[BMScriptUnitTests class]]));
    
    // test instance method
    BMRubyScript * rbScript = [BMRubyScript new];
    STAssertTrue([rbScript isDescendantOfClass:[BMScript class]], 
                 @"but is '%@'", BMNSStringFromBOOL([rbScript isDescendantOfClass:[BMScript class]]));
    
    [rbScript release], rbScript = nil;
    
    // test class method
    STAssertTrue([BMRubyScript isDescendantOfClass:[BMScript class]], 
                  @"but is '%@'", BMNSStringFromBOOL([BMRubyScript isDescendantOfClass:[BMScript class]]));
}


- (void) testMacros {
    NSDictionary * opts = BMSynthesizeOptions(@"/usr/local/bin/ruby1.9", @"-EUTF-8", @"-e");
    STAssertTrue([[opts descriptionInStringsFileFormat] isEqualToString:[alternativeOptions descriptionInStringsFileFormat]], 
                    @"but is '%@'", [opts descriptionInStringsFileFormat]);
}

- (void) testCopying {
    
    BMScript * script = [[BMScript alloc] init];
    BMScript * scriptCopy = [script copy];
    
    STAssertTrue([scriptCopy.source isEqualToString:script.source], @" but is %@", scriptCopy.source);
    STAssertTrue([scriptCopy.options isEqualToDictionary:script.options], @" but is %@", [scriptCopy.options descriptionInStringsFileFormat]);
    STAssertTrue([scriptCopy lastReturnValue] == [script lastReturnValue], @" but is %d", [scriptCopy lastReturnValue]);
    
    scriptCopy.source = @"assign a new source";
    
    BOOL isNotEqual = (![scriptCopy.source isEqualToString:script.source ]);
    STAssertTrue(isNotEqual, @" scriptCopy's source should not be equal to script's source after changing it.");
    
    [script release], script = nil;
    [scriptCopy release], scriptCopy = nil;
    
}

- (void) testPythonLowComplexityScript {
    
    NSString * pyLCScriptPath = PATHFOR(@"Python Low Complexity Script", @"py");
    BMScript * pyLCScript = [BMScript pythonScriptWithContentsOfFile:pyLCScriptPath];
    
    STAssertNotNil(pyLCScript, @" but is %@", pyLCScript);
    STAssertTrue([pyLCScript.source isEqualToString:@"#!/usr/bin/python\n#\n# Python Low Complexity Script.py\n# BMScriptTest\n#\n# Created by Andre Berg on 21.09.10.\n# Copyright 2010 Berg Media. All rights reserved.\n# \n\ndef main():\n    s = \"\"\n    for i in range(1,11):\n        s = s + str(i)\n    print s\n\nif __name__ == '__main__':\n    main()"], @" but is %@", pyLCScript.source);
    
    ExecutionStatus status = [pyLCScript execute];
    
    NSString * pyLCScriptResult = [[pyLCScript lastResult] contentsAsString];
    NSInteger pyLCScriptRetVal = [pyLCScript lastReturnValue];
    
    STAssertTrue(status == BMScriptFinishedSuccessfully, @" but is %@", BMNSStringFromExecutionStatus(status));
    STAssertTrue(pyLCScriptRetVal == 0, @" but is %d", pyLCScriptRetVal);
    STAssertTrue([pyLCScriptResult isEqualToString:@"12345678910\n"], @" but is %@", pyLCScriptResult);
}

- (void) testPerlLowComplexityScript {
    
    NSString * plLCScriptPath = PATHFOR(@"Perl Low Complexity Script", @"pl");
    BMScript * plLCScript = [BMScript perlScriptWithContentsOfFile:plLCScriptPath];
    
    STAssertNotNil(plLCScript, @" but is %@", plLCScript);
    STAssertTrue([plLCScript.source isEqualToString:@"#!/usr/bin/perl\n#\n# Perl Low Complexity Script.pl\n# BMScriptTest\n#\n# Created by Andre Berg on 22.09.10.\n# Copyright 2010 Berg Media. All rights reserved.\n\nuse strict;\n\nmy $i = 1;\nwhile ($i <= 10) {\n    print $i;\n    $i++;\n}"], @" but is %@", plLCScript.source);
    
    ExecutionStatus status = [plLCScript execute];
    
    NSString * plLCScriptResult = [[plLCScript lastResult] contentsAsString];
    NSInteger plLCScriptRetVal = [plLCScript lastReturnValue];
    
    STAssertTrue(status == BMScriptFinishedSuccessfully, @" but is %@", BMNSStringFromExecutionStatus(status));
    STAssertTrue(plLCScriptRetVal == 0, @" but is %d", plLCScriptRetVal);
    STAssertTrue([plLCScriptResult isEqualToString:@"12345678910"], @" but is %@", plLCScriptResult);
}

- (void) testRubyLowComplexityScript {
    
    NSString * rbLCScriptPath = PATHFOR(@"Ruby Low Complexity Script", @"rb");
    BMScript * rbLCScript = [BMScript rubyScriptWithContentsOfFile:rbLCScriptPath];

    STAssertNotNil(rbLCScript, @" but is %@", rbLCScript);
    STAssertTrue([rbLCScript.source isEqualToString:@"#!/usr/bin/ruby\n#\n# Ruby Low Complexity Script.rb\n# BMScriptTest\n#\n# Created by Andre Berg on 22.09.10.\n# Copyright 2010 Berg Media. All rights reserved.\n\ni = 0\n1.upto 10 do\n  print i = i + 1\nend"], @" but is %@", rbLCScript.source);
    
    ExecutionStatus status = [rbLCScript execute];
    
    NSString * rbLCScriptResult = [[rbLCScript lastResult] contentsAsString];
    NSInteger rbLCScriptRetVal = [rbLCScript lastReturnValue];
    
    STAssertTrue(status == BMScriptFinishedSuccessfully, @" but is %@", BMNSStringFromExecutionStatus(status));
    STAssertTrue(rbLCScriptRetVal == 0, @" but is %d", rbLCScriptRetVal);
    STAssertTrue([rbLCScriptResult isEqualToString:@"12345678910"], @" but is %@", rbLCScriptResult);    
}

- (void) testShellLowComplexityScript {
    
    NSString * shLCScriptPath = PATHFOR(@"Shell Low Complexity Script", @"sh");
    BMScript * shLCScript = [BMScript shellScriptWithContentsOfFile:shLCScriptPath];
    
    STAssertNotNil(shLCScript, @" but is %@", shLCScript);
    STAssertTrue([shLCScript.source isEqualToString:@"#!/bin/bash\n#\n# Low Complexity Shell Script.sh\n# BMScriptTest\n#\n# Created by Andre Berg on 21.09.10.\n# Copyright 2010 Berg Media. All rights reserved.\n\nif [[ -f \"/System/Library/CoreServices/SystemVersion.plist\" ]]; then\n  echo 'File exists!' | sed s/File/SystemVersion.plist/\nelse\n  echo 'File does not exist!' | sed s/File/SystemVersion.plist/\nfi"], @" but is %@", shLCScript.source);
    
    ExecutionStatus status = [shLCScript execute];
    
    NSString * shLCScriptResult = [[shLCScript lastResult] contentsAsString];
    NSInteger shLCScriptRetVal = [shLCScript lastReturnValue];

    STAssertTrue(status == BMScriptFinishedSuccessfully, @" but is %@", BMNSStringFromExecutionStatus(status));
    STAssertTrue(shLCScriptRetVal == 0, @" but is %d", shLCScriptRetVal);
    STAssertTrue([shLCScriptResult isEqualToString:@"SystemVersion.plist exists!\n"], @" but is %@", shLCScriptResult);    
}

@end

#undef PATHFOR
#define PATHFOR OLD_PATHFOR
