from deepface import DeepFace

def verify_faces(id_image, selfie_image):
    try:
        result = DeepFace.verify(
            id_image,
            selfie_image,
            model_name='Facenet',
            detector_backend='opencv'  # faster
        )
        return result["verified"]
    except:
        return False