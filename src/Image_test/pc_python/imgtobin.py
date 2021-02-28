#!/usr/bin/env python

fi = open('mountain.bmp', 'rb')
fo = open('mountain.bin', 'wb')
assert fi and fo

image = fi.read()
b = bytearray(image)
fo.write(b)

fi.close()
fo.close()
