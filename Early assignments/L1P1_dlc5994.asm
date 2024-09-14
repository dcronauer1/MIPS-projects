li $t0,1	# Set register $t0 = 1
add $t0,$t0,2	# add 2,3,4,5 to $t0
add $t0,$t0,3
add $t0,$t0,4
add $t0,$t0,5
move $t1,$t0 	# Copy $t0 into register $t1

li  $v0,10
syscall		# Terminate the program 
