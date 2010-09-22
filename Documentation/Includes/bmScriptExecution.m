- (ExecutionStatus) execute;  // call -lastResult after completion to obtain the result.
- (ExecutionStatus) executeAndReturnResult:(NSString **)result;
- (ExecutionStatus) executeAndReturnResult:(NSString **)result error:(NSError **)error;
- (void) executeInBackgroundAndNotify; AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER