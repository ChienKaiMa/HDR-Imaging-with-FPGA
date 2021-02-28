#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv
import numpy as np
from PIL import Image
import struct

assert len(argv) == 2
s = Serial(
    port=argv[1],
    baudrate=115200,
    bytesize=EIGHTBITS,
    parity=PARITY_NONE,
    stopbits=STOPBITS_ONE,
    xonxoff=False,
    rtscts=False
)

### for PNG file
I = np.asarray(Image.open('grass/grass_1_125.png'))
I = I.tolist()
print(np.shape(I))

for i in range(0, 480, 1):
	for j in range(0, 640, 1):
		# print(str(I[i][j]))
		o = struct.pack("B", I[i][j])
		#print(i, j)
		# print(struct.pack("B", I[i][j]))
		s.write(o)
s.write(struct.pack("B", I[479][639]))

### for BMP file
# fp = open('mountain/mountain.bmp', 'rb')
# #fw = open('image.out', 'wb')
# assert fp

# image = fp.read()
# print(len(image))
# #fw.write(image)
# #s.write(image)
# length = len(image)

# for i in range(length-640, 1076, -640):
#     for j in range(1, 641, 1):
#     	# print(image[i + j - 1])
#         s.write(image[i+j-1])
#         #fw.write(image[i])
#         #print(len(image[i]))
# s.write(image[1076])

#fp.close()
#fw.close()
###

# D:\2020Fall-NTUEE-DCLAB\final\RS232\pc_python