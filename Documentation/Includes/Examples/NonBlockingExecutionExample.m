
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
// You can query status (return value, aka exit code) and results through 
// the NSNotification userInfo dictionary.
- (void) taskFinished:(NSNotification *)aNotification {
    
    NSDictionary * infoDict  = [aNotification userInfo];
    TerminationStatus status = [[infoDict objectForKey:BMScriptNotificationTaskTerminationStatus] intValue];
    NSString * results       = [infoDict objectForKey:BMScriptNotificationTaskResults];
    
    NSLog(@"Inside %s: background task finished with status = %ld, result = '%@'", 
            __PRETTY_FUNCTION__, status, [results quote]);
}

// ...

// If you're not using Garbage Collection, DON'T FORGET to remove yourself as observer, ideally 
// right when you're done with BMScript, but at least in your class' dealloc method or your program 
// may crash if the defaultCenter continues to send messages to your dealloc'd class!

// With GC enabled you DO NOT need to remove your class from the defaultCenter since the defaultCenter
// under GC stores connections to your class as "Zeroing Weak References". You can just forget about
// -dealloc or -finalize with regards to removing yourself as observer.
- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}