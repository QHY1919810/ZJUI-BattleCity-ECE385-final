addr = 0

filename = input("What's the output file name? ")
out = open("./sprite_ram/" + filename + ".txt", 'w')
for i in range(1,17):
    f =  open("./sprite_palette/tank_" + str(i) + ".txt", 'r')
    for line in f:
        out.write(line)
        addr += 1
    f.close()

print("parameter [19:0] Barrier_ADDR = 20'd%d;" %addr)
f =  open("./sprite_palette/wall.txt", 'r')
for line in f:
    out.write(line)
    addr += 1
f.close()

f =  open("./sprite_palette/stone.txt", 'r')
for line in f:
    out.write(line)
    addr += 1
f.close()

f =  open("./sprite_palette/water.txt", 'r')
for line in f:
    out.write(line)
    addr += 1
f.close()

f =  open("./sprite_palette/grass.txt", 'r')
for line in f:
    out.write(line)
    addr += 1
f.close()

print("parameter [19:0] Bullet_ADDR = 20'd%d;" %addr)
for i in range(1,5):
    f =  open("./sprite_palette/bullet_" + str(i) + ".txt", 'r')
    for line in f:
        out.write(line)
        addr += 1
    f.close()

print("parameter [19:0] Stage_ADDR = 20'd%d;" %addr)
f =  open("./sprite_palette/stage.txt", 'r')
for line in f:
    out.write(line)
    addr += 1
f.close()

print("parameter [19:0] UI_ADDR = 20'd%d;" %addr)
for i in range(1,5):
    f =  open("./sprite_palette/UI_" + str(i) + ".txt", 'r')
    for line in f:
        out.write(line)
        addr += 1
    f.close()

print("parameter [19:0] Number_ADDR = 20'd%d;" %addr)
for i in range(0,10):
    f =  open("./sprite_palette/" + str(i) + ".txt", 'r')
    for line in f:
        out.write(line)
        addr += 1
    f.close()

print("parameter [19:0] Start_Menu_ADDR = 20'd%d;" %addr)
f = open("./sprite_palette/Start_Menu_2.txt", 'r')
for line in f:
    out.write(line)
    addr += 1
f.close()

print("RAM size: %d" %addr)

out.close()