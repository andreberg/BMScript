#import <Foundation/Foundation.h>
#import "BMRubyScript.h"

NS_INLINE NSString * NSStringFromBOOL(BOOL b) {
    return (b ? @"YES" : @"NO");
}

static BOOL s_taskHasEnded = NO;

@interface ObserverDummy : NSObject <BMScriptLanguageProtocol> {
    
}
- (void) taskFinished:(NSNotification *)aNotification;
@end

@implementation ObserverDummy 

- (void) taskFinished:(NSNotification *)aNotification {
    TerminationStatus status = [[[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskTerminationStatusKey] intValue];
    NSString * results = [[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskResultsKey];
    NSLog(@"task finished with status = %ld, results = %@", status, results);
    s_taskHasEnded = YES;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:BMScriptTaskDidEndNotification object:nil];
        // FIXME: support for bg execution 
        // TIP: read concurrent programming topics
        BMRubyScript * bgScript = [BMRubyScript scriptWithSource:@"print 3**2"];
        [bgScript setDelegate:self];
        //BMRubyScript * bgScript = [[BMScript alloc] init];
        [bgScript executeInBackgroundAndNotify];
    }
    return self;
}

- (BOOL) shouldSetLastResult:(NSString *)aString {
    if ([aString isEqualToString:@"9"]) {
        NSLog(@"LastResult will be set to 9");
        return YES;
    }
    return NO;
}

- (BOOL) shouldSetScript:(NSString *)aScript {
    NSLog(@"%s", _cmd);
    return YES;
}

- (NSDictionary *) defaultOptionsForLanguage {
    SynthesizeOptions(@"/bin/echo", @"using /bin/echo from ObserverDummy", nil);
    return defaultDict;
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end



// ---------------------------------------------------------------------------------------- 
// MARK: MAIN
// ---------------------------------------------------------------------------------------- 


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"MAC_OS_X_VERSION_MIN_REQUIRED = %i", MAC_OS_X_VERSION_MIN_REQUIRED);
    NSLog(@"MAC_OS_X_VERSION_MAX_ALLOWED = %i", MAC_OS_X_VERSION_MAX_ALLOWED);
    
    BOOL success = NO;
    
    ObserverDummy * od = [[ObserverDummy alloc] init];
    
    // test protocol conformance
    BOOL respondsToDefaultOpts = [od respondsToSelector:@selector(defaultOptionsForLanguage)];
    BOOL respondsToDefaultScript = [od respondsToSelector:@selector(defaultScriptSourceForLanguage)];
    BOOL respondsToTaskFinishedCallback = [od respondsToSelector:@selector(taskFinishedCallback:)];
    
    NSLog(@"od conforms to BMScriptLanguageProtocol = %@", NSStringFromBOOL([ObserverDummy conformsToProtocol:@protocol(BMScriptLanguageProtocol)]));
    NSLog(@"od implements all required methods for %@ = %@", @"BMScriptLanguageProtocol", NSStringFromBOOL(respondsToDefaultOpts && respondsToDefaultScript && respondsToTaskFinishedCallback));
    
    BMScript * newScript1 = [[BMScript alloc] init];
    [newScript1 execute];
    NSString * result1 = [newScript1 lastResult];
    NSLog(@"newScript1 result = %@", result1);
    
    BMRubyScript * newScript2 = [[BMRubyScript alloc] initWithScriptSource:@"puts 1+2"];
    NSString * result2;
    success = [newScript2 executeAndReturnResult:&result2];
    
    if (success) {
        NSLog(@"newScript2 result = %@", result2);
    };
    
    
    
    NSArray * newArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    NSDictionary * newOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"/usr/local/bin/ruby1.9", BMScriptOptionsTaskLaunchPathKey, 
                                 newArgs, BMScriptOptionsTaskArgumentsKey, nil];
    NSError * outError;
    NSString * newResult1;
    
    [newScript1 setScript:@"puts \"newScript1 executed\\n ...again with \\\"ruby 1.9\\\"!\""];
    [newScript1 setOptions:newOptions];
    success = [newScript1 executeAndReturnResult:&newResult1 error:&outError];
    
    if (success) {
        NSLog(@"newScript1 new result (unquoted) = %@ (%@)", [newResult1 quote], newResult1);
    }
    
    NSString * path = @"/Users/andre/Documents/Xcode/Command Line Utility/Foundation/+ Tests/BMScriptTest/Convert To Oct.rb";
    
    BMRubyScript * script1 = [BMRubyScript scriptWithContentsOfTemplateFile:path];
    [script1 saturateTemplateWithArgument:@"100"];
    [script1 execute];
    
    NSLog(@"script1 result = %@", [script1 lastResult]);
    
    path = @"/Users/andre/Documents/Xcode/Command Line Utility/Foundation/+ Tests/BMScriptTest/Multiple Tokens Template.rb";
    
    BMRubyScript * script2 = [BMRubyScript scriptWithContentsOfTemplateFile:path];
    [script2 saturateTemplateWithArguments:@"template", @"1", @"tokens"];
    [script2 execute];
    
    NSLog(@"script2 result = %@", [script2 lastResult]);


    if (s_taskHasEnded) {
        [od release];
    } else {
        NSLog(@"*** Warning: ObserverDummy still around. ObserverDummy * od = %@, s_taskHasEnded = %d", od, NSStringFromBOOL(s_taskHasEnded));
    }
    
    NSString * result3;
    NSString * result4;
    
    // alternative options (ruby 1.9)
    NSArray * alternativeArgs = [NSArray arrayWithObjects:@"-EUTF-8", @"-e", nil];
    NSDictionary * alternativeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"/usr/local/bin/ruby1.9", BMScriptOptionsTaskLaunchPathKey, 
                                          alternativeArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    BMRubyScript * script3 = [BMRubyScript scriptWithSource:@"print RUBY_VERSION" options:alternativeOptions];
    [script3 execute];
    result3 = [script3 lastResult];
        
    BMRubyScript * script4 = [BMRubyScript scriptWithSource:[script3 lastScriptSourceFromHistory] options:alternativeOptions];
    [script4 execute];
    result4 = [script4 lastResult];
    
    if (![result3 isEqualToString:result4]) {
        NSLog(@"*** AssertionFailure: result3 should be equal to result4!");
    }
    
    if (![[script3 history] isEqual:[script4 history]]) {
        NSLog(@"*** AssertionFailure: [result3 history] should be equal to [result4 history]");
    }
    
    [newScript1 release];
    [newScript2 release];
        
    [pool drain];
    return 0;
}
