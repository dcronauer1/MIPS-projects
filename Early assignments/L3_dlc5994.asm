.data
Prompt: .asciiz "Enter two integers:"	#Prompt string
Outputfile: .asciiz "Lab3.txt"
StrToSave: .asciiz ""
Num:    .word 0:2			#Array to store user entered integers
Ans:	.word 0  
Buffer: .word 0				#Reserve space for output string

.text
main:
#Prompt
la $a0, Prompt			#Load address of prompt string
li $v0, 4			#System call for printing null-terminated string from address
syscall				#This will output string to console
jal newline			#calls newline function

#Read
li $v0, 5			#System call for user inputted integer
syscall 			#Will prompt for integer and save to $v0   
sw $v0, Num			#Save user input to Num[0]
li $v0, 5			#System call for user inputted integer
syscall				#Will prompt for integer and save to $v0   
sw $v0, Num+4			#Save user input to Num[1]

#Load numbers from memory
lw $t0, Num			#Load first number into $t0
lw $t1, Num+4			#Load second number into $t1

#Multiply using add/shift method
move $t2, $t0			#Copy of first number (multiplicand)
move $t3, $t1			#Copy of second number (multiplier)
move $t4, $zero			#Initialize product to 0

multiply:
beqz $t3, print_result		#If multiplier is 0, multiplication is done
andi $t5, $t3, 1		#Check LSB of multiplier
beqz $t5, shift			#If LSB is 0, just shift
add $t4, $t4, $t2		#Add multiplicand to product if LSB is 1

shift:
sll $t2, $t2, 1			#Shift multiplicand left
srl $t3, $t3, 1			#Shift multiplier right
j multiply			#Repeat

#Save and print decimal result
print_result:
sw $t4, Ans
li $v0, 1
move $a0, $t4
syscall
jal newline			#Calls newline function

#Convert decimal answer into base32

lw $a0, Ans			#Read decimal number 

#Initialize variables
li $t0, 32			#Maximum number of digits in base32
li $t1, 0			#Counter for number of digits
li $t3, 0			#Index for storing digits in buffer

#Conversion loop
convert_loop:
beq $a0, $zero, done_convert	#Exit loop if input is 0
andi $t2, $a0, 31		#Get last 5 bits of decimal number

#Map decimal digit to base32 character
addi $t2, $t2, 48		#Adjust for ASCII '0'
blt $t2, 58, digit_to_char	#If digit is 0-9, just convert it
addi $t2, $t2, 7		#Adjust for ASCII 'A' to align to '0'

digit_to_char:
sb $t2, Buffer($t3)		#Store character in buffer
addi $t3, $t3, 1		#Increment buffer index

srl $a0, $a0, 5			#Shift right by 5 bits to get next digit
addi $t1, $t1, 1		#Increment digit counter

				
bne $t1, $t0, convert_loop	#Check if all digits have been converted

done_convert:
sb $zero, Buffer($t3)		#Null-terminate the buffer

#Reverse the characters in the buffer
li $t4, 0			#Initialize start index
move $t5, $t3			#End index is one less than the buffer length
addi $t5, $t5, -1

reverse_loop:
bge $t4, $t5, print_buffer	#If start index >= end index, we are done
lb $t6, Buffer($t4)		#Load character at start index
lb $t7, Buffer($t5)		#Load character at end index
sb $t7, Buffer($t4)		#Store character from end at start index
sb $t6, Buffer($t5)		#Store character from start at end index
addi $t4, $t4, 1		#Increment start index
addi $t5, $t5, -1		#Decrement end index
j reverse_loop

print_buffer:
#Print the base32 representation
li $v0, 4
la $a0, Buffer
syscall


jal newline			#Calls newline function


#output to file
li $v0, 13			#Open file syscall
la $a0, Outputfile		#Load address of filename
li $a1, 1			#Mode: 1 for write, 0 for read
li $a2, 0			#Permissions: ignored when opening existing file
syscall				#Open the file

move $a0, $v0			#Move file descriptor to $a0
li $v0, 15			#Write file syscall
la $a1, Buffer			#Load address of buffer
li $a2, 32			#Number of bytes to write
syscall				#Write to the file

li $v0, 16			#Close file syscall
syscall				#Close the file


j main				#Restart program

#Function(s)
newline:			#Print newline function
li $v0, 11
la $a0, 10
syscall
jr $ra
