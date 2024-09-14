.data
GameParameters: .half 200,1000 #delay per blink, delay between numbers
BaseAddress: .word 0x10040000
ColorTable:
	.word 0x000000		#black
	.word 0x0000ff		#blue
	.word 0x00ff00		#green
	.word 0xff0000		#red
	.word 0x00ffff		#blue+green
	.word 0xff00ff		#blue+red
	.word 0xffff00		#green+red = yellow
	.word 0xffffff		#white
	.word 0xffa500		#orange
CircleTable:
    # Format: center_x, center_y, color, tone_pitch
    .byte 128,64, 8, 60    # Orange (top)
    .byte 64,128, 1, 62   # Blue (left)
    .byte 198,128, 2, 64   # Green (right)
    .byte 128,198, 3, 66  # Red (bottom)

CircleRadius: .byte 32
# Pre-computed circle data (for a 32-pixel radius circle)
CircleOffsets:
    .byte 2,5,8,10
    .byte 11,12,12,13
    .byte 14,14,15,15
    .byte 15,16,16,16
ErrorTone: .byte 40  # Lower pitch for error tone
#number data stuff:
DigitTable:
    .byte   '1', 0x38,0x78,0xf8,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18
    .byte   '2', 0x7e,0xff,0x83,0x06,0x0c,0x18,0x30,0x60,0xc0,0xc1,0xff,0x7e
    .byte   '3', 0x7e,0xff,0x83,0x03,0x03,0x1e,0x1e,0x03,0x03,0x83,0xff,0x7e
    .byte   '4', 0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7f,0x03,0x03,0x03,0x03,0x03
Numbers:  .asciiz "1","2","3","4"

msgWin:		.asciiz "You win!"
msgLose:	.asciiz "\nYou lose! Actual sequence:"
msgLength:	.asciiz "\nCurrent Length:"
msgPrompt:	.asciiz "Repeat the sequence using 1, 2, 3, 4 for orange, blue, green, red:\n"
invalidNum:	.asciiz "Invalid Num\n"
msgSequenceLength: .asciiz "Sequence Length? Max 80:"
msgEnterBlinkDelay: .asciiz "Enter Blink Delay (in ms):"
msgEnterDelay: .asciiz "Enter Delay (in ms):"
msgEnterDifficulty: .asciiz "Enter Difficulty 1-3 (other for custom):"

sequence:  .space 80	#Space to store the sequence
#dont need this anymore userInput:	.space 80	#Space to store user input
.text

main:
  #clear display:
  li $a0,0			#x pos vert line
  li $a1,0			#y pos vert lines
  li $a2,0			#color black
  li $a3,256			#size
  jal DrawBox			#clear the screen
mainLoop:
  #Initialize sequence and parameters
  li $s0,0			#Current sequence length (1 index)
  li $s1,4			#default length of 5
  li $t0,80			#max length (based on space for sequence)
  
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
  syscall			#prompt for message enter delay
  li $v0,5
  syscall			#read integer
  sh $v0,GameParameters		#store delay
  #get blink delay
  li $v0,4
  la $a0,msgEnterBlinkDelay
  syscall			#prompt for blink delay
  li $v0,5
  syscall			#read integer
  sh $v0,GameParameters+2	#store blink delay
  j mainDoneDifficulty
  mainDifficulty1:
  #already set up by default
  j mainDoneDifficulty
  mainDifficulty2:
  li $s1,7			#8
  li $t1,100
  sh $t1,GameParameters 	#delay per blink
  li $t1,500
  sh $t1,GameParameters+2 	#delay in-between numbers
  j mainDoneDifficulty
  mainDifficulty3:
  li $s1,10			#11
  li $t1,50
  sh $t1,GameParameters 	#delay per blink
  li $t1,250
  sh $t1,GameParameters+2 	#delay in-between numbers
  j mainDoneDifficulty

  mainDoneDifficulty:
  
  jal generate_sequence
  jal draw_graphics_initial	#draw the initial grid and squares
  simonLoop:
    li $a0,500
    jal pause			#pause for 1/2 sec
    
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
#delay between numbers is stored in data
  subi $sp,$sp,16
  sw $ra,0($sp)			#store return address
  sw $s6,4($sp)	
  li $s6,0			#Index
  display_sequence_loop:
    lhu $a0, GameParameters+2	#load delay between numbers
    jal pause			#pause for delay seconds
    lb $a0,sequence($s6)	#load number to blink
    subiu $a0,$a0,1
    lhu $a1, GameParameters	#load blink delay
    lhu $t1,GameParameters+2
    addu $a1,$a1,$t1		#sound time =blink + number delay
    sw $a0,8($sp)
    sw $a1,12($sp)				
    jal playTone		#play the tone
    lw $a0,8($sp)
    lw $a1,12($sp)
    jal blink			#blink the number
    addiu $s6,$s6,1		#incrament current counter
    bleu $s6,$s0,display_sequence_loop#continue displaying

  li $v0,11			#Print char syscall
  li $a0,10
  syscall			#print newline
  
  lw $s6,4($sp)
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,16
  jr $ra			#continue game
#end display_sequence

read_input:
#procedure to read user input, and compare it to the current sequence
#$s0: length of current sequence
#$s1: length of the full sequence
  #Prompt user for input
  subi $sp,$sp,16
  sw $ra,0($sp)			#store return address
  sw $s2,4($sp)
  sw $s3,8($sp)
  li $v0, 4			#Print string syscall
  la $a0, msgPrompt
  syscall
  li $s2,0			#Index
  read_input_loop:
    li $v0, 12			#Read char syscall
    syscall
    subiu $s3,$v0,0x30		#convert ascii to dec
  #Check user input
    bgtu $s3,4,readError
    bltu $s3,1,readError	#if s3 not within 1-4, error
    
    move $a0, $s3
    subi $a0, $a0, 1
    lhu $a1, GameParameters	#load blink delay
    lhu $t1,GameParameters+2
    addu $a1,$a1,$t1		#sound time =blink + number delay
    srl $t1,$a1,3		#divide time by 4
    subu $a1,$a1,$t1		#sound time = 3/4(blink + number delay)
    sw $a0,12($sp)
    jal playTone		#play the tone
    lw $a0,12($sp)
    li $a1,70			#70ms blink delay
    jal blink			#blink the user inputted circle
    
    lb $t2, sequence($s2)
    bne $t2,$s3, inputError	#compare input and sequence
  #win: 
    addiu $s2,$s2,1		#incrament counter   
    bleu $s2,$s0,read_input_loop#continue checking
   
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
    j read_inputEnd		#continue game
  inputError:		
    lb $a0, ErrorTone
    li $a1, 1000
    li $a2, 100
    li $a3, 127
    li $v0, 31			#play error tone
    syscall
    li $a0, 1000
    jal pause			#pause for 1 second
    
    lb $a0, sequence($s2)
    subi $a0, $a0, 1
    sw $a0,12($sp)		#store a0 to stack
    li $a1, 500
    jal playTone		#play the tone
    lw $a0,12($sp)		#load a0 from stack
    li $a1, 500
    jal blink
    li $a0, 500
    jal pause			#pause for 500milisecs
    lw $a0,12($sp)		#load a0 from stack
    li $a1, 500
    jal playTone
    lw $a0,12($sp)		#load a0 from stack
    li $a1, 500
    jal blink			#blink the actual circle twice
    #go to lose		
  lose:
    li $v0, 4			#Print string syscall
    la $a0, msgLose
    syscall			#print "you lose"
    li $v0,1			#syscall to print integer
    li $s2,0			#counter
    loseLoop:			#print actual sequence
      lb $a0, sequence($s2)
      syscall
      addiu $s2,$s2,1
      bleu $s2,$s1,loseLoop	#endloop
    li $v0,11
    li $a0,10
    syscall			#print newline
    addi $sp, $sp, 16		#make sure stack pointer stays the same
    j mainLoop			#restart game
  readError:
    li $v0,4
    la $a0,invalidNum
    syscall
    j read_input_loop		#print error, let user retry
    
  read_inputEnd:
    lw $s3,8($sp)
    lw $s2,4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra
#end read_input

