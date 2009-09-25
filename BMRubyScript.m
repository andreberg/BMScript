//
//  BMRubyScript.m
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  For license details see end of this file.
//  Short version: licensed under the MIT license.
//

#import "BMRubyScript.h"
#import "BMScript.h"

@implementation BMRubyScript

- (NSString *) defaultScriptSourceForLanguage { 
    return @"print \"BMRubyScript using Ruby v#{RUBY_VERSION}\"";
}

- (NSDictionary *) defaultOptionsForLanguage {
    NSArray * newArgs = [NSArray arrayWithObjects:@"-Ku", @"-e", nil];
    NSDictionary * defaultOpts = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"/usr/bin/ruby", BMScriptOptionsTaskLaunchPathKey, 
                                                 newArgs, BMScriptOptionsTaskArgumentsKey, nil];
    
    return defaultOpts;
}

@end

/*
 * Copyright (c) 2009 Andre Berg (Berg Media)
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */