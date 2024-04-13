data = 0x1000				#PC NPC
lw x4, 0(x1)				#0 4
#addi x4, x0, 1
#Init Registers
addi x1, x0, 1				#4 8
addi x2, x0, 2				#8 12

# x4 -> r1
# x1 -> f1
# x2 -> f0
# x3 -> f2

# inst dest, opA/rs1, opB/rs2
#Hazards Checking
lw x1, 0(x4)				#12 16
#addi x1, x0, 0
#mul	x3,	x2,	x1		#16 20
add      x3, x2, x1
sw	x3, 0x100(x4)			#20 24
addi x4, x4, 4				#24 28
lw x1, 0(x4)				#28 32
mul	x3,	x2,	x1		#32 36
sw	x3, 0x100(x4)			#36 40
wfi					#40 44
