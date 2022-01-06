from PIL import Image
from collections import Counter
from scipy.spatial import KDTree
import numpy as np
def hex_to_rgb(num):
    hex = str(num)
    return int(hex[0:4], 16), int(('0x' + hex[4:6]), 16), int(('0x' + hex[6:8]), 16)
def rgb_to_hex(rgb):
    return "0x%02x%02x%02x" %(rgb[0], rgb[1], rgb[2])
filename = input("What's the image name? ")

im = Image.open("./sprite_originals/" + filename + ".png") #Can be many different formats.
im = im.convert("RGB")

outImg = Image.new('RGB', im.size, color='white')
outFile = open("./sprite_bytes/" + filename + '.txt', 'w')

for y in range(im.size[1]):
    for x in range(im.size[0]):
        pixel = im.getpixel((x,y))
        # print(pixel)
        outImg.putpixel((x,y), pixel)
        r, g, b = im.getpixel((x,y))
        outFile.write("%02x%02x%02x\n" %(r,g,b))
outFile.close()
outImg.save("./sprite_converted/" + filename+ ".png")
im.close()
