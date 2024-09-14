.data
InputPrompt1: 	.asciiz "Enter 1st Number: "
InputPrompt2: 	.asciiz "Enter 2nd Number: "
OperatorPrompt:	.asciiz "Select Operator: "
ResultPrompt: 	.asciiz "Result: ","Remainder: "
Invalid: 	.asciiz "Invalid, "
DivideBy0: 	.asciiz "Div by 0"
Entry:		.asciiz "Entry"
Nums: 		.word 0:2	#Array to store user entered integers
Ans: 		.word 0:2	#Array to store answer and remainder		
buffer: .byte 0:80
.text
main:
li $t0,-1
sw $t0,Ans+4		#if remainder <0, remainder isnt applicable
li $s6,100		#use this as the decimal offset (default 2 decimal places)
#Input1
la $a0 InputPrompt1
la $a1 Nums
jal GetInput		#P&R first num

#Operator
la $a0 OperatorPrompt
jal GetOperator		#P&R operator

#Input2
la $a0 InputPrompt2
la $a1 Nums+4
jal GetInput		#P&R first num

#Math logic#
#Load addresses into procedure paramaters
la $a0 Nums
la $a1 Nums+4
la $a2 Ans
la $a3 Ans+4		#Set up remainder address

#Check which operation to perform
la $ra,jAns		#Set return address to jAns
beq $v1,43,AddNumb
beq $v1,45,SubNumb
li $s6,10000		#decimal pts will be 4 for mult instead of 2
beq $v1,42,MultNumb
li $s6,0		#decimal pts will be 0 for div instead of 2
beq $v1,47,DivNumb
j main #failsafe, should never execute


#Display Ans
jAns:
la $a0, ResultPrompt
la $a1, Ans
la $a2,buffer
li $t0,0x000A
sw $t0,0($a2)		#store string for \n\0 in buffer
jal DisplayNumb		#Show answer
#Remainder Ans
lw $t0 Ans+4		#Load remainder into $t0
move $s5,$s6	#store decimal offset for EqnPrint (as remainder will change it)
bltz,$t0,jNoRemainder	#If remainder is <0, then there is no remainder, so skip that part
    la $a1 Ans+4	#Load remainder # into $a1
    la $a0 ResultPrompt+0x09
    li $s6,100		#decimal pts will be 2 for remainder
    li $t0,0x000A
    sw $t0,0($a2)	#store string for \n\0 in buffer
    jal DisplayNumb	#Show remainder
jNoRemainder:
la $a0 Nums
la $a1 Nums+4
la $a2 Ans
la $a3 Ans+4
move $s6,$s5		#set $s6 back to decimal count of answer
jal EqnPrint		#run EqnPrint
j main			#loop main
#End main---------------------------------

GetInput:
#Displays a prompt to the user and then wait for a numerical input
#Input: $a0 points to the text string that will get displayed to the user
#Input: $a1 points to a word address in .data memory, where to store the input number
#Input: $a2 points to buffer in .data (included in procedure since its a generic buffer)
la $a2, buffer		#remove this line to manually pass in the buffer address
move $a3,$a1
li $v0 4
syscall			#Output string $a0 in console

move $a0,$a2		#move buffer address to $a0 for syscall
#The user’s input will get stored to the (word) address pointed by $a1
li $v0, 8			
syscall 		#Syscall for read string

#convert user input
li $t0,0
li $t9,10		#store 10 for mult func
li $t8,0		#bool for neg num
li $t7,3		#counter for decimal point
li $t6,0		#used as a temp return adress
#check for negative sign 
lbu $t1, 0($a2)		
beq $t1, 0x2D, thereIsNegNum
j giWhile		#no negative sign
thereIsNegNum:
li $t8,1
addiu $a2,$a2,1		#advance pointer

#start loop
giWhile:
	la $t6,giWhile		#store return address of giWhile in $t6
	beq $t7,2,giBreak1Loop	#there are 2 decimal point nums, so ignore other nums and break
	lbu $t1, 0($a2)
	addiu $a2,$a2,1		#advance pointer

	beq $t1,0x2E,giSetCounterZero	#decimal point found
	beq $t1,0xA,giBreak1Loop#no decimal point (newline char)
	beq $t1,$0,giBreak1Loop	#no decimal point (null char)
	#convert to decimal
	bgtu $t1,0x39,giError1
	bltu $t1,0x30,giError1	#if t1 not within 0x30-0x39 error

	subiu $t3,$t1,0x30	#convert ascii to dec

	bgtu $t3,9,giError1
	bltu $t3,0,giError1	#if t3<0 or >9 error

	mulu $t0,$t0,$t9	
	addu $t0,$t0,$t3	#mult by 10 and add new value
	
	addiu $t7,$t7,1		#incrament count
	j giWhile		#loop

