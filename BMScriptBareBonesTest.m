#import <Foundation/Foundation.h>
#import "BMScript.h"
#import "BMRubyScript.h"
#import "ScriptRunner.h"
#include <unistd.h>

#include "BMDefines.h"

BM_DEBUG_RETAIN_INITIALIZE

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    BM_DEBUG_RETAIN_SWIZZLE([ScriptRunner class])
    BM_DEBUG_RETAIN_SWIZZLE([BMScript class])
    
    ScriptRunner * scriptRunner1 = [[ScriptRunner alloc] init];    
    [scriptRunner1 launch];
    
    BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"\"test test\"" options:BMSynthesizeOptions(@"/bin/echo", nil)];
    [script1 execute];
    
    printf("script1 result = %s", [[[script1 lastResult] quote] UTF8String]);
    
    [script1 release];
    [scriptRunner1 release];
    [pool drain];
    
    if (DEBUGS) {
        //NSLog(@"Press return to exit...");
        getchar();
    }
    
    return 0;
}