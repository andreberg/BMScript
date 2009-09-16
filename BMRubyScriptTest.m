#import <Foundation/Foundation.h>
#import "BMRubyScript.h"

void TaskFinished(id obj) {
    NSLog(@"%@", @"task finished");
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"MAC_OS_X_VERSION_MIN_REQUIRED = %i", MAC_OS_X_VERSION_MIN_REQUIRED);
    NSLog(@"MAC_OS_X_VERSION_MAX_ALLOWED = %i", MAC_OS_X_VERSION_MAX_ALLOWED);
    NSLog(@"using %@", BMRS_ACCESSORS);
    
    [[NSNotificationCenter defaultCenter] addObserver:nil selector:@selector(TaskFinished) name:BMScriptTaskDidEndNotification object:nil];
    
    
    // FIXME: support for bg execution 
    // TIP: read concurrent programming topics
    BMRubyScript * bgScript = [BMRubyScript scriptWithSource:@"print 3**2"];
    [bgScript executeInBackgroundAndNotify];
    
    BOOL success = NO;
    
    BMRubyScript * newScript1 = [[BMRubyScript alloc] init];
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
    
    [newScript1 release];
    [newScript2 release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:nil name:BMScriptTaskDidEndNotification object:nil];
    
    [pool drain];
    return 0;
}
