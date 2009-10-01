
// Register with the default center passing the selector you want called.
// If you have multiple BMScript instances pass the instance you want to 
// register for instead of nil as the "object".
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(taskFinished:) 
                                             name:BMScriptTaskDidEndNotification 
                                           object:nil];

// ...

// Meanwhile, in your class...

// Your selector will be called once the task has finished. 
// You can query status and results through the NSNotification userInfo dictionary.
- (void) taskFinished:(NSNotification *)aNotification {
    
    NSDictionary * infoDict = [aNotification userInfo];
    TerminationStatus status = [[infoDict objectForKey:BMScriptNotificationTaskTerminationStatus] intValue];
    NSString * results = [infoDict objectForKey:BMScriptNotificationTaskResults];
    
    NSLog(@"Inside %s: background task finished with status = %ld, result = '%@'", 
            __PRETTY_FUNCTION__, status, [results quote]);
}

// ...

// DON'T FORGET to remove yourself as observer in your class' dealloc method 
// or your program might crash if the defaultCenter continues to send messages 
// to your dealloc'ed class!
- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}