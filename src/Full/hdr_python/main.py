from math import *
import hdr_g
import cv2
images = []
for i in range(6):
    image_r = "./data/0"+str(i)+".png"
    #image_r = "./example/sample2-0"+str(i+1)+".jpg"
    image = cv2.imread(image_r,0)
    images.append(image)
log_exposure_times = [int(i) for i in [log(1/1000),log(1/500),log(1/250),log(1/125),log(1/64),log(1/32)]]
image_g = hdr_g.computeHDR(images, log_exposure_times, smoothing_lambda=100., gamma=0.8)
image_w = "./data/result.png"
cv2.imwrite(image_w,image_g)