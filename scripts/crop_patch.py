from PIL import Image

im = Image.open("screenshot_graves.png")
# unproject was (620, 522)
# Let crop around x: 450 to 750, y: 350 to 700
crop = im.crop((450, 350, 750, 700))
crop.save("crop_patch.png")
print("Crop saved, size:", crop.size)
