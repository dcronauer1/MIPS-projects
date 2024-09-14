li $t0,0		# Set register $t0 = 0
li $t1,10		# Set register $t1 = 10
li $t2,5		# Set register $t2 = 5 (for loop counter)

jal loop		# jump to for loop
# $t0=10+20+30+40+50=150

li  $v0,10
syscall			# Terminate the program 


loop:
addu $t0,$t0,$t1	# add $t1 to $t0
addiu $t1,$t1,10	# add 10 to $t1
addiu $t2,$t2,-1	# incrament loop
bgtz $t2,loop		# for loop condition
jr $ra			# return to main code