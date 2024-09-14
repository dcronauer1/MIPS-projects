.data
Num: .word 0				#variable to store user entered integer
Ask: .asciiz "Enter integer:\n" 	#string to output to ask user to enter a number


.text
la $a0,Ask	#load address of prompt string
li $v0,4   	#system call for printing null-terminated string from address
syscall    	#this will output string to console

li $v0,5   	#system call for user inputted integer
syscall		#will prompt for integer and save to $v0	
sw $v0,Num	#save user input to Num

lw $a0,Num	#load integer into $a0 from Num (syscall 35 prints the integer, not the integer's address) 
li $v0,35	#system call to print integer as 32-bit binary
syscall		#print user's integer as 32-bit binary

li $v0,10	#syscall to terminate program
syscall		#end program
