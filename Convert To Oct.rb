str = %{255}
begin
   print "%#o" % str
rescue
   print 'Error: Cannot convert to octal. String not a number?'
   print str
end