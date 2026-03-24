import re

def detect_sensitive(text):
    aadhaar = re.findall(r"\d{4}\s\d{4}\s\d{4}", text)
    pan = re.findall(r"[A-Z]{5}[0-9]{4}[A-Z]", text)

    return {
        "aadhaar": aadhaar,
        "pan": pan
    }