#define BMSynthesizeOptions(_PATH_, ...) \
    NSDictionary * defaultDict = [NSDictionary dictionaryWithObjectsAndKeys:\
        (_PATH_), BMScriptOptionsTaskLaunchPathKey, [NSArray arrayWithObjects:__VA_ARGS__], BMScriptOptionsTaskArgumentsKey, nil]

// Usage:
BMSynthesizeOptions(@"/bin/echo", nil);