// register with the default center passing the selector you want called
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:BMScriptTaskDidEndNotification object:nil];

- (void) taskFinished:(NSNotification *)aNotification {
    TerminationStatus status = [[[aNotification userInfo] objectForKey:BMScriptNotificationTaskTerminationStatus] intValue];
    NSString * results = [[aNotification userInfo] objectForKey:BMScriptNotificationTaskResults];
    NSLog(@"inside %s: bgTask finished with status = %ld, result = '%@'", __PRETTY_FUNCTION__, status, [results quote]);
}