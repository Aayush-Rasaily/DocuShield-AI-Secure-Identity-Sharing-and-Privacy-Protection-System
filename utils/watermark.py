from PIL import Image, ImageDraw

def add_watermark(image_path, text="For Verification Only"):
    img = Image.open(image_path)
    draw = ImageDraw.Draw(img)

    draw.text((20, 20), text, fill=(255, 0, 0))

    output_path = image_path.replace(".jpg", "_watermarked.jpg")
    img.save(output_path)

    return output_path