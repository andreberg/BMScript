//
//  BMRubyScriptUnitTests.m
//  BMRubyScriptTest
//
//  Created by Andre Berg on 13.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

// !!! Andre Berg 20090925: This file has been obsoleted by BMScriptUnitTests.m
// It may be updated to support tests for subclassing BMScript through BMRubyScript

#import <SenTestingKit/SenTestingKit.h>
#import "BMRubyScript.h"

#ifdef PATHFOR
    #define OLD_PATHFOR PATHFOR
    #undef PATHFOR
#endif
#define PATHFOR(name) ([[NSBundle bundleForClass:[self class]] pathForResource:(name) ofType:@"rb"])

@interface BMRubyScriptUnitTests : SenTestCase {
    NSDictionary * defaultOptions;
    NSDictionary * alternativeOptions;    
    NSString * defaultScript;
    NSString * hexScript;
    NSString * decScript;
    NSString * convertToOctPath;
    NSString * convertToHexTemplatePath;
    NSString * convertToDecimalTemplatePath;
}

@end

@implementation BMRubyScriptUnitTests

- (void) setUp {
    NSImageView
    // default options (ruby 1.8)
    NSArray * defaultArgs = [NSArray arrayWithObjects:@"-Ku", @"-e", nil];
    defaultOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"/usr/bin/ruby", BMScriptOptionsTaskLaunchPathKey, 
                             defaultArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    // alternative options (ruby 1.9)
    NSArray * alternativeArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    alternativeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"/usr/local/bin/ruby1.9", BMScriptOptionsTaskLaunchPathKey, 
                                      alternativeArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    // a few scripts to play with...
    defaultScript = @"print \"Ruby Version #{RUBY_VERSION}\"";

    hexScript = [NSString stringWithFormat:@"str = %%{%@}\n"
                                           @"begin\n"
                                           @"  print \"%%#x\" %% str\n"
                                           @"rescue\n"
                                           @"  #print 'Error: Cannot convert to hexadecimal. String not a number?'\n"
                                           @"  print str\n"
                                           @"end\n", 
                                           @"255"];
    
    decScript = [NSString stringWithFormat:@"str = %%{%@}\n"
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
    
    // a few file paths to play with...
    convertToOctPath = PATHFOR(@"Convert To Oct");
    convertToHexTemplatePath = PATHFOR(@"Convert To Hex Template");
    convertToDecimalTemplatePath = PATHFOR(@"Convert To Decimal Template");
}

- (void) tearDown {
    defaultOptions = nil;
    defaultScript = nil;
    hexScript = nil;
    decScript = nil;
    convertToOctPath = nil;
    convertToHexTemplatePath = nil;
    convertToDecimalTemplatePath = nil;
}


- (void) testInitializers {
    
    BMRubyScript * script1 = [[BMRubyScript alloc] init];
    BMRubyScript * script2 = [[BMRubyScript alloc] initWithScriptSource:defaultScript];      
    BMRubyScript * script3 = [[BMRubyScript alloc] initWithScriptSource:defaultScript options:defaultOptions];
    BMRubyScript * script4 = [[BMRubyScript alloc] initWithContentsOfFile:convertToOctPath];      
    BMRubyScript * script5 = [[BMRubyScript alloc] initWithContentsOfFile:convertToOctPath options:defaultOptions];
    
    STAssertNotNil(script1, @"script1 should not be nil but is %@", script1);
    STAssertNotNil(script2, @"script2 should not be nil but is %@", script2);
    STAssertNotNil(script3, @"script3 should not be nil but is %@", script3);
    STAssertNotNil(script4, @"script4 should not be nil but is %@", script4);
    STAssertNotNil(script5, @"script5 should not be nil but is %@", script5);
    
    STAssertTrue([script1 isKindOfClass:[BMRubyScript class]], @"");
    STAssertTrue([script2 isKindOfClass:[BMRubyScript class]], @"");
    STAssertTrue([script3 isKindOfClass:[BMRubyScript class]], @"");
    STAssertTrue([script4 isKindOfClass:[BMRubyScript class]], @"");
    STAssertTrue([script5 isKindOfClass:[BMRubyScript class]], @"");
}

- (void) testFactories {
    
    NSString * result = [NSString string];
    
    BMRubyScript * script1 = [BMRubyScript scriptWithContentsOfFile:convertToOctPath];
    [script1 execute];
    result = [script1 lastResult];
    
    STAssertTrue([result isEqualToString:@"0377"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMRubyScript * script2 = [BMRubyScript scriptWithContentsOfFile:convertToOctPath options:defaultOptions];
    [script2 execute];
    result = [script2 lastResult];
    
    STAssertTrue([result isEqualToString:@"0377"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMRubyScript * script3 = [BMRubyScript scriptWithSource:decScript];
    [script3 execute];
    result = [script3 lastResult];
    
    STAssertTrue([result isEqualToString:@"255"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
    BMRubyScript * script4 = [BMRubyScript scriptWithSource:hexScript options:defaultOptions];
    [script4 execute];
    result = [script4 lastResult];
    
    STAssertTrue([result isEqualToString:@"0xff"], @"but instead is %@", result);
    STAssertFalse([result isEqualToString:@"(null)"], @"but instead is %@", result);
    
}

- (void) testTemplates {
    
    NSString * result;
    NSError * error;
    
    NSString * path = [[NSBundle bundleForClass:[BMRubyScriptUnitTests class]] pathForResource:@"Convert To Hex Template" ofType:@"rb"];
    BMRubyScript * script1 = [BMRubyScript scriptWithContentsOfTemplateFile:path];
    
    STAssertNotNil(script1, @"but instead is %@", script1);
    
    [script1 saturateTemplateWithArgument:[NSString stringWithFormat:@"%li", NSIntegerMax ]];
    [script1 executeAndReturnResult:&result error:&error];
    
    STAssertTrue([result isEqualToString:@"0x7fffffff"], @"but instead is %@", result);
    
    path = [[NSBundle bundleForClass:[BMRubyScriptUnitTests class]] pathForResource:@"Multiple Tokens Template" ofType:@"rb"];
    BMRubyScript * script2 = [BMRubyScript scriptWithContentsOfTemplateFile:path options:defaultOptions];
    
    STAssertNotNil(script2, @"but instead is %@", script1);

    [script2 saturateTemplateWithArguments:@"template", @"1", @"token"];
    [script2 executeAndReturnResult:&result];
    
    STAssertTrue([result isEqualToString:@"a string template with more than 1 replacement also called token\n"], @"but instead is '%@'", [result quote]);
    
    // test exception thrown when template has undefined arguments
    BMRubyScript * script3 = [BMRubyScript scriptWithContentsOfTemplateFile:convertToHexTemplatePath];
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
    
    BOOL success = NO;
    
    // Case 1: 
    // test initalizer for default values
    
    BMRubyScript * script1 = [[BMRubyScript alloc] init];
    success = [script1 execute];

    STAssertTrue(success == YES, @"script1 execution should return YES, but returned %@", (success ? @"YES" : @"NO"));
    STAssertFalse([[script1 lastResult] isEqualToString:@""], @"script1's lastResult shouldn't be equal to an empty string");
    
    // Case 2: 
    // a slightly more complicated script which uses compound return method (more likely real-world scenario)
    
    NSString * script2Result;
    BMRubyScript * script2 = [[BMRubyScript alloc] initWithScriptSource:hexScript];
    success = [script2 executeAndReturnResult:&script2Result];
    
    STAssertTrue([script2Result isEqualToString:@"0xff"], @"script2Result is \"%@\"", script2Result);

    
    // Case 3: 
    // a slightly more complicated script and use compound return method with out error (more likely real-world scenario)
   
    NSString * script3Result;
    NSError * outError;
    
    BMRubyScript * script3 = [[BMRubyScript alloc] initWithScriptSource:decScript];
    success = [script3 executeAndReturnResult:&script3Result error:&outError];

    STAssertTrue([script3Result isEqualToString:@"255"], @"script3Result is \"%@\", outError is \"%@\"", script3Result, outError);
    
    [script1 release];    
    [script2 release];
    [script3 release];
}

- (void) testBackgroundExecution {
    // TODO: background execution
}


- (void) testStateChangeAfterExecution {
    BMRubyScript * script1 = [BMRubyScript scriptWithSource:hexScript];
    [script1 execute];
    
    STAssertTrue([[script1 lastResult] isEqualToString:@"0xff"], @"");
    
    NSError * error;
    
    [script1 setScript:decScript];
    [script1 executeAndReturnError:&error];
    
    STAssertTrue([[script1 lastResult] isEqualToString:@"255"], @"but is '%@'", [script1 lastResult]);
}

- (void) testHistory {
    
    NSString * result1;
    NSString * result2;
    BMRubyScript * script1 = [BMRubyScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
    [script1 execute];
    result1 = [script1 lastResult];
    
    STAssertTrue([[script1 history] count] > 0, @"");
    
    BMRubyScript * script2 = [BMRubyScript scriptWithSource:[script1 lastScriptSourceFromHistory] options:alternativeOptions];
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
    NSString * unquotedString = [NSString stringWithContentsOfFile:convertToHexTemplatePath encoding:NSUTF8StringEncoding error:&error];
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


@end

#undef PATHFOR
#define PATHFOR OLD_PATHFOR