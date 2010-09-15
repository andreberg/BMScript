
// This is the default way of using BMScript:
// Initialize with the designated initializer and supply script and options

BMScript * script1 = [[BMScript alloc] initWithScriptSource:@"\"test test\"" 
                                                    options:BMSynthesizeOptions(@"/bin/echo", @"-n", nil)];
[script1 execute];

NSLog(@"script1 result = %@\n", [[script1 lastResult] quote]);
// result: script1 result = \"test test\"


// Here are a couple of other examples of the blocking execution model:

BMScript * script2 = [BMScript perlScriptWithSource:@"print 2**64;"];
[script2 executeAndReturnResult:&result2];

NSLog(@"script2 result = %@", result2);
// result: 1.84467440737096e+19


// You can of course change the script source of an instance after the fact.
// Normally NSTasks are one-shot (not for re-use), so it is convenient that
// BMScript handles all the boilerplate setup for you in an opaque way.

script2.script = @"print \"Halleluja!\";";
[script2 execute];

NSLog(@"script2 new result = %@", [script2 lastResult]);
// result: Halleluja!

// Of course any execution and its corresponding result are stored in the instance
// local execution history. See the (upcoming) example on the history if you would 
// like more info on that