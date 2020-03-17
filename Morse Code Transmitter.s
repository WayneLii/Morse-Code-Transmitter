##################################################
## Name:    Lab2_Template.s  					##
## Purpose:	Morse Code Transmitter		 		##
## Author:	Mahmoud A. Elmohr 					##
##################################################

# Start of the data section
.data			
.align 4						# To make sure we start with 4 bytes aligned address (Not important for this one)
InputLUT:						
	# Use the following line only with the board
	.ascii "SOS"				# Put the 5 Letters here instead of ABCDE plus1
	# Note: the memory is initialized to zero so as long as there are not 4*n characters there will be at least one zero (NULL) after the last character
	
	# Use the following 2 lines only on Venus simulator
	#.asciiz "ABCDE"			# Put the 5 Letters here instead of ABCDE	
	
	#.asciiz "X"				# Leave it as it is. It's used to make sure we are 4 bytes aligned  (as Venus doesn't have the .align directive)

.align 4						# To make sure we start with 4 bytes aligned address (This one is Important)
MorseLUT:
	.word 0xE800	# A
	.word 0xAB80	# B
	.word 0xBAE0	# C
	.word 0xAE00	# D
	.word 0x8000	# E
	.word 0xBA80	# F
	.word 0xBB80	# G
	.word 0xAA00	# H
	.word 0xA000	# I
	.word 0xEEE8	# J
	.word 0xEB80	# K
	.word 0xAE80	# L
	.word 0xEE00	# M
	.word 0xB800	# N
	.word 0xEEE0	# O
	.word 0xBBA0	# P
	.word 0xEBB8	# Q
	.word 0xBA00	# R
	.word 0xA800	# S
	.word 0xE000	# T
	.word 0xEA00	# U
	.word 0xEA80	# V
	.word 0xEE80	# W
	.word 0xEAE0	# X
	.word 0xEEB8	# Y
	.word 0xAEE0	# Z



# The main function must be initialized in that manner in order to compile properly on the board
.text
.globl	main
main:
	# Put your initializations here
	# --LED base address
	li s1, 0x7ff60000 			# assigns s1 with the LED base address (Could be replaced with lui s1, 0x7ff60)
	# -- inital value to turn LED on
	li s2, 0x01					# assigns s2 with the value 1 to be used to turn the LED on
	# assigns s3 with the InputLUT base address
	la s3, InputLUT				
	# assigns s4 with the MorseLUT base address
	la s4, MorseLUT				

	sw zero, 0(s1)				# Turn the LED off
		
    ResetLUT:
		mv s5, s3				# assigns s5 to the address of the first byte  in the InputLUT

	NextChar:
		lbu a0, 0(s5)				# loads one byte from the InputLUT
		addi s5, s5, 1				# increases the index for the InputLUT (For future loads)
		bne a0, zero, ProcessChar	# if char is not NULL, jumps to ProcessChar
		# If we reached the end of the 5 letters, we start again
		li a0, 4 					# delay 4 extra spaces (7 total) between words to terminate
		jal DELAY				
		j ResetLUT					# start again
       
	ProcessChar:
		jal CHAR2MORSE				# convert ASCII to Morse pattern in a0	

	RemoveZeros:
		# to remove trailling zeroe bits until reach a one
		addi a7, zero, 1

		loop1: ANDI a6, a0, 1
		beq a6, a7, exit
		SRLI a0, a0, 1
		j loop1
		exit:
		
		jal Shift_and_display
		
	
		
	
	Shift_and_display:
	
	add t3, a0, zero
	addi t6, zero, 1
		# to peel off one bit at a time and turn the light on or off as necessary
		loop2: andi t5, t3, 1
        beq t5, t6, ON # turn on the LED when t5 = t6
        jal LED_OFF # turns off LED
		j ifend

        # turns on the LED
        ON:
		jal LED_ON

        # display complete and start a long delay as gap between characters
		ifend:
		addi a0,zero,1
		jal DELAY
		#bne t5, t6, OFF
		# Delay after the LED has been turned on or off
	
		
		# Test if all bits are shifted
		# If we're not done then loop back to Shift_and_display to shift the next bit
		beq t3, zero, out
		SRLI t3, t3, 1
		j loop2
		# If we're done then branch back to get the next characte
		out:
		addi a0, zero, 3
		jal DELAY
		j NextChar
		
	
# End of main function		
		







# Subroutines
LED_OFF:
	# turn LED off
	sw zero, 0(s1)
	
	jr ra
	
	
LED_ON:
	# turn LED on
	#li s1, 0x7ff60000 
	#addi t1, t1, 0xF
	sw s2,0(s1)
	
	jr ra


DELAY:
	# to make a delay of a0 * 500ms
	li s6, 6250000
	# decrement a0 to determine how many times to loop through
	
	while_1:
		addi a0, a0, -1
		li s7, 0
        # code used to create a 500ms delay
		while_2: 
			addi s7, s7, 1
			BNE s7, s6, while_2
		
	BNE zero, a0, while_1
	
	jr ra


CHAR2MORSE:
	# to convert the ASCII code to an index and lookup the Morse pattern in the Lookup Table
	
	# pick a empty register a5, and let it hold 0
	add a5, zero, zero
	# let a5 get the (a0-0x41)
	addi a5, a0, -0x41
	# multiple by 4 to ge the offset
	slli a5, a5, 2
	
	add a5, a5, s4 #s4 is the base of morseLUT, a5 is the offset
	lw a0, 0(a5) #get the MorseTable[offset]
	
	jr ra
