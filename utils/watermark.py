from PIL import Image, ImageDraw, ImageFont
import os
from datetime import datetime

def add_watermark(image_path, text="For Verification Only"):
    try:
        img = Image.open(image_path).convert("RGBA")

        # 🔥 ADD SHORT TIMESTAMP (clean format)
        timestamp = datetime.now().strftime("%d-%m %H:%M")
        full_text = f"{text} | {timestamp}"

        width, height = img.size

        # 🔥 ADD TOP & BOTTOM BARS
        border_height = int(height * 0.10)  # 10% height (balanced)

        new_img = Image.new(
            "RGBA",
            (width, height + 2 * border_height),
            (0, 0, 0, 255)  # black strip
        )

        # Paste original image in center
        new_img.paste(img, (0, border_height))

        draw = ImageDraw.Draw(new_img)

        # 🔥 SMALLER FONT (clean visibility)
        try:
            font = ImageFont.truetype("arial.ttf", int(width / 35))
        except:
            font = ImageFont.load_default()

        # Get text size
        text_bbox = draw.textbbox((0, 0), full_text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]

        # ===============================
        # 🔝 TOP WATERMARK
        # ===============================
        top_position = (
            (width - text_width) // 2,
            (border_height - text_height) // 2
        )

        draw.text(top_position, full_text, fill=(255, 255, 255), font=font)

        # ===============================
        # 🔻 BOTTOM WATERMARK
        # ===============================
        bottom_position = (
            (width - text_width) // 2,
            height + border_height + (border_height - text_height) // 2
        )

        draw.text(bottom_position, full_text, fill=(255, 255, 255), font=font)

        # Convert back to RGB
        final_img = new_img.convert("RGB")

        # Save output
        base, ext = os.path.splitext(image_path)
        output_path = f"{base}_watermarked{ext}"

        final_img.save(output_path)

        return output_path

    except Exception as e:
        print("❌ Watermark error:", str(e))
        return image_path