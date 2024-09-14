.data
msgWin:		.asciiz "You win!"
msgLose:	.asciiz "\nYou lose! Actual sequence:"
msgLength:	.asciiz "\nCurrent Length:"
msgPrompt:	.asciiz "Repeat the sequence using 1, 2, 3, 4 for yellow, blue, green, red:\n"
invalidNum:	.asciiz "Invalid Num\n"
sequence:	.space 5	#Space to store the sequence
userInput:	.space 5	#Space to store user input
.text
main:
  #Initialize sequence
  li $s0,0			#Current sequence length (1 index)
  li $s1,5			#Sequence length (allocate more space for more nums)
  subiu $s1,$s1,1		#sequence is 0 index, so must sub 1
  jal generate_sequence
  simonLoop:
    li $a0,1000
    jal pause			#pause for 1 sec
    jal clearConsole
    
    jal display_sequence
    #Read user input and check with sequence
    jal read_input
    addiu $s0,$s0,1		#incrament current counter
    bleu $s0,$s1,simonLoop	#add new num to sequence, break when max reached
  #user won
  li $v0,4			#Print string syscall
  la $a0,msgWin
  syscall			
    
  li $v0, 10			#Exit syscall
  syscall
#end main


generate_sequence:
#procedure to generate sequence of numbers
#$s1: length of sequence
  li $v0,30
  syscall			#get system time
  move $a1,$a0
  li $a0,0
  li $v0,40
  syscall			#set random seed to time
  li $t1, 0			#set index
  gen_seq_loop:
    li $v0, 42			#Random number syscall
    li $a1, 4			#Upper bound (1 to 4 inclusive)
    syscall
    addi $t2, $a0, 1		#Make it 1-4
    sb $t2, sequence($t1)
    addi $t1, $t1, 1
    bleu $t1, $s1, gen_seq_loop
    jr $ra			#return
#end generate_sequence
    
display_sequence:
#procedure to display sequence
#$s0: length of current sequence
  li $t1,0			#Index
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  display_sequence_loop:
    
    lb $a0,sequence($t1)
    li $v0,1
    syscall			#output num
    addiu $t1,$t1,1		#incrament current counter
    li $a0,200
    jal pause			#pause for .2 seconds
    li $v0,11
    li $a0,0x23
    syscall			#print # (help with repeat nums)
    li $a0,300
    jal pause			#pause for .3 seconds
    jal clearConsole		#clear console
    bleu $t1,$s0,display_sequence_loop#continue displaying

  li $v0,11			#Print char syscall
  li $a0,10
  syscall			#print newline

  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra			#continue game
#end display_sequence

read_input:
#procedure to read user input, and compare it to the current sequence
#$s0: length of current sequence
#$s1: length of the full sequence
  #Prompt user for input
  li $v0, 4			#Print string syscall
  la $a0, msgPrompt
  syscall
  li $t1,0			#Index
  read_input_loop:
    li $v0, 12			#Read char syscall
    syscall
    sb $v0, userInput($t1)

  #Check user input
    lb $t3, userInput($t1)
    bgtu $t3,0x34,readError
    bltu $t3,0x31,readError	#if t3 not within 0x31-0x34 error
    subiu $t3,$t3,0x30		#convert ascii to dec

    lb $t2, sequence($t1)
    bne $t2,$t3, lose		#compare input and sequence
  #win:
    addiu $t1,$t1,1
    bleu $t1,$s0,read_input_loop#continue checking
    li $v0,4			#Print string syscall
    la $a0,msgLength
    syscall
    li $v0,1			#print int syscall
    move $a0,$s0
    addiu $a0,$a0,1
    syscall
    li $v0,11
    li $a0,10			#print \n
    syscall			#print "\nCurrent Length: [length]\n"
    jr $ra			#continue game
    
  lose:
    li $v0, 4			#Print string syscall
    la $a0, msgLose
    syscall			#print lose
    li $v0,1			#syscall to print integer
    li $t1,0			#counter
    loseLoop:			#print actual sequence
      lb $a0, sequence($t1)
      syscall
      addiu $t1,$t1,1
      bleu $t1,$s1,loseLoop	#endloop
    li $v0,11
    li $a0,10
    syscall			#print newline
    li $a0,2000
    jal pause			#pause for 2 seconds
    j main			#restart game
  readError:
    li $v0,4
    la $a0,invalidNum
    syscall
    j read_input_loop		#print error, let user retry
#end read_input

clearConsole:
#sub procedure to clear console.
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  subi $sp,$sp,12
  sw $t0,0($sp)
  sw $v0,4($sp)		 
  sw $a0,8($sp)			#store used variables 
  
  li $t0,0
  li $v0,11
  li $a0,10
  blinkLoop:
  syscall
  addiu $t0,$t0,1
  bltu $t0,10,blinkLoop		#send 10 newlines in console
  
  lw $t0,0($sp)
  lw $v0,4($sp)
  lw $a0,8($sp)
  addi $sp,$sp,12		#put used varaibles back
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra

pause:
#sub procedure to pause. will put variables back when done
#$a0: input for amount of time to pause (in miliseconds)
  subi $sp,$sp,20
  sw $t0,0($sp)
  sw $t1,4($sp)
  sw $t2,8($sp)
  sw $v0,12($sp)		 
  sw $a1,16($sp)		#store used variables 
  
  move $t0,$a0			#save pause time to $t0
  li $v0,30
  syscall			#get initial time
  move $t1,$a0			#save time
  pauseLoop:
    syscall			#get current time
    sub $t2,$a0,$t1		#elapsed=current-initial
    bltu $t2,$t0,pauseLoop	#if elapsed<timeout,loop
  
  lw $t0,0($sp)
  lw $t1,4($sp)
  lw $t2,8($sp)
  lw $v0,12($sp)
  lw $a1,16($sp)
  addi $sp,$sp,20		#put used varaibles back
  jr $ra


