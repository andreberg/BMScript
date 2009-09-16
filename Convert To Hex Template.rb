str = %{}
begin
   print "%#x" % str
rescue
   print 'Error: Cannot convert to hexadecimal. String not a number?'
   print str
end