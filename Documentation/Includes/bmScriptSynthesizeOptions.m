#define BMSynthesizeOptions(path, ...) \
    [NSDictionary dictionaryWithObjectsAndKeys:(path),\
        BMScriptOptionsTaskLaunchPathKey, [NSArray arrayWithObjects:__VA_ARGS__, nil], BMScriptOptionsTaskArgumentsKey, nil]

// Usage
NSDictionary * defaultOptions = BMSynthesizeOptions(@"/bin/echo", @""); 

// notice how you must supply at least two parameters to the macro function.
// supply an empty string for the arguments if you do not need to set any.