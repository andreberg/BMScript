//
//  BMRubyScript.m
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//

#import "BMRubyScript.h"
#import "BMScript.h"

@implementation BMRubyScript

- (NSString *) defaultScriptSourceForLanguage { 
    return @"print \"BMRubyScript using Ruby v#{RUBY_VERSION}\"";
}

- (NSDictionary *) defaultOptionsForLanguage {
    NSArray * newArgs = [NSArray arrayWithObjects:@"-Ku", @"-e", nil];
    NSDictionary * defaultOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"/usr/bin/ruby", BMScriptOptionsTaskLaunchPathKey, 
                                                 newArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    return defaultOptions;
}

@end