giBreak1Loop:
	la $t6,giBreak1Loop	#store return address of giBreak1Loop in $t6
	bgtu $t7,2,giSetCounterZero #counter >2, which means there is no dec, so set $t8=0
	#for: if $t8=0 then mult 100, if $t8=1 then mult 10, if $t8=2 do nothing. if $t8>2 mult by 100
	beq $t7,2,giBreak2	#break when counter =2
	mulu $t0,$t0,$t9	#mult by 10
	addiu $t7,$t7,1		#incrament
	j giBreak1Loop		#loop

giBreak2:
	beq $t8,0,giNoNegNum	#check if number negative
	neg $t0,$t0		#make number negative

giNoNegNum:
	sw $t0,0($a3)		#store user variable
	jr $ra			#return to main


giSetCounterZero:
	li $t7,0		#set counter to 0
	jr $t6			#return to loop

giError1:
	la $a1, Entry
	j Error

#End GetInput-----------------------------

GetOperator:
#Displays a prompt to the user and then wait for a single character input
#Input: $a0 points to the text string that will get displayed to the user
#Returns the operator in $v1 (as an ascii character)
li $v0, 4
syscall			#Output string $a0 in console
 
li $v0, 12			
syscall 		#Syscall to read char
move $v1,$v0		#copy operator char from $v0 to $v1
move $t0,$a0		#temporarily store $a0 if char is invalid

li $v0, 11
la $a0, 10
syscall			#output newline in console

#logic to check if it is a valid operator
beq $v1,43,jIfVaildOperator
beq $v1,45,jIfVaildOperator
beq $v1,42,jIfVaildOperator
beq $v1,47,jIfVaildOperator

#invalid char#
la $a0,Invalid
li $v0 4
syscall			#Output "Invalid, "
move $a0,$t0		
j GetOperator		#rerun GetOperator when unvalid operator is entered
#Note: I dont call Error here to avoid weird issues happening, since this reruns GetOperator instead of main

jIfVaildOperator:
jr $ra
#End GetOperator--------------------------

DisplayNumb:
#Displays a message to the user followed by a numerical value
#Inout: $a0 points to a string in .data that will print before the number
#Input: $a1 points to a word address in .data memory, where the input value is stored
#Inout: $a2 points to a string in .data that will print after the number
#Inupt: $s6 is the offset for the number ($s6=100 -> 11.11)

move $t9,$s6		#counter variable
li $v0 4
syscall			#output first string in console


#print number here

#handle negative num:
lw $t0,0($a1)		#load number into $t0
bgez $t0,dnNotNegative	#check if number is negative
li $v0,11
li $a0,0x2D
syscall			#print "-"
neg $t0,$t0		#make $t0 positive

dnNotNegative:
#check for offset
bgtz $s6,dnOffset
li $v0 1
move $a0,$t0
syscall			#print number with no offset
j dnEnd			#print out the 2nd string then return

dnOffset:
#negative was handled, number is confirmed to have an offset
li $v0 1
div $t2,$t0,$s6		#pre decimal number
rem $t3,$t0,$s6		#post decimal number
move $a0,$t2
syscall			#print pre decimal

li $v0,11
li $a0,0x2E
syscall			#print "."
divu $t9,$t9,10		#reduce counter by factor of 10

li $v0 1		#syscall to print int
dnLoop:
move $t0,$t3		#take new number and put it in $t0
div $t2,$t0,$t9		#this decimal
rem $t3,$t0,$t9		#next number to divide
move $a0,$t2
syscall			#print post decimal digit
divu $t9,$t9,10		#reduce counter by factor of 10
bgtz $t9,dnLoop		#loop if counter greater than 0 there are more decimal places

dnEnd:			#jump for no offset
li $v0, 4
move $a0,$a2
syscall			#output second string in console

jr $ra
#End DisplayNumb--------------------------

