str = %{<##>}
def decimal(x)
   if /^0x[abcdefABCDEF0123456789]+$/ =~ x
      x.hex
   elsif /^0\\d+$/ =~ x
      x.oct
   else
      'Cannot convert to decimal. String not a hexadecimal or octal number?'
      x
   end
end
print decimal(str)