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

# ENV['SVN_REVISION'] = `svn info | grep Revision | awk '{print $2}'`.chomp!
# ENV['PROJECT_VERSION'] = "%.1f" % (ENV['SVN_REVISION'].to_i / 150.0)

common_git_paths = %w[/usr/local/bin/git /usr/local/git/bin/git /opt/local/bin/git]
git_path = ""
 
common_git_paths.each do |p|
  if File.exist?(p)
    git_path = p
    break
  end
end
 
if git_path == ""
  puts "Error: path to git not found! Setting doc version components to null values."
  ENV['PROJECT_VERSION'] = "v0.0"
  ENV['GIT_COMMIT_COUNT'] = "0"
  ENV['GIT_SHA'] = "000000"
else
   s = `#{git_path} describe --long`

   mat = s.match(/v?(\d\.\d)\-(\d*?)\-(\w+)/)
   if mat && mat.length > 3
      version = mat[1]
      commit_count = mat[2]
      sha = mat[3]
   end
   ENV['PROJECT_VERSION'] = version
   ENV['GIT_COMMIT_COUNT'] = commit_count
   ENV['GIT_SHA'] = sha
end

ENV['PROJECT_NUMBER'] = "v#{ENV['PROJECT_VERSION']} r#{ENV['GIT_COMMIT_COUNT']}"

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