draw_graphics_initial:
#procedure to generate the initial graphics.
#(has code to draw the initial circles too, but its easier and better to flash the whole circle rather than
# expand it, even though its less efficient overall)
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
    # Draw diagonal lines
    li $a2, 7  # White color
    jal GetColor
    li $a0, 30
    li $a1, 30			#initial x and y
    li $a3, 225			#x2
    li $v0, -1  # Diagonal line 45 degrees downwards
    jal DrawDiagonalLine

    li $a0, 30
    li $a1, 225			#initial x and y
    li $a3, 225			#x2
    li $v0, 1  # Diagonal line 45 degrees upwards
    jal DrawDiagonalLine

  # Draw circles		not doing it this way anymore
#    li $s2, 0  # Counter
#  dgiCircleLoop:
#    move $a0, $s2
#    jal ChooseCircle
#    li $a3,10			#for the bool
#    jal DrawCircleWithNumber
#    addiu $s2, $s2, 1
#    bltu $s2, 4, dgiCircleLoop
  #end dgiCircleLoop
  
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
#end draw_graphics_initial

ChooseCircle:
#sub procedure to load argument values dependant on the circle needed
#loads from .data
#input $a0: which circle (0-3)
#output $a0-$a2 circle parameters
  subi $sp, $sp, 8
  sw $ra, 0($sp)
  sw $s2, 4($sp)
# Get circle parameters
    sll $s2, $a0, 2  # Multiply by 4 (1 word per entry)
    lbu $a0, CircleTable($s2)    # center_x
    addi $s2, $s2, 1
    lbu $a1, CircleTable($s2)    # center_y
    addi $s2, $s2, 1
    lbu $a2, CircleTable($s2)    # color
    jal GetColor

  lw $s2, 4($sp)  
  lw $ra, 0($sp)
  addi $sp, $sp, 8
  jr $ra

DrawCircleWithNumber:
#Procedure to draw the circle and its number.
#input $a0: which circle (0-3)
  subi $sp, $sp, 20
  sw $ra, 0($sp)
  sw $a0, 4($sp)
  
  jal ChooseCircle		#get circle parameters
  sw $a0, 8($sp)
  sw $a1, 12($sp)		#store x and y to stack
  sw $a2, 16($sp)
  jal DrawCircle   		#draw the circle
  
  #draw numbers
  lw $a3, 4($sp)  		#Restore circle index
  sll $a3,$a3,1			#asciiz has null terminator for each entry
  la $a3, Numbers($a3)		#load address to appropriate number
  lw $a0, 8($sp)
  lw $a1, 12($sp)		#restore circle x and y
  lw $a2, 16($sp)		#restore color
  #adjust coordinates
  subiu $a0,$a0,4
  subiu $a1,$a1,6
  jal OutText	  		#draw number
  
  lw $ra, 0($sp)
  addi $sp, $sp, 20
  jr $ra
#end DrawCircleWithNumber

DrawCircle:
  #procedure to draw the circle
  #$a0 = center_x, $a1 = center_y, $a2 = color (in hex), $a3 = tone
  subi $sp, $sp, 20
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
  sw $s3, 16($sp)

  lbu $s1,CircleRadius		#load radius into $s1
  srl $s2,$s1,1			#divide radius by 2
  subu $a0,$a0,$s2		#start x at left of circle
  li $s0,0			#counter
  move $s3,$a1			#store original y value

  #for data efficency, it goes through the circle datatable twice, once forwards and again backwards
  DrawCircleLoop:
    blt $s0,$s2,dclFirstHalf	#when counter is at >=16, do below
      subiu $s2,$s2,1		#decrement counter for CircleOffsets (for other half of circle)
      lbu $a3, CircleOffsets($s2) 
      bge $s0,$s1 DrawCircleEnd	#End if x reached end of circle (radius is 1 indexed, counter is 0 index)
      j dclSecondHalfjump
  dclFirstHalf:
      lbu $a3, CircleOffsets($s0)  #y distance from center (use this for first half)
  dclSecondHalfjump:
    #y=y-offset, then $a3=offset*2+1 
    subu $a1,$s3,$a3		#y=original_y-offset
    sll $a3,$a3,1
    addiu $a3,$a3,1		#$a3=offset*2+1 (length of the line)
    li $v1,1			#vertical line
    jal DrawLine		#draw the line of the circle (line is top to bottom)
  dclSkipFullCircle:
    addi $a0,$a0,1		#increment x
    addi $s0, $s0, 1   		# Move to next entry in CircleOffsets & incrament counter
    j DrawCircleLoop

