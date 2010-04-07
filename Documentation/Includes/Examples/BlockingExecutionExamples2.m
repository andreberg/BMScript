NSString * result2 = nil;
BMScript * script2 = [BMScript perlScriptWithSource:@"print 2**64;"];
NSInteger retVal = [script2 executeAndReturnResult:&result2];

NSLog(@"script2 result = %@", result2);
NSLog(@"script2 retVal = %d", retVal);
// script2 result = 1.84467440737096e+19
// script2 retVal = 0
