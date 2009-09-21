// register with the default center passing the selector you want called
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:BMScriptTaskDidEndNotification object:nil];

- (void) taskFinished:(NSNotification *)aNotification {
    TerminationStatus status = [[[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskTerminationStatusKey] intValue];
    NSString * results = [[aNotification userInfo] objectForKey:BMScriptNotificationInfoTaskResultsKey];
    NSLog(@"inside %s: bgTask finished with status = %ld, result = '%@'", __PRETTY_FUNCTION__, status, [results quote]);
}