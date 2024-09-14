.data
msgWin:		.asciiz "You win!"
msgLose:	.asciiz "\nYou lose! Actual sequence:"
msgLength:	.asciiz "\nCurrent Length:"
msgPrompt:	.asciiz "Repeat the sequence using 1, 2, 3, 4 for yellow, blue, green, red:\n"
invalidNum:	.asciiz "Invalid Num\n"
msgSequenceLength: .asciiz "Sequence Length? Max 80:"
msgEnterBlinkDelay: .asciiz "Enter Blink Delay (in ms):"
msgEnterDelay: .asciiz "Enter Delay (in ms):"
msgEnterDifficulty: .asciiz "Enter Difficulty 1-3 (other for custom):"
BoxTable:	#x,y,color
	.byte 6,6,6
	.byte 22,6,1
	.byte 6,22,2
	.byte 22,22,3
ColorTable:
	.word 0x000000		#black
	.word 0x0000ff		#blue
	.word 0x00ff00		#green
	.word 0xff0000		#red
	.word 0x00ffff		#blue+green
	.word 0xff00ff		#blue+red
	.word 0xffff00		#green+red = yellow
	.word 0xffffff		#white
	
sequence:	.space 80	#Space to store the sequence
userInput:	.space 80	#Space to store user input
.text

main:
  li $s7,0x10040000		#base address for display
  #clear display:
  li $a0,0			#x pos vert line
  li $a1,0			#y pos vert lines
  li $a2,0			#color black
  li $a3,32			#size
  jal DrawBox
mainLoop:
  #Initialize sequence and parameters
  li $s0,0			#Current sequence length (1 index)
  li $s1,4			#default length of 5
  li $t0,80			#max length (based on space for sequence)
  li $s7,0x10040000		#base address for display
  li $s6,4			#size of colored squares
  li $s5,200			#delay per blink
  li $s4,1000			#delay in-between numbers
  
  #enter difficulity:
  li $v0,4
  la $a0,msgEnterDifficulty
  syscall			#prompt for sequence length
  li $v0,5
  syscall
  beq $v0,1,mainDifficulty1
  beq $v0,2,mainDifficulty2
  beq $v0,3,mainDifficulty3
  #custom:
  #get sequence length
  li $v0,4
  la $a0,msgSequenceLength
  syscall			#prompt for sequence length
  li $v0,5
  syscall			#read integer
  blez $v0,mainLoop
  bgt  $v0,$t0,mainLoop		#make sure length is within range
  move $s1,$v0
  subiu $s1,$s1,1		#sequence is 0 index, so must sub 1
  #get delay
  li $v0,4
  la $a0,msgEnterDelay
  syscall			#prompt for sequence length
  li $v0,5
  syscall			#read integer
  move $s5,$v0
  #get blink delay
  li $v0,4
  la $a0,msgEnterBlinkDelay
  syscall			#prompt for sequence length
  li $v0,5
  syscall			#read integer
  move $s4,$v0
  j mainDoneDifficulty
  mainDifficulty1:
  #already set up by default
  j mainDoneDifficulty
  mainDifficulty2:
  li $s1,7			#8
  li $s5,100			#delay per blink
  li $s4,500			#delay in-between numbers
  j mainDoneDifficulty
  mainDifficulty3:
  li $s1,10			#11
  li $s5,50			#delay per blink
  li $s4,250			#delay in-between numbers
  j mainDoneDifficulty

  mainDoneDifficulty:
  
  jal generate_sequence
  jal draw_graphics_initial	#draw the initial grid and squares
  simonLoop:
    li $a0,1000
    jal pause			#pause for 1 sec
    
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
#$s4 = delay between numbers
  li $t1,0			#Index
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  display_sequence_loop:
    move $a0,$s4
    jal pause			#pause for delay seconds
    lb $a0,sequence($t1)	#load number for blink
    subiu $a0,$a0,1
    jal blink			#blink the number
    addiu $t1,$t1,1		#incrament current counter
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
    j mainLoop			#restart game
  readError:
    li $v0,4
    la $a0,invalidNum
    syscall
    j read_input_loop		#print error, let user retry
#end read_input

draw_graphics_initial:
#procedure to generate the initial graphics.
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  #generate grid (make this shorter if I have time)
  li $a2,7			#color white
  jal GetColor
  li $a0,0			#x pos vert line
  li $a1,0			#y pos vert lines
  li $a3,32			#size
  li $v1,1			#vertical line
  jal DrawLine
  li $a0,15			#x pos 2nd vert line
  jal DrawLine
  li $a0,16			#x pos 3rd vert line
  jal DrawLine
  li $a0,31			#x pos 4th vert line
  jal DrawLine
  li $v1,0			#horizontal line
  li $a0,0			#x pos horiz lines
  li $a1,0			#y pos horiz lines
  jal DrawLine
  li $a1,15			#y pos 2nd vert line
  jal DrawLine
  li $a1,16			#y pos 3rd vert line
  jal DrawLine
  li $a1,31			#y pos 4th vert line
  jal DrawLine
  
  #generate the four boxes
  li $t0,0			#counter
  dgiLoop:
    move $a0,$t0
    jal ChooseBox		#set variables for each box
    jal DrawBox
    addiu $t0,$t0,1		#incrament
    bltu $t0,4,dgiLoop
  #end dgiloop
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra
#end draw_graphics_initial

blink:
#sub procedure to blink a number.
#$a0 = box to blink (0-3)
#$s5 = time per blink (in miliseconds)
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  subi $sp,$sp,4
  sw $a0,0($sp)
  
  li $t5,4			#amount of blinks
  li $t4,0			#bool for black or color (0 black)
  
  li $a2,0
  jal GetColor
  move $t6,$a2			#save black to $t6
  
  jal ChooseBox
  
  subiu $a0,$a0,1
  subiu $a1,$a1,1
  move $t8,$a0			
  move $t9,$a1			#copy coordinates into temp registers
  jal GetColor			#convert color to hex
  move $t7,$a2			#copy color into temp register
  li $a3,6			#length of lines
  #draws grid around box, used to flash back and forth from black and the color
  blinkLoop:
    li $v1,0			#horizontal line
    jal DrawLine
    addu $a1,$a1,$s6
    addiu $a1,$a1,1
    jal DrawLine		#bottom horizontal line
    move $a1,$t9		#paste coordinate from temp registers
        
    li $v1,1			#vertical line
    jal DrawLine
    addu $a0,$a0,$s6
    addiu $a0,$a0,1
    jal DrawLine		#bottom vertical line
    subiu $t5,$t5,1			#decrement counter
    blez $t5,blinkDone		#done blinking when counter =0
    move $a0, $s5
    jal pause			#pause for blink delay
    move $a0,$t8		#paste coordinate from temp registers
    beqz $t4,blinkSetBlack	
      #normal color
      move $a2,$t7
      li $t4,0			#do black next loop
      j blinkLoop
    blinkSetBlack:
      move $a2,$t6
      li $t4,1
      j blinkLoop		#do color next loop
  blinkDone:
  lw $a0,0($sp)
  addi $sp,$sp,4
  lw $ra,0($sp)			#load return address 
  addi $sp,$sp,4
  
  
  
#end blink

ChooseBox:
#sub procedure to load argument values dependant on the box needed
#loads from .data
#input $a0: which box (0-3)
#output $a0-$a3 box parameters
#input $s6 = box size
  move $a3,$s6
  subi $sp,$sp,4
  sw $t0,0($sp)
  
  mulu $t0,$a0,3		#indexed by 3
  lb $a0,BoxTable($t0)		#load x
  addiu $t0,$t0,1
  lb $a1,BoxTable($t0)		#load y
  addiu $t0,$t0,1
  lb $a2,BoxTable($t0)		#load color
  
  lw $t0,0($sp)
  addi $sp,$sp,4
  jr $ra
#end ChooseBox
  
