#!/usr/bin/env python3
"""Remove the two foreground tables from 11.png by filling with floor texture."""
from PIL import Image

import os
downloads_path = os.path.expanduser("~/Downloads/11.png")
assets_path = "/Users/gagsingh/Desktop/workspace/my-space/bulls-eye/assets/images/11.png"

img = Image.open(downloads_path).convert("RGB")
w, h = img.size

# Tables are in lower-left and lower-right. Approximate regions (tuned for 1536x1024).
left_box = (0, int(h * 0.52), int(w * 0.38), h)
right_box = (int(w * 0.62), int(h * 0.52), w, h)

# Sample floor from center strip (between tables) to use as fill
center_strip = img.crop((int(w * 0.42), int(h * 0.72), int(w * 0.58), int(h * 0.92)))
left_fill = center_strip.resize((left_box[2] - left_box[0], left_box[3] - left_box[1]), Image.Resampling.LANCZOS)
right_fill = center_strip.resize((right_box[2] - right_box[0], right_box[3] - right_box[1]), Image.Resampling.LANCZOS)

img.paste(left_fill, (left_box[0], left_box[1]))
img.paste(right_fill, (right_box[0], right_box[1]))

img.save(downloads_path, "PNG", optimize=True)
print("Saved", downloads_path)
img.save(assets_path, "PNG", optimize=True)
print("Saved", assets_path)
