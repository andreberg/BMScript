// these use OS default paths and arguments
+ (id) rubyScriptWithSource:(NSString *)scriptSource;
+ (id) rubyScriptWithContentsOfFile:(NSString *)path;
+ (id) rubyScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) pythonScriptWithSource:(NSString *)scriptSource;
+ (id) pythonScriptWithContentsOfFile:(NSString *)path;
+ (id) pythonScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) perlScriptWithSource:(NSString *)scriptSource;
+ (id) perlScriptWithContentsOfFile:(NSString *)path;
+ (id) perlScriptWithContentsOfTemplateFile:(NSString *)path;

+ (id) shellScriptWithSource:(NSString *)scriptSource;
+ (id) shellScriptWithContentsOfFile:(NSString *)path;
+ (id) shellScriptWithContentsOfTemplateFile:(NSString *)path;