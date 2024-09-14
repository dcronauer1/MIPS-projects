li $t0,0x00000001		# Set register $t0 = 0x00000001 = 1 in dec
li $t1,0x7fffffff		# Set register $t1 = 0x7fffffff = 2147483647 in dec, max positive value for signed ints

addu $t2,$t0,$t1		# this will overflow to 0x80000000=-2147483648, but it wont throw an exception as it is unsigned addition. 
add $t2,$t0,$t1			# this will throw an overflow exception
