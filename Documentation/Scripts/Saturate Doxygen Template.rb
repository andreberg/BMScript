#!/usr/bin/env ruby -wKu
# 
#  Saturate Doxygen Template
#  Xcode Build Scripts
#  
#  Created by Andre Berg on 2009-09-30.
#  Copyright 2009 Berg Media. All rights reserved.
# 
#  Saturates a Doxyfile template with values 
#  from .xcconfig files.
#

XCODE = true

# these should be set from the .xcconfig files but I did not succeed in
# getting the needed inline shell script output. So we set those from here...

# FIXME: replace svn based code with git version
# ENV['SVN_REVISION'] = `svn info | grep Revision | awk '{print $2}'`.chomp!
# ENV['PROJECT_VERSION'] = "%.1f" % (ENV['SVN_REVISION'].to_i / 150.0)

#ENV['GIT_REVISION'] = `git describe`
ENV['GIT_REVISION'] = "100"
ENV['PROJECT_VERSION'] = "0.1"
ENV['PROJECT_NUMBER'] = "#{ENV['PROJECT_VERSION']} (r#{ENV['SVN_REVISION']})"

if XCODE
   puts "Replacing variables in DOXYFILE template"
   doxyfile_path = "#{ENV['DOCROOT']}/#{ENV['DOXYFILE']}"
   doxyfile_template_path = "#{ENV['DOCROOT']}/#{ENV['DOXYFILE_TEMPLATE']}"
else
   doxyfile_template_path = "/Users/andre/Documents/Xcode/CommandLineUtility/Foundation/+Tests/BMScriptTestSVN/trunk/DoxyfileTemplate"
end
doxyfile_contents = File.read(doxyfile_template_path)

puts "doxyfile_template_path = \"#{doxyfile_template_path}\"" if $DEBUG

if XCODE
   # a hash table is perfect for storying what need to be unique symbols
   # a symbol on this case is one build setting shell variable (i.e. $DOCROOT)
   # which must be replaced
   symbols = Hash.new()
   
   doxyfile_contents.each_line do |line|
      if /\$([A-Z_]+)/.match(line)
         matchdata = $~
         symbols["$#{matchdata[1]}"] = ENV[matchdata[1]]
      end
   end
   
else
   symbols = {"$DOCROOT" => "/Users/andre/Documents/Xcode/CommandLineUtility/Foundation/+Tests/BMScriptTestSVN/trunk", "$DOXYGEN_RES_PATH" => "/Developer/Applications/Utilities/Third-Party/Doxygen.app/Contents/Resources", "$DOT_PATH" => "/opt/local/bin"}
end

puts "symbols = '#{symbols.inspect}'" if $DEBUG

symbols.each_pair do |key, value|
   if value
      doxyfile_contents.gsub!(key, value)
   else
      doxyfile_contents.gsub!("#{key}", "#{key}")
   end
end

if $DEBUG
   puts "doxyfile_contents = '#{doxyfile_contents}'" 
else
   doxyfile_new = File.open("#{doxyfile_path}", "w")
   doxyfile_new.write(doxyfile_contents)
   doxyfile_new.close
end