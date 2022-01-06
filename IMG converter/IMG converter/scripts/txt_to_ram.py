import struct

filename = input("What's the output file name? ")
out = open("./sprite_ram/" + filename + ".ram", 'wb')
for i in range(1,17):
    f =  open("./sprite_palette/tank_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()

f =  open("./sprite_palette/wall.txt", 'r')
for line in f:
    hex = int("0x" + str(line[0]) + str(line[1]), 16)
    # print(hex)
    s = struct.pack('b', hex)
    out.write(s)
    s = struct.pack('b', 0)
    out.write(s)
f.close()

f =  open("./sprite_palette/stone.txt", 'r')
for line in f:
    hex = int("0x" + str(line[0]) + str(line[1]), 16)
    # print(hex)
    s = struct.pack('b', hex)
    out.write(s)
    s = struct.pack('b', 0)
    out.write(s)
f.close()

f =  open("./sprite_palette/water.txt", 'r')
for line in f:
    hex = int("0x" + str(line[0]) + str(line[1]), 16)
    # print(hex)
    s = struct.pack('b', hex)
    out.write(s)
    s = struct.pack('b', 0)
    out.write(s)
f.close()

f =  open("./sprite_palette/grass.txt", 'r')
for line in f:
    hex = int("0x" + str(line[0]) + str(line[1]), 16)
    # print(hex)
    s = struct.pack('b', hex)
    out.write(s)
    s = struct.pack('b', 0)
    out.write(s)
f.close()

for i in range(1,5):
    f =  open("./sprite_palette/bullet_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()

# fill in blank data
for i in range(0,1024):
    s = struct.pack('b', 0)
    out.write(s)
out.close()