DrawCircleEnd:
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  lw $s1, 8($sp)
  lw $s2, 12($sp)
  lw $s3, 16($sp)
  addi $sp, $sp, 20
  jr $ra
#end DrawCircle

playTone:
#sub procedure to play the tone for a circle
#$a0 = circle to play tone (0-3)
#$a1 = duration of tone (in miliseconds)
  sll $t0, $a0, 2  		#Multiply by 4 (1 word per entry)
  addi $t0, $t0, 3		#move 3 into the table (4th entry)
  lbu $a0, CircleTable($t0)    	#tone/pitch
  #play tone
  #$a1 already equals $a1
  li $a2,50			#instrument
  li $a3, 50			#volume
  li $v0,31			#syscall to play midi
  syscall
  jr $ra
#end playTone

blink:
#sub procedure to blink a circle once
#$a0 = circle to blink (0-3)
#$a1 = time per blink (in miliseconds)
  subi $sp,$sp,12		#for storing circle and time to blink
  sw $ra,0($sp)			#store return address
  sw $a0,4($sp)
  sw $a1,8($sp)
#flash circle
  lw $a0,4($sp)
  jal DrawCircleWithNumber	#draw the circle
  lw $a0,8($sp)			#load pause delay
  jal pause
  lw $a0,4($sp)			#load circle
  jal ChooseCircle		#load circle params
  li $a2,0			#color black
  jal DrawCircle		#erase the circle (black)

  blinkDone:
  lw $ra,0($sp)			#load return address 
  addi $sp,$sp,12
  jr $ra			#forgot this in the last part whoops
#end blink

##removed ChooseBox

DrawBox:
#sub procedure to draw a box. calls DrawLine
#a0 = x coord left
#a1 = y coord top
#a2 = color number (0-7) STILL INDEXED
#a3 = size of box (1-32)
  subi $sp,$sp,20
  sw $ra,0($sp)			#store return address
  sw $s2,4($sp)			#store $s2
  jal GetColor			#make $a2 the hex color
  move $s2,$a3			#counter
  DrawBLoop:
    li $v1,0			#hoirz line for DrawLine
    
    sw $a0,8($sp)			
    sw $a1,12($sp)
    sw $a3,16($sp)		#store arguments
    jal DrawLine		#draw the line
    lw $a0,8($sp)			
    lw $a1,12($sp)
    lw $a3,16($sp)		#load arguments
    
    addiu $a1,$a1,1		#incrament y coord
    subiu $s2,$s2,1		#decrement counter
    bne $s2,$0,DrawBLoop	
  
  lw $s2,4($sp)			#load $s2 
  lw $ra,0($sp)			#load return address 
  addi $sp,$sp,20
  jr $ra
#end DrawBox

