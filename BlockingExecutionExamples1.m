BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"\"test test\"" 
                                                    options:BMSynthesizeOptions(@"/bin/echo", @"-n", nil)];
[script1 execute];

NSLog(@"script1 result = %@\n", [[script1 lastResult] quote]);
// result: script1 result = \"test test\"