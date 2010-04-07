script2.script = @"print \"Halleluja!\";";
[script2 execute];

NSLog(@"script2 new result = %@", [script2 lastResult]);
// script2 new result = Halleluja!