DrawDiagonalLine:
# $a0 = x1
#$a1 = y
#$a2 = color
#$a3 = x2
#$v0 = angle (+1 for 45 degrees upwards and right)

  subi $sp, $sp, 16
  sw $ra, 0($sp)
  sw $s2, 4($sp)
  sw $s3, 8($sp)
  sw $s4, 12($sp)		#save space for temp registers that wont change during subprocedure calls
    
  move $s2, $v0  		# sub procedures will touch $v0
  ble $a0,$a3,ddlStart	#if x1>x2, swap them. else branch
  move $s3,$a1
  move $a1,$a0
  move $a0,$s3
  neg $s2,$s2			#since x's are backwards, then direction is also backwards
    
  ddlStart:
    move $s3, $a0  		# Start x
    move $s4, $a1  		# start y
    neg $s2,$s2    		#since as y increases it goes down, do this to make it easier
  DrawDiagonalLoop:
    move $a0, $s3
    move $a1, $s4
    jal DrawDot
    addi $s3, $s3, 1		#incrament x pos
    add  $s4,$s4,$s2		#incrament y by factor
    bgt $s4,255,ddllstop	#if y is about to go out of bounds, exit loop
    ble $s3, $a3, DrawDiagonalLoop #has reached x2, stop next loop
    
  ddllstop:
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    lw $s4, 12($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra
#end DrawDiagonalLine

DrawLine:
#sub procedure to draw a line. calls DrawDot
#a0 = x coord left
#a1 = y coord top
#a2 = color (NOT INDEXED, already in hex)
#a3 = size of line (1-32)
#v1 = 1 for vert line, 0 (or anything) for horiz line
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
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
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra
#end DrawLine

DrawDot:
#sub procedure to draw a dot. calls CalcAddress
#keeps a registers the same
#a0 = x coord
#a1 = y coord
#a2 = color (NOT INDEXED, already in hex)
  subi $sp,$sp,4
  sw $ra,0($sp)			#store return address
  subi $sp,$sp,8
  sw $a0,0($sp)			
  sw $a1,4($sp)
  
  jal CalcAddress		#$v0 has address
  sw $a2,0($v0)			#make dot
  
  lw $a0,0($sp)			
  lw $a1,4($sp)
  addi $sp,$sp,8
  lw $ra,0($sp)			#load return address
  addi $sp,$sp,4
  jr $ra
#end DrawDot

CalcAddress:
#sub procedure to convert x and y coords into addresses
#a0 = x coord 
#a1 = y coord
#BaseAddress = base address
#returns $v0 = memory address
  sll $a0,$a0,2			#$a0=$a0*4
  sll $a1,$a1,10		#$a1=$a1*1024
  lw $t0,BaseAddress		#load address
  addu $v0,$t0,$a0
  addu $v0,$v0,$a1		#$v0=base+$a0x4+$a1x256x4
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
#sub procedure to pause.
#$a0: input for amount of time to pause (in miliseconds)
  move $t0,$a0			#save pause time to $t0
  li $v0,30
  syscall			#get initial time
  move $t1,$a0			#save time
  pauseLoop:
    syscall			#get current time
    sub $t2,$a0,$t1		#elapsed=current-initial
    bltu $t2,$t0,pauseLoop	#if elapsed<timeout,loop
  jr $ra
#end pause

OutText:
# OutText: display ascii characters on the bit mapped display
# $a0 = horizontal pixel co-ordinate (0-255)
# $a1 = vertical pixel co-ordinate (0-255)
# $a2 = background color (hex)
# $a3 = pointer to asciiz text (to be displayed)
        addiu   $sp, $sp, -24
        sw      $ra, 20($sp)

        li      $t8, 1          # line number in the digit array (1-12)
_text1:
        la      $t9, 0x10040000 # get the memory start address
        sll     $t0, $a0, 2     # assumes mars was configured as 256 x 256
        addu    $t9, $t9, $t0   # and 1 pixel width, 1 pixel height
        sll     $t0, $a1, 10    # (a0 * 4) + (a1 * 4 * 256)
        addu    $t9, $t9, $t0   # t9 = memory address for this pixel

        move    $t2, $a3        # t2 = pointer to the text string
_text2:
        lb      $t0, 0($t2)     # character to be displayed
        addiu   $t2, $t2, 1     # last character is a null
        beq     $t0, $zero, _text9

        la      $t3, DigitTable # find the character in the table
_text3:
        lb      $t4, 0($t3)     # get an entry from the table
        beq     $t4, $t0, _text4
        beq     $t4, $zero, _text4
        addiu   $t3, $t3, 13    # go to the next entry in the table
        j       _text3
_text4:
        addu    $t3, $t3, $t8   # t8 is the line number
        lb      $t4, 0($t3)     # bit map to be displayed

        sw      $a2, 0($t9)   # first pixel is background
        addiu   $t9, $t9, 4

        li      $t5, 8          # 8 bits to go out
_text5:
        move    $t7, $a2     	#background color
        andi    $t6, $t4, 0x80  # mask out the bit (0=black, 1=white)
        beq     $t6, $zero, _text6
        la      $t7, ColorTable     # else it is white
        lw      $t7, 28($t7)
_text6:
        sw      $t7, 0($t9)     # write the pixel color
        addiu   $t9, $t9, 4     # go to the next memory position
        sll     $t4, $t4, 1     # and line number
        addiu   $t5, $t5, -1    # and decrement down (8,7,...0)
        bne     $t5, $zero, _text5

        sw      $a2, 0($t9)    # last pixel is background
        addiu   $t9, $t9, 4
        j       _text2          # go get another character

_text9:
        addiu   $a1, $a1, 1     # advance to the next line
        addiu   $t8, $t8, 1     # increment the digit array offset (1-12)
        bne     $t8, 13, _text1

        lw      $ra, 20($sp)
        addiu   $sp, $sp, 24
        jr      $ra

