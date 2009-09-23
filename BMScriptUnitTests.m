//
//  BMScriptUnitTests.m
//  BMScriptTest
//
//  Created by Andre Berg on 21.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "BMScript.h"
#import "TaskObserver.h"

#ifdef PATHFOR
    #define OLD_PATHFOR PATHFOR
    #undef PATHFOR
#endif
#define PATHFOR(_NAME_, _TYPE_) ([[NSBundle bundleForClass:[self class]] pathForResource:(_NAME_) ofType:(_TYPE_)])


@interface BMScriptUnitTests : SenTestCase {
    NSDictionary * rubyDefaultOptions;
    NSDictionary * alternativeOptions;    
    
    NSString * rubyDefaultScript;
    NSString * rubyHexScript;
    NSString * rubyDecScript;
    NSString * rubyConvertToOctPath;
    NSString * rubyConvertToHexTemplatePath;
    NSString * rubyConvertToDecimalTemplatePath;
    
    NSString * bgResults;
    TerminationStatus bgStatus;
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
                     @"print decimal(str)", 
                     @"0xff"];
    
    // a few rb file paths to play with...
    rubyConvertToOctPath = PATHFOR(@"Convert To Oct", @"rb");
    rubyConvertToHexTemplatePath = PATHFOR(@"Convert To Hex Template", @"rb");
    rubyConvertToDecimalTemplatePath = PATHFOR(@"Convert To Decimal Template", @"rb");
}