DrawBox:
#sub procedure to draw a box. calls DrawLine
#will put $a0-$a3 variables back when done. doesnt touch temp registers
#a0 = x coord left
#a1 = y coord top
#a2 = color number (0-7) STILL INDEXED
#a3 = size of box (1-32)
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  subi $sp,$sp,4
  sw $t0,0($sp)			#store $t0
  jal StoreArgumentRegisters	#store $a0-$a3 in stack
  jal GetColor			#make $a2 the hex color
  move $t0,$a3			#counter
  DrawBLoop:
    li $v1,0			#hoirz line for DrawLine
    
    jal DrawLine
    addiu $a1,$a1,1		#incrament y coord
    subiu $t0,$t0,1		#decrement counter
    bne $t0,$0,DrawBLoop	
  
  
  
  jal LoadArgumentRegisters	#load $a0-$a3 from stack
  lw $t0,0($sp)			#load $t0 
  addi $sp,$sp,4
  lw $ra,0($sp)			#load return address 
  addi $sp,$sp,4
  jr $ra
#end DrawBox

DrawLine:
#sub procedure to draw a line. calls DrawDot
#will put $a0-$a3 variables back when done. doesnt touch temp registers
#a0 = x coord left
#a1 = y coord top
#a2 = color (NOT INDEXED, already in hex)
#a3 = size of line (1-32)
#v1 = 1 for vert line, 0 (or anything) for horiz line

  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  jal StoreArgumentRegisters	#store $a0-$a3 in stack
  subi $sp,$sp,4
  sw $v1,0($sp)			#store $v1
  beq $v1,1,dlVertLoop		#vert loop if $v1=1
  #horizontal line
  dlHorzLoop:
    jal DrawDot
    addiu $a0,$a0,1		#incrament x coord $a0
    subiu $a3,$a3,1		#decrament line left $a3
    bne $a3,$0,dlHorzLoop
  j DrawLineDone
  #vertical line
  dlVertLoop:
    jal DrawDot
    addiu $a1,$a1,1		#incrament y coord $a0
    subiu $a3,$a3,1		#decrament line left $a3
    bne $a3,$0,dlVertLoop
  DrawLineDone:
  lw $v1,0($sp)			#load $v1
  addi $sp,$sp,4
  jal LoadArgumentRegisters	#load $a0-$a3 from stack
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra
#end DrawLine

DrawDot:
#sub procedure to draw a dot. calls CalcAddress
#will put $a0-$a3 variables back when done. doesnt touch temp registers
#a0 = x coord
#a1 = y coord
#a2 = color (NOT INDEXED, already in hex)
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  jal StoreArgumentRegisters
  
  jal CalcAddress		#$v0 has address
  sw $a2,0($v0)			#make dot
  
  jal LoadArgumentRegisters	#load $a0-$a3 from stack
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra
#end DrawDot

CalcAddress:
#sub procedure to convert x and y coords into addresses
#a0 = x coord 
#a1 = y coord
#s7 = base address
#returns $v0 = memory address
  sll $a0,$a0,2			#$a0=$a0*4
  sll $a1,$a1,7			#$a1=$a1*128
  addu $v0,$s7,$a0
  addu $v0,$v0,$a1		#$v0=base+$a0x4+$a1x32x4
  jr $ra
#end CalcAddress

GetColor:
#sub procedure to convert color 1-7 coords into actual color
#a2 = color 0-7
#returns $a2 = color hex
  sll $a2,$a2,2			#offset by 4
  lw $a2,ColorTable($a2)
  jr $ra
#end GetColor

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
#end pause


#Below procedures store and load $a0-$a3 in the stack
#Did this because this is done in multiple functions, and it makes code management easier
#Im aware its less storage efficient
StoreArgumentRegisters:
  subi $sp,$sp,16
  sw $a0,0($sp)			
  sw $a1,4($sp)
  sw $a2,8($sp)
  sw $a3,12($sp)		#store arguments
  jr $ra
LoadArgumentRegisters:
  lw $a0,0($sp)			
  lw $a1,4($sp)
  lw $a2,8($sp)
  lw $a3,12($sp)		#store arguments
  addi $sp,$sp,16
  jr $ra
#end Store and Load ArgumentRegisters