AddNumb:
#Add two data values and store the result back to memory: 0($a2) = 0($a0) + 0($a1)
#Input: $a0 points to a word address in .data memory for the first data value
#Input: $a1 points to a word address in .data memory for the second data value
#Input: $a2 points to a word address in .data memory, where to store the result
lw $t0,0($a0)
lw $t1,0($a1)
add $t2,$t0,$t1
sw $t2,0($a2)
jr $ra
#End AddNumb------------------------------

SubNumb:
#Subtract two data values and store the result back to memory: 0($a2) = 0($a0) - 0($a1)
#Input: $a0 points to a word address in .data memory for the first data value
#Input: $a1 points to a word address in .data memory for the second data value
#Input: $a2 points to a word address in .data memory, where to store the result
lw $t0,0($a0)
lw $t1,0($a1)
sub $t2,$t0,$t1
sw $t2,0($a2)
jr $ra
#End SubNumb------------------------------

MultNumb:
#Multiply two data values and store the result back to memory: 0($a2) = 0($a0) * 0($a1)
#Input: $a0 points to a word address in .data memory for the first data value
#Input: $a1 points to a word address in .data memory for the second data value
#Input: $a2 points to a word address in .data memory, where to store the result
lw $t0,0($a0)
lw $t1,0($a1)		#Load nums into temp registers

#Determine if the result should be negative
slt $t6,$t0,$zero	#$t7=1 if num1<0
slt $t7,$t1,$zero	#$t6=1 if num2<0
xor $t6,$t6,$t7		#XOR to determine if ans will be + or -

#Make both numbers positive
abs $t0,$t0		#Take absolute value of $t0
abs $t1,$t1		#Take absolute value of $t1

#Multiply using add/shift method
move $t2,$zero		#Initialize product to 0
mMultiply:
beqz $t1,mDoneMult	#If multiplier is 0, multiplication is done
andi $t3,$t1,1		#Check LSB of multiplier
beqz $t3,mShift		#If LSB is 0, just shift
add $t2,$t2,$t0		#Add multiplicand to product if LSB is 1

mShift:
sll $t0,$t0,1		#Shift multiplicand left
srl $t1,$t1,1		#Shift multiplier right
j mMultiply		#repeat

mDoneMult:
beqz $t6,mStoreResult	#If result should be positive, skip negation
neg $t2,$t2		#Negate the result to make it negative

mStoreResult:
sw $t2,0($a2)		#Store the result back to memory
jr $ra			#return
#End MultNumb-----------------------------

DivNumb:
#Divide two data values and store the quotient and remainder back to memory
#Input: $a0 points to a word address in .data memory for the first data value
#Input: $a1 points to a word address in .data memory for the second data value
#Input: $a2 points to a word address in .data memory, where to store the quotient
#Input: $a3 points to a word address in .data memory, where to store the remainder
lw $t0,0($a0)		#Load dividend
lw $t1,0($a1)		#Load divisor

beqz $t1,dDiv0		#Check for division by zero

#Make both numbers positive and store the original signs
slt $t6,$t0,$zero	#$t6=1 if dividend is negative
slt $t7,$t1,$zero	#$t7=1 if divisor is negative
abs $t0,$t0		#Take absolute value of $t0
abs $t1,$t1		#Take absolute value of $t1

#Initialize register for the division process
move $t2,$zero		#Quotient

dDivLoop:
blt $t0,$t1,dHandleSigns#If dividend < divisor, end division
sub $t0,$t0,$t1		#Subtract divisor from dividend
addi $t2,$t2,1		#Increment quotient
j dDivLoop		#Repeat

dHandleSigns:
beqz $t0,dRemainder0	#When remainder is 0, only worry about sign of quotient
#Handle all 4 cases here (-/-,+/-,-/+,+/+). Handling as if remainders cant be negative
beqz $t6,dPosDividend
beqz $t7,dNegDividendPosDivisor
## -/- here
addiu $t2,$t2,1		#add 1 to quotient
subu $t0,$t1,$t0	#remainder=divisor-remainder
j dstoreResult

dPosDividend:
beqz $t7,dstoreResult # +/+, do nothing
## +/- here
neg $t2,$t2		#negative quotient
j dstoreResult

dNegDividendPosDivisor:
## -/+ here
addiu $t2,$t2,1		#add 1 to quotient
subu $t0,$t1,$t0	#remainder=divisor-remainder
neg $t2,$t2		#negative quotient
j dstoreResult

dRemainder0:
xor $t6,$t6,$t7		#Check if signs are different
beqz $t6,dstoreResult	#If signs are not different, skip negation.
neg $t2,$t2		#Negate the result to make it negative, then continue to store result
	#end dHandleSigns---------------------

dstoreResult:
sw $t2,0($a2)		#Store the quotient
sw $t0,4($a2)		#Store the remainder
jr $ra			#return

#Error: divide by 0
dDiv0:
la $a1, DivideBy0
j Error

#End DivNumb-------------------------------

EqnPrint:
#Displays the equation, followed by the answer
#Input: $a0 points to a word address in .data memory for the first data value
#Input: $a1 points to a word address in .data memory for the second data value
#Input: $a2 points to a word address in .data memory, result/quotient
#Input: $a3 points to a word address in .data memory, where the remainder is stored
#Input: $v1 stores the operator used as a ascii char
#Input: $s6 is the decimal offset the answer has (procedure will finish with $s6 being same as inputted $s6)

sw $a1,4($sp)		#store address of second number in 4($sp)
sw $a2,8($sp)		#store address of result/quotient in 8($sp)
move $a1,$a0		#store address of first number in $a1
sw $ra,0($sp)		#store return address to stack
sw $s6,12($sp)		#store decimal offset of answer in 12($sp)

#print "[num1] [operator] "
li $t2,0x00
la $a0, buffer
sb $t2,0($a0)		#store \0 in buffer
li $s6,100		#two decimal places
li $t2,0x00200020	#ascii " \0 \0"
move $t3,$v1		#move operator to temp register
sll $t3,$t3,8		#0x[operator]00
addu $t2,$t2,$t3	#ascii " [operator] \0"
la $a2, buffer+4
sw $t2,($a2)		#store " [operator] \0" to buffer+4
jal DisplayNumb		#Print "[num1] [operator] " with 2 decimal places

#print "[num2] = "
la $a0, buffer		#should still be \0
lw $a1,4($sp)		#load address of second number into $a1
li $t2,0x00203D20	#ascii " = \0"
la $a2, buffer+4
sw $t2,0($a2)		#store " = \0" to buffer+4
jal DisplayNumb		#Print "[num2] = " with 2 decimal places

#print "[answer]"
la $a0, buffer		#should still be \0
lw $s6,12($sp)		#decimal place offset for answer
lw $a1,8($sp)		#load address of answer into $a1

#determine if answer should end with \0 or \n\n\0, depending on if division was used
li $t2,0x00		#ascii "\0"
beq $v1,47,eqprDontAddNewLines#check if "/" was used, if it was then remainder print section will handle newlines.
li $t2,0x000A0A		#ascii"\n\n\0"
eqprDontAddNewLines:
la $a2, buffer+4
sw $t2,0($a2)		#store "\0" or "\n\n\0" to buffer+4 
jal DisplayNumb		#Print "[answer]" or "[answer]\n\n" with originally passed in decimal places

#print " r[remainder]" if applicable
bne $v1,47,eqprtNoRemainder #check if "/" was used, if not jump ahead.
li $s6,100		#two decimal places for remainder
move $a1,$a3		#store address of remainder in $a1
li $t2,0x007220		#ascii " r\0"
la $a0, buffer+4
sw $t2,0($a0)		#store " r\0" to buffer+4 ($a0)
li $t2,0x000A0A		#ascii"\n\n\0"
la $a2, buffer		#$a2 points to buffer
sw $t2,0($a2)		#store "\n\n\0" to buffer ($a2)
jal DisplayNumb		#Print " r[remainder]\n\n" with 2 decimal places
eqprtNoRemainder:

lw $s6,12($sp)		#set $s6 back to decimal places of answer to keep things consistent
lw $ra, 0($sp)		#load return address from stack
jr $ra			#return
#End EqnPrint---------------------------------

Error:
#Sends an error in console and then jumps to main
#Input: $a1 points to error string
li $v0,4
la $a0,buffer
li $t0,0x3A524545
sw $t0,0($a0)
li $t0,0x0020
sw $t0,4($a0)
syscall			#output "ERR: "
move $a0,$a1
syscall			#Send error string to console	
li $v0, 11
la $a0, 10
syscall			#newline
j main			#jump back to main
#End Error-------------------------------
