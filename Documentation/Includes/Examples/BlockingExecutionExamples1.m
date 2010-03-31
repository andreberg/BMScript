// This is the default way of using BMScript:
// Initialize with the designated initializer and supply script and options

BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"\"test test\"" 
                                                    options:BMSynthesizeOptions(@"/bin/echo", @"-n")];
NSInteger retVal = [script1 execute];

NSLog(@"script1 result = %@\n", [[script1 lastResult] quote]);
NSLog(@"script1 retVal = %d\n", retVal);
// script1 result = script1 result = \"test test\"
// script1 retVal = 0
