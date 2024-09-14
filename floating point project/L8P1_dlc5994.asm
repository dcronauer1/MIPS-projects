.data
floatArray: .float 0:5
promptFloats1: .asciiz "Enter "
promptFloats2: .asciiz " float numbers:"
sortedNums: .asciiz "Sorted Floats: "
commaSpace: .asciiz ", "
average: .asciiz "\nAverage: "
.text
main:
  li $s0,5		#number of entries
  move $a0,$s0		#procedure input for number of entries
  la $a1,floatArray	#procedure input for address of array
  jal PromptUser	#prompt user for entries
  
  move $a0,$s0
  la $a1,floatArray
  jal SortFloats	#sort the array
  
  move $a0,$s0
  la $a1,floatArray
  jal DisplayArray	#display the array
  
  move $a0,$s0
  la $a1,floatArray
  jal DisplayAverage	#display the average
  
  li $v0,10
  syscall	#end program
#end main
PromptUser:
#procedure to prompt and read user float inputs. stores them in an array
#input: $a0 - number of entries to enter
#input: $a1 - address of Array
  move $t0,$a0		#store number of entries
  
  la $a0,promptFloats1
  li $v0, 4
  syscall		#print "Enter "
  li $v0,1
  move $a0,$t0
  syscall		#print number
  li $v0,4
  la $a0,promptFloats2
  syscall		#print " float numbers:"
  
  #for $t1=0,$t1<$t0,$t1++
  li $t1,0
  puForLoop:
    li $v0,6
    syscall		#get float ($f0)
    s.s $f0,($a1) 	#store float in array
    addiu $a1,$a1,4	#next entry
    addiu $t1,$t1,1	#incrament counter
    blt $t1,$t0,puForLoop #$t1<$t0, continue
  #end for
  
  jr $ra
#end PromptUser

SortFloats:
#Procedure to sort floats in an array from low to high
#Uses bubble sort
#input $a0 - size of array
#input $a1 - address of array
  move $t0,$a0		#store size
  sll $t0,$t0,2		#mult size by 4
  #everything is multiplied by 4 because floats are 4 bytes
  #i=$t1/4
  #j=$t2/4
  #n=$t0/4
  #for i=1,i<n,i++
  li $t1,4
  sfForLoop1:
    bgeu $t1,$t0,sfEndForLoop1 #i>=n, end for1
    #for j=0,j<n-i,j++
    li $t2,0		#j=0
    subu $t4,$t0,$t1	#$t4=n-i
    sfForLoop2:
      bgeu $t2,$t4,sfEndForLoop2 #j>=n-i, end for2
      addu $t3,$a1,$t2	#$t3=address of A[j]
      l.s $f4,0($t3) 	#$f4=A[j]
      l.s $f5,4($t3)	#$f5=A[j+1]
      
      c.le.s $f4,$f5 
      bc1t sfFor2NoSwap#if A[j]>A[j+1], continue
      #swap:
      s.s $f5,0($t3)	#A[j]=A[j+1]
      s.s $f4,4($t3)	#A[j+1]=A[j]
      sfFor2NoSwap:
      addi $t2,$t2,4	#j++
      j sfForLoop2
    sfEndForLoop2:
    addiu $t1,$t1,4	#i++
    j sfForLoop1
  sfEndForLoop1:
  jr $ra
#end SortFloats

DisplayArray:
#procedure to display floats from an array
#input: $a0 - number of entries
#input: $a1 - address of Array
  move $t0,$a0		#store number of entries
  li $v0,4
  la $a0,sortedNums
  syscall 		#print "Sorted Floats: "
  
  la $a0,commaSpace	#address for string ", "
  #for $t1=0,$t1<$t0,$t1++
  li $t1,0
  daForLoop:
    l.s $f12,($a1)	#load array entry into $f12
    li $v0,2
    syscall		#print float ($f12)
    addiu $a1,$a1,4	#next entry
    addiu $t1,$t1,1	#incrament counter
    bge $t1,$t0,daEndFor #$t1<$t0, continue
      li $v0,4
      syscall		#print ", "
      j daForLoop	#continue
  daEndFor:
  jr $ra
#end DisplayArray

DisplayAverage:
#procedure to calculate and display the average number from an array of floats
#input: $a0 - number of entries
#input: $a1 - address of Array
  move $t0,$a0		#store number of entries
  #for $t1=0,$t1<$t0,$t1++
  li $t1,0
  mtc1 $t1,$f5
  davgForLoop:
    l.s $f4,($a1)	#load array entry into $f4
    add.s $f5,$f5,$f4	#add entry to total
    addiu $a1,$a1,4	#next entry
    addiu $t1,$t1,1	#incrament counter
    blt $t1,$t0,davgForLoop #$t1<$t0, continue
  mtc1 $t0,$f6
  cvt.s.w $f6,$f6
  div.s $f12,$f5,$f6	#$f12=total/amount

  li $v0,4
  la $a0,average
  syscall		#print "\nAverage: "
  li $v0,2
  syscall		#print average ($f12)
  jr $ra
#end DisplayAverage
