data = 0x1000
li   x4, data
#Init Registers
addi x1, x0, 1
addi x2, x0, 2

# x4 -> r1
# x1 -> f1
# x2 -> f0
# x3 -> f2

# inst dest, opA/rs1, opB/rs2
#Hazards Checking
lw x1, 0(x4)
mul	x3,	x2,	x1
sw	x3, 0x100(x4)
addi x4, x4, 4
lw x1, 0(x4)
mul	x3,	x2,	x1
sw	x3, 0x100(x4)
wfi
