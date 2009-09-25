#define BMSynthesizeOptions(path, ...) \
    [NSDictionary dictionaryWithObjectsAndKeys:(path),\
        BMScriptOptionsTaskLaunchPathKey, [NSArray arrayWithObjects:__VA_ARGS__], BMScriptOptionsTaskArgumentsKey, nil]

// Usage:
NSDictionary * defaultOptions = BMSynthesizeOptions(@"/bin/echo", nil);