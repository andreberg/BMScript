NSDictionary * defaultDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     @"/bin/ls", BMScriptOptionsTaskLaunchPathKey, 
                              [NSArray arrayWithObjects:@"-la"], BMScriptOptionsTaskArgumentsKey, nil];

// Same as executing '/bin/ls -la' in a shell