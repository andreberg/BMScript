script2.script = @"print \"Halleluja!\";";
[script2 execute];

NSLog(@"script2 new result = %@", [[script2 lastResult] contentsAsString]);

// script2 new result = Halleluja!