- (void) tearDown {
    rubyDefaultOptions = nil;
    rubyDefaultScript = nil;
    rubyHexScript = nil;
    rubyDecScript = nil;
    rubyConvertToOctPath = nil;
    rubyConvertToHexTemplatePath = nil;
    rubyConvertToDecimalTemplatePath = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) testInitializers {
    
    BMScript * script1 = [[BMScript alloc] init];
    BMScript * script2 = [[BMScript alloc] initWithScriptSource:rubyDefaultScript];      
    BMScript * script3 = [[BMScript alloc] initWithScriptSource:rubyDefaultScript options:rubyDefaultOptions];
    BMScript * script4 = [[BMScript alloc] initWithContentsOfFile:rubyConvertToOctPath];      
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
    result = [script1 lastResult];
    
    STAssertTrue([result isEqualToString:@"0377"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script2 = [BMScript scriptWithContentsOfFile:rubyConvertToOctPath options:rubyDefaultOptions];
    [script2 execute];
    result = [script2 lastResult];
    
    STAssertTrue([result isEqualToString:@"0377"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script3 = [BMScript scriptWithSource:rubyDecScript options:rubyDefaultOptions];
    [script3 execute];
    result = [script3 lastResult];
    
    STAssertTrue([result isEqualToString:@"255"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script4 = [BMScript scriptWithSource:rubyHexScript options:rubyDefaultOptions];
    [script4 execute];
    result = [script4 lastResult];
    
    STAssertTrue([result isEqualToString:@"0xff"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMScript * script5 = [BMScript perlScriptWithSource:@"print 2**16;"];
    [script5 execute];
    result = [script5 lastResult];
    
    STAssertTrue([result isEqualToString:@"65536"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
}

- (void) testTemplates {
    
    NSString * result;
    NSError * error;
    NSString * path;
    
    path = [[NSBundle bundleForClass:[BMScriptUnitTests class]] pathForResource:@"Convert To Hex Template" ofType:@"rb"];
    BMScript * script1 = [BMScript rubyScriptWithContentsOfTemplateFile:path];
    
    STAssertNotNil(script1, @"but instead is %@", script1);
    
    [script1 saturateTemplateWithArgument:[NSString stringWithFormat:@"%li", NSIntegerMax ]];
    [script1 executeAndReturnResult:&result error:&error];
    
    STAssertTrue([result isEqualToString:@"0x7fffffff"], @"but instead is %@", result);


    
    path = [[NSBundle bundleForClass:[BMScriptUnitTests class]] pathForResource:@"Multiple Tokens Template" ofType:@"rb"];
    BMScript * script2 = [BMScript scriptWithContentsOfTemplateFile:path options:rubyDefaultOptions];
    
    STAssertNotNil(script2, @"but instead is %@", script2);
    
    [script2 saturateTemplateWithArguments:@"template", @"1", @"token"];
    [script2 executeAndReturnResult:&result];
    
    STAssertTrue([result isEqualToString:@"a string template with more than 1 replacement also called token\n"], @"but instead is '%@'", [result quote]);
    
    // test exception thrown when template has undefined arguments
    BMScript * script3 = [BMScript rubyScriptWithContentsOfTemplateFile:rubyConvertToHexTemplatePath];
    //[script1 saturateTemplateWithArgument:@"255"];
    STAssertThrowsSpecificNamed([script3 execute], NSException, BMScriptTemplateArgumentMissingException, @"", nil);
    
}


// - (void) testAvailability {
//     if (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5 && MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5) {
//         STAssertTrue([BMRS_ACCESSORS isEqualToString:@"conventional accessors"], @"but is %@", BMRS_ACCESSORS);
//     }
//     if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5) {
//         STAssertTrue([BMRS_ACCESSORS isEqualToString:@"synthesized properties"], @"but is %@", BMRS_ACCESSORS);
//     }
// }

- (void) testExecution {
    
    BOOL success;
    
    // Case 1: 
    // test initalizer for default values
    
    BMScript * script1 = [[BMScript alloc] init];
    success = [script1 execute];
    
    STAssertTrue(success == YES, @"script1 execution should return YES, but returned %@", (success ? @"YES" : @"NO"));
    STAssertFalse([[script1 lastResult] isEqualToString:@""], @"script1's lastResult shouldn't be equal to an empty string");
    
    [script1 release];    

    // Case 2: 
    // a slightly more complicated script which uses compound return method (more likely real-world scenario)
    
    NSString * result2;
    BMScript * script2 = [[BMScript alloc] initWithScriptSource:rubyHexScript options:rubyDefaultOptions];
    success = [script2 executeAndReturnResult:&result2];
    
    STAssertTrue([result2 isEqualToString:@"0xff"], @"script2Result is \"%@\"", result2);
    
    NSLog(@"script2 success = %@", BMStringFromBOOL(success));
    
    [script2 release];

    // Case 3: 
    // a slightly more complicated script and use compound return method with out error (more likely real-world scenario)
    
    NSString * result3;
    NSError * outError;
    
    BMScript * script3 = [[BMScript alloc] initWithScriptSource:rubyDecScript options:rubyDefaultOptions];
    success = [script3 executeAndReturnResult:&result3 error:&outError];
    
    STAssertTrue([result3 isEqualToString:@"255"], @"script3Result is \"%@\", outError is \"%@\"", result3, outError);
    
    NSLog(@"script3 success = %@", BMStringFromBOOL(success));
    
    [script3 release];

}
- (void) testBackgroundExecution {
    // Unfortunately SenTestingKit is too weak to test async execution.
    // I tried different methods from facades to distributed objects to proxies etc.
    // Right now I have reasonable test coverage by testing in main
//     STAssertTrue([to.bgResults isEqualToString:@"515377520732011331036461129765621272702107522001\n"], @"but is %@", to.bgResults);
//     STAssertTrue(to.bgStatus == BMScriptFinishedSuccessfullyTerminationStatus, @"but is %d", to.bgStatus);
//     STAssertFalse(to.bgStatus == BMScriptFailedTerminationStatus, @"but is %d", to.bgStatus);

}


- (void) testStateChangeAfterExecution {
    BMScript * script1 = [BMScript rubyScriptWithSource:rubyHexScript];
    [script1 execute];
    
    STAssertTrue([[script1 lastResult] isEqualToString:@"0xff"], @"but is '%@'", [script1 lastResult]);
    
    NSError * error;
    
    [script1 setScript:rubyDecScript];
    [script1 executeAndReturnError:&error];
    
    STAssertTrue([[script1 lastResult] isEqualToString:@"255"], @"but is '%@'", [script1 lastResult]);
}

- (void) testHistory {
    
    NSString * result1;
    NSString * result2;
    BMScript * script1 = [BMScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
    [script1 execute];
    result1 = [script1 lastResult];
    
    STAssertTrue([[script1 history] count] > 0, @"");
    
    BMScript * script2 = [BMScript scriptWithSource:[script1 lastScriptSourceFromHistory] options:alternativeOptions];
    [script2 execute];
    result2 = [script2 lastResult];
    
    // Would need to chop off the "[objc $PID]:" part from the messages which SenTestKit is outputting to stderr. 
    // Since we have told BMScript's out pipes to write to stdout and stderr what will spoil the test is that 
    // although the output written from BMScript's results is fine, the $PID part from the messages send by SenTestKit 
    // will cause the test to fail since testing the two instances causes it to spawn two test threads with a PID of 
    // one apart from the other. 
    // Edit: Unfortunately this is not possible: It appears that these will be run twice once for GC_ON and once for GC_OFF
    // and only the GC_OFF case has this stupidity attached.
    STAssertTrue([result2 isEqualToString:result1], @"instead '%@' != '%@'", [[result2 quote] truncate], [[result1 quote] truncate]);
    STAssertTrue([[script1 lastResultFromHistory] isEqualToString:[script2 lastResultFromHistory]], @"");
    
    STAssertEqualObjects([script1 history], [script2 history], @"");
    
    STAssertTrue([[script1 history] isKindOfClass:[NSMutableArray class]], @"but is '%@'", NSStringFromClass([[script1 history] class]));
    STAssertTrue([[script2 history] isKindOfClass:[NSMutableArray class]], @"but is '%@'", NSStringFromClass([[script2 history] class]));
    
}

- (void) testStringUtilities {
    
    NSError * error = nil;
    NSString * unquotedString = [NSString stringWithContentsOfFile:rubyConvertToHexTemplatePath encoding:NSUTF8StringEncoding error:&error];
    STAssertNil(error, @"");
    NSString * quotedString = [unquotedString quote];
    
    STAssertTrue([quotedString isEqualToString:@"str = %%{}\\n"
                  @"begin\\n"
                  @"   print \\\"%%#x\\\" %% str\\n"
                  @"rescue\\n"
                  @"   print \\\'Error: Cannot convert to hexadecimal. String not a number?\\\'\\n"
                  @"   print str\\n"
                  @"end"], @"but is '%@'", quotedString);
    
    // if truncate length unspecifified uses a default of 20 or NSSTRING_TRUNCATE_LENGTH if defined
    NSString * truncatedQuotedString = [quotedString truncate];
    
    STAssertTrue([truncatedQuotedString isEqualToString:@"str = %%{}\\n"
                  @"begin\\n"
                  @" ..."], @"but is '%@'", truncatedQuotedString);
    
    // test that too large length returns unmodified string
    NSString * truncatedQuotedString2 = [quotedString truncateToLength:200];
    
    STAssertTrue([truncatedQuotedString2 isEqualToString:quotedString], @"but is '%@'", truncatedQuotedString2);
    
    NSString * truncatedQuotedString3 = [quotedString truncateToLength:30];
    
    STAssertTrue([truncatedQuotedString3 isEqualToString:@"str = %%{}\\n"
                  @"begin\\n"
                  @"   print \\\"..."], @"but is '%@'", truncatedQuotedString3);
    
    NSInteger numPercentageChars = [unquotedString countOccurrencesOfString:@"%"];
    
    STAssertTrue(numPercentageChars == 3, @"but is %i", numPercentageChars);
    
    NSInteger numAUmlautChars = [quotedString countOccurrencesOfString:@"ä"];
    
    STAssertTrue(numAUmlautChars == NSNotFound, @"but is %i", numAUmlautChars);
    
}

- (void) testDictionaryUtilities {
    NSDictionary * someDict = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"1key", @"2", @"2key", nil];
    STAssertTrue([[someDict allKeys] count] == 2, @"but is %d", [[someDict allKeys] count]);
    
    someDict = [someDict dictionaryByAddingObject:@"3" forKey:@"3key"];
    
    STAssertTrue([[someDict allKeys] count] == 3, @"but is %d", [[someDict allKeys] count]);
    STAssertTrue([[someDict objectForKey:@"3key"] isEqualToString:@"3"], @"but is %@", [[someDict objectForKey:@"3key"] isEqualToString:@"3"]);
}

- (void) testMacros {
    BMSynthesizeOptions(@"/usr/local/bin/ruby1.9", @"-EUTF-8", @"-e", nil);
    STAssertTrue([[defaultDict descriptionInStringsFileFormat] 
                    isEqualToString:[alternativeOptions descriptionInStringsFileFormat]], 
                    @"but is '%@'", [defaultDict descriptionInStringsFileFormat]);
}


@end

#undef PATHFOR
#define PATHFOR OLD_PATHFOR
