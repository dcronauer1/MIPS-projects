.data
Num: .word 0:2			#array to store user entered integer and user's integer multiplied by 5
Prompt: .asciiz "Enter integer:\n" 	#string to output to ask user to enter a number

.text
#Prompt
la $a0,Prompt	#load address of prompt string
li $v0,4   	#system call for printing null-terminated string from address
syscall    	#this will output string to console
#Read
li $v0,5   	#system call for user inputted integer
syscall		#will prompt for integer and save to $v0	
sw $v0,Num	#save user input to Num
#Multiply by 5 and store
lw $t1,Num		#load contents of Num into $t0 (for modularity)
sll $t0,$t1,2		# shift left logical by 2 bits to multiply by 4
add $t0,$t1,$t0		# add the original number to 4x to get 5x
sw $t0,Num+4		# store int*5 in Num array
#Print integer*5
lw $a0,Num+4	#load integer multiplied by 5x into $a0 
li $v0,1	#system call to print integer
syscall		#print user's integer*5
li $a0,10	#char to print \n
li $v0,11	#system call to print character
syscall		#print new line

#Bonus - print integer*5 in hex
lw $a0,Num+4	#load integer multiplied by 5x into $a0 
li $v0,34	#system call to print integer*5 as 8 hexadecimal digits
syscall		#print user's integer multiplied by 5 in 8 hex digits


#terminate
li $v0,10	#syscall to terminate program
syscall		#end program
