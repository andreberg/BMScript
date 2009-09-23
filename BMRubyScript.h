//
//  BMRubyScript.h
//  ProgrammersFriend
//
//  Created by Andre Berg on 11.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  For license details see end of this file.
//  Short version: licensed under MIT license.
//

/// @cond 
 
#import <Cocoa/Cocoa.h>
#import "BMScript.h"

@interface BMRubyScript : BMScript <BMScriptLanguageProtocol> {

}
- (NSString *) defaultScriptSourceForLanguage;
- (NSDictionary *) defaultOptionsForLanguage;
@end

/// @endcond