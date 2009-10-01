//
//  BMRubyScript.h
//  BMRubyScript.m
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Cocoa/Cocoa.h>
#import "BMScript.h"

@interface BMRubyScript : BMScript <BMScriptLanguageProtocol> {
    
}
- (NSString *) defaultScriptSourceForLanguage;
- (NSDictionary *) defaultOptionsForLanguage;
@end


@implementation BMRubyScript

- (NSString *) defaultScriptSourceForLanguage { 
    // of course you can change the script to execute anytime with
    // bmRubyScriptInstance.script = @"some script"
    return @"print \"BMRubyScript using Ruby v#{RUBY_VERSION}\"";
}

- (NSDictionary *) defaultOptionsForLanguage {
    NSArray * newArgs = [NSArray arrayWithObjects:@"-Ku", @"-e", nil];
    
    NSDictionary * defaultOpts = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"/usr/bin/ruby", BMScriptOptionsTaskLaunchPathKey, 
                                           newArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    return defaultOpts;
    // or return BMSynthesizeOptions(@"/usr/bin/ruby", @"-Ku", @"-e");
}

@end
