size = input("palette bit size? ")
count = 0
out = open("./palette_sv/palette_sv.txt", 'w')
f = open("./palette/palette.txt", 'r')
for line in f:
    out.write(size + "'d" + str(count) + ":\n")
    out.write("begin\n")
    out.write("\tVGA_R = 8'h" + str(line[2]) + str(line[3]) + ";\n")
    out.write("\tVGA_G = 8'h" + str(line[4]) + str(line[5]) + ";\n")
    out.write("\tVGA_B = 8'h" + str(line[6]) + str(line[7]) + ";\n")
    out.write("end\n")
    count += 1
out.write("default:\n")
out.write("begin\n")
out.write("\tVGA_R = 8'h00;\n")
out.write("\tVGA_G = 8'h00;\n")
out.write("\tVGA_B = 8'h00;\n")
out.write("end\n")
f.close()
out.close()
