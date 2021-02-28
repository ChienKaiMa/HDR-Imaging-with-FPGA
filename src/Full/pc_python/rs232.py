#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv

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

fp = open('mountain.bmp', 'rb')
fw = open('image.out', 'wb')
assert fp

image = fp.read()
print(len(image))
#fw.write(image)
#s.write(image)

for i in range(len(image)-640, 1076, -640):
    for j in range(1, 641, 1):
        s.write(image[i+j-1])
        #fw.write(image[i])
        #print(len(image[i]))
s.write(image[1076])

fp.close()
fw.close()
