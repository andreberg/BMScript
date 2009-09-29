// - register with the default center passing the selector you want called
// - if you have multiple BMScript instances pass the instance you want to 
//   register for instead of nil as the "object"
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(taskFinished:) 
                                             name:BMScriptTaskDidEndNotification 
                                           object:nil];

- (void) taskFinished:(NSNotification *)aNotification {
    
    NSDictionary * infoDict = [aNotification userInfo];
    TerminationStatus status = [[infoDict objectForKey:BMScriptNotificationTaskTerminationStatus] intValue];
    NSString * results = [infoDict objectForKey:BMScriptNotificationTaskResults];
    
    NSLog(@"inside %s: background task finished with status = %ld, result = '%@'", __PRETTY_FUNCTION__, status, [results quote]);
}

// DON'T FORGET to unregister in your class' dealloc method or your program might crash
// if the defaultCenter continues to send messages to your dealloc'ed class!
- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}