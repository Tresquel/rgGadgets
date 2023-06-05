import struct
from PIL import Image
import cv2
import tempfile
import os
import time

temp_dir = tempfile.mkdtemp()
frames_dir = os.path.join(temp_dir, 'frames')
os.mkdir(frames_dir)
print("Converting to frames (this might take a while)...")
for file in os.listdir(os.curdir):
    if file.startswith("toconvert."):
        filecon = file
        os.system(f"ffmpeg -i {file} -vf palettegen {temp_dir}/palette.png -hide_banner -loglevel error")
        os.system(f"ffmpeg -i {file} -filter:v scale=-1:224 {temp_dir}/video.mp4 -hide_banner -loglevel error")
        os.system(f'ffmpeg -i {temp_dir}/video.mp4 -i {temp_dir}/palette.png -filter_complex "paletteuse" {frames_dir}/%d.png -hide_banner -loglevel error')
        break

frames = 0
print("Detecting frames...")

for file in os.listdir(frames_dir):
    if file.endswith(".png"):
        frames += 1
        
print(f"Detected {frames} frames in total")

if frames == 0:
    raise ValueError("No frames detected")

print("Starting conversion...")
print("Creating palette...")

palette = []
imag = Image.open(f"{temp_dir}/palette.png")
imag = imag.convert("RGB")
x, y = imag.size
for ypos in range(0, y):
    for xpos in range(0, x):
        pixelRGB = imag.getpixel((xpos, ypos))
        if pixelRGB not in palette:
            palette.append(pixelRGB)

print("Palette created")

print(f"Conversion will take around {round(frames * 0.35)} seconds.")
userInput = input("Do you want to continue? y/N: ")
if userInput.lower() != "y":
    print("ok, exiting.")
    exit(0)

# Header
data = b"RGVIDEO"  # Type
imag = Image.open(f"{frames_dir}/1.png")
imag = imag.convert("RGB")
x, y = imag.size
data += struct.pack('I', x)
data += struct.pack('I', frames)  # Number of frames
cap = cv2.VideoCapture(filecon)
framerate = int(cap.get(cv2.CAP_PROP_FPS))
cap.release()
if framerate == 0: 
    print("framerate not found, setting to 30")
    framerate = 30 # Specify own framerate
data += struct.pack("B", int(framerate))  # Framerate
for color in palette:
    r, g, b = color
    data += struct.pack('BBB', r, g, b)
data += b"VIDEODATA"

print("Converting frames...")
for i in range(1, frames + 1):
    starttime = time.perf_counter()
    imag = Image.open(f"{frames_dir}/{i}.png")
    imag = imag.convert("RGB")
    x, y = imag.size
    frameData = b""
    for ypos in range(0, y):
        for xpos in range(0, x):
            pixelRGB = imag.getpixel((xpos, ypos))
            color_index = palette.index(pixelRGB)
            frameData += struct.pack('B', color_index)
    print(f"converted frame {i} in {round(time.perf_counter() - starttime, 2)} seconds")
    data += frameData
    
print("conversion done")
with open("video.rgv", "wb") as f:
    print("saving...")
    f.write(data)
    print("done")