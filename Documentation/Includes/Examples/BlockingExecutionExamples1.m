BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"\"test test\"" 
                                                    options:BMSynthesizeOptions(@"/bin/echo", @"-n")];

ExecutionStatus status = [script1 execute];

NSLog(@"script1 status = %@", BMNSStringFromExecutionStatus(status));
NSLog(@"script1 result = %@", [[[script1 lastResult] contentsAsString] quotedString]);
NSLog(@"script1 retVal = %d", [script1 lastReturnValue]);

// script1 status = script finished successfully
// script1 result = \"test test\"
// script1 retVal = 0
