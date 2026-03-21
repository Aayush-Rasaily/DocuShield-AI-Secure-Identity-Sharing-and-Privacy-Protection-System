"""
Aadhaar card augmentation pipeline.
Simulates real-world scanning conditions: glare, blur, skew, crop.
Uses Albumentations. Call `get_augmentation_pipeline()` to get the transform.
"""

import albumentations as A
import cv2
import numpy as np


def get_augmentation_pipeline(image_size: int = 640) -> A.Compose:
    """
    Returns an Albumentations pipeline with 4 augmentation types:
    1. Glare simulation (RandomSunFlare)
    2. Blur (MotionBlur + GaussianBlur)
    3. Perspective skew (Perspective)
    4. Random crop (RandomResizedCrop)
    """
    return A.Compose(
        [
            # 1. Glare simulation
            A.RandomSunFlare(
                flare_roi=(0.0, 0.0, 1.0, 0.5),
                angle_lower=0,
                num_flare_circles_lower=3,
                num_flare_circles_upper=6,
                src_radius=200,
                p=0.3,
            ),

            # 2. Blur — motion or gaussian (real-world hand shake / scan blur)
            A.OneOf(
                [
                    A.MotionBlur(blur_limit=(3, 9), p=1.0),
                    A.GaussianBlur(blur_limit=(3, 7), p=1.0),
                ],
                p=0.4,
            ),

            # 3. Perspective skew (card held at angle)
            A.Perspective(scale=(0.02, 0.08), p=0.5),

            # 4. Random crop (partial card scan)
            A.RandomResizedCrop(
                size=(image_size, image_size),
                scale=(0.8, 1.0),
                ratio=(0.9, 1.1),
                p=0.4,
            ),

            # Standard normalize
            A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ],
        bbox_params=A.BboxParams(
            format="yolo",
            label_fields=["class_labels"],
            min_visibility=0.3,
        ),
    )


def visualize_augmented_batch(image_path: str, n: int = 4) -> None:
    """
    Visual verification — applies pipeline n times and saves a grid to /tmp/aug_preview.jpg
    """
    image = cv2.imread(image_path)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = cv2.resize(image, (640, 640))

    pipeline = A.Compose(
        [
            A.RandomSunFlare(p=0.5),
            A.OneOf([A.MotionBlur(p=1.0), A.GaussianBlur(p=1.0)], p=0.5),
            A.Perspective(scale=(0.02, 0.08), p=0.5),
            A.RandomResizedCrop(size=(640,640), scale=(0.8, 1.0), p=0.5),
        ]
    )

    results = [pipeline(image=image)["image"] for _ in range(n)]
    row1 = np.concatenate([image] + results[:2], axis=1)
    row2 = np.concatenate([image] + results[2:4], axis=1)
    grid = np.concatenate([row1, row2], axis=0)

    out = cv2.cvtColor(grid, cv2.COLOR_RGB2BGR)
    cv2.imwrite("/tmp/aug_preview.jpg", out)
    print("Saved preview to /tmp/aug_preview.jpg")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        visualize_augmented_batch(sys.argv[1])
    else:
        print("Usage: python augmentation.py path/to/sample_aadhaar.jpg")
