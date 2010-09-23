#define BMSynthesizeOptions(path, ...) \
    [NSDictionary dictionaryWithObjectsAndKeys:(path),\
        BMScriptOptionsTaskLaunchPathKey, [NSArray arrayWithObjects:__VA_ARGS__, nil], BMScriptOptionsTaskArgumentsKey, nil]

// Usage
NSDictionary * defaultOptions = BMSynthesizeOptions(@"/bin/echo", @""); 