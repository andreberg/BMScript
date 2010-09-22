// Observe that even though you could just pass nil for the options
// (yielding the same effect) it is usually better to supply the 
// options as you will make your intent clear.

BMScript * script3 = [[BMScript alloc] initWithTemplateSource:@"This is a <#KEYWORD#> template. <#ADJECTIVE#> stuff." 
                                                      options:BMSynthesizeOptions(@"/bin/echo", @"-n")];

// Before we can execute the script we need to saturate it first, 
// e.g. fill it with values for the keywords. Otherwise we'd get
// an exception which would tell us that we need to saturate the
// template before execution.

NSDictionary * keywordDict = [NSDictionary dictionaryWithObjectsAndKeys:@"keyword-based", @"KEYWORD", 
                                                                        @"Neat", @"ADJECTIVE", nil];
[script3 saturateTemplateWithDictionary:keywordDict];


// Now that we have saturated the template we can execute it:

ExecutionStatus status = [script3 executeAndReturnResult:&result2];

NSLog(@"script3 status = %@", BMNSStringFromExecutionStatus(status));
NSLog(@"script3 result = %@", result2);
NSLog(@"script3 retVal = %d", [script3 lastReturnValue]);

// script3 status = script finished successfully
// script3 result = This is a keyword-based template. Neat stuff.
// script3 retVal = 0
