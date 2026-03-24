def mask_aadhaar(num):
    return "XXXX XXXX " + num[-4:]

def mask_pan(pan):
    return pan[:3] + "XXXXX" + pan[-2:]