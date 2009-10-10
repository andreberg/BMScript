BMScript * script2 = [BMScript perlScriptWithSource:@"print 2**64;"];
[script2 executeAndReturnResult:&result2];

NSLog(@"script2 result = %@", result2);
// result: 1.84467440737096e+19