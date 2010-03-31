// You can of course change the script source of an instance after the fact.
// Normally NSTasks are one-shot (not for re-use), so it is convenient that
// BMScript handles all the boilerplate setup for you in an opaque way.

script2.script = @"print \"Halleluja!\";";
[script2 execute];

NSLog(@"script2 new result = %@", [script2 lastResult]);
// script2 new result = Halleluja!

// Of course any execution and its corresponding result are stored in the instance
// local execution history. Take a look at #scriptSourceFromHistoryAtIndex: et al.
// Usage is pretty self explanatory. You can a script source from history by supplying
// an index or you can get the last one executed. Same goes for the execution results.
// Currently the return values (exit codes) are not stored in the history. Might
// be added at a later time, but for now you can just store the TerminationStatus in a
// variable of your own before you do anything else with your BMScript instance.