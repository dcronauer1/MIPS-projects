.data
InputPrompt1: 	.asciiz "Enter 1st Number: "
InputPrompt2: 	.asciiz "Enter 2nd Number: "
OperatorPrompt:	.asciiz "Select Operator: "
ResultPrompt: 	.asciiz "Result: ","Remainder: "
Invalid: 	.asciiz "Invalid, "
DivideBy0: 	.asciiz "Div by 0"
Nums: 		.word 0:2	#Array to store user entered integers
Ans: 		.word 0:2	#Array to store answer and remainder		

.text
main:
li $t0,-1
sw $t0,Ans+4		#if remainder <0, remainder isnt applicable

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
beq $v1,42,MultNumb
beq $v1,47,DivNumb
j main #failsafe, should never execute


#Im assuming the bonus is supposed to run alongside the required answer display?
#My other assumption would've been set $s6=-2 before main,++ it at the start of jAns, and then "bgtz $s6,Bonus" right after

#Display Ans
jAns:
la $a0 ResultPrompt
la $a1 Ans
jal DisplayNumb		#Show answer
#Remainder Ans
lw $t0 Ans+4		#Load remainder into $t0
bltz,$t0,jNoRemainder	#If remainder is <0, then there is no remainder, so skip that part
    la $a1 Ans+4	#Load remainder # into $a1
    la $a0 ResultPrompt+0x09
    jal DisplayNumb	#Show remainder
jNoRemainder:
la $a0 Nums
la $a1 Nums+4
jal Bonus		#run bonus, #$a3 and $a4 will still be what they need to be in current setup
j main			#loop main
#End main---------------------------------





GetInput:
#Displays a prompt to the user and then wait for a numerical input
#Input: $a0 points to the text string that will get displayed to the user
#Input: $a1 points to a word address in .data memory, where to store the input number

li $v0 4
syscall			#Output string $a0 in console

#The user’s input will get stored to the (word) address pointed by $a1
li $v0, 5			
syscall 			 
sw $v0,0($a1)		#store user variable

jr $ra
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

jIfVaildOperator:
jr $ra
#End GetOperator--------------------------

DisplayNumb:
#Displays a message to the user followed by a numerical value
#Input: $a0 points to the text string that will get displayed to the user
#Input: $a1 points to a word address in .data memory, where the input value is stored
li $v0 4
syscall			#output $a0 in console

li $v0 1
lw $a0,0($a1)
syscall			#output $a1 in console

li $v0, 11
la $a0, 10
syscall			#output newline in console

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
li $v0,4
la $a0,Invalid
syscall			#"Invalid: "
la $a0, DivideBy0
syscall			#"Divide By 0"	
li $v0, 11
la $a0, 10
syscall			#newline
j main

#End DivNumb-------------------------------

Bonus:
#Displays the equation, followed by the answer
#Input: $a0 points to a word address in .data memory for the first data value
#Input: $a1 points to a word address in .data memory for the second data value
#Input: $a2 points to a word address in .data memory, where to store the result/quotient
#Input: $a3 points to a word address in .data memory, where to store the remainder
#Input: $v1 stores to the operator used as a ascii char

li $v0 1
lw $a0,0($a0)		#Get num1 from address $a0
syscall			#output num1 in console

li $v0 11
li $a0 32
syscall			#Print " "

move $a0 $v1
syscall			#Print operator

li $a0 32
syscall			#Print " "

li $v0 1
lw $a0,0($a1)		#Get num2 from address $a1
syscall			#output num2 in console

li $v0 11
li $a0 32
syscall			#Print " "
li $a0 61
syscall			#Print "="
li $a0 32
syscall			#Print " "

li $v0 1
lw $a0,0($a2)		#Get ans from address $a2
syscall			#output ans in console

bne $v1,47,bonusNoRemainder #check if / was used, if not jump ahead.
li $v0 11
li $a0 114
syscall			#Print "r" to represent remainder
li $v0 1
lw $a0,0($a3)		#Get remainder from address $a3
syscall			#output remainder in console

bonusNoRemainder:

li $v0, 11
la $a0, 10
syscall			#output newline in console

jr $ra			#return
#End Bonus---------------------------------
