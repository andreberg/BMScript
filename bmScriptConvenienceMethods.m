// these use default paths and parameters for 10.5 and 10.6
+ (id) rubyScriptWithSource:(NSString *)scriptSource;
+ (id) rubyScriptWithContentsOfFile:(NSString *)path;
+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) pythonScriptWithSource:(NSString *)scriptSource;
+ (id) pythonScriptWithContentsOfFile:(NSString *)path;
+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) perlScriptWithSource:(NSString *)scriptSource;
+ (id) perlScriptWithContentsOfFile:(NSString *)path;
+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path;