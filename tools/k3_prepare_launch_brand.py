#!/usr/bin/env python3
"""Re-create native splash art from the existing, approved Care360 brand asset.

Requires Pillow.  Never substitutes an AI approximation for the logo.
The output is generated and used when preparing the final review APK; no
clinical settings, signing material, Firebase files, or release keys change.
"""
from pathlib import Path

SOURCE = Path("assets/images/care360_master_logo.webp")
TARGET = Path("assets/images/care360_splash_brand.png")


def main() -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit(
            "Install Pillow for splash asset generation: python -m pip install Pillow"
        ) from exc

    if not SOURCE.is_file():
        raise SystemExit("Official Care360 logo is missing; do not use a replacement.")

    with Image.open(SOURCE) as image:
        image = image.convert("RGBA")
        # Preserve exact colours, proportions and wordmark. A scaled bitmap
        # cannot create lost resolution; obtain a higher-resolution master
        # before final store approval when source art is too small.
        if image.width < 512 or image.height < 512:
            print(
                f"WARNING: Care360 master is only {image.width}x{image.height}; "
                "native splash may look soft on high-density displays."
            )
        from PIL import ImageDraw
        # Clip only the white square outside the approved circular mark.
        # Supersampling smooths the edge without changing interior artwork.
        mask = Image.new("L", (image.width * 4, image.height * 4), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, mask.width - 1, mask.height - 1), fill=255)
        mask = mask.resize(image.size, Image.Resampling.LANCZOS)
        image.putalpha(mask)
        normal = image.resize((576, 576), Image.Resampling.LANCZOS)
        normal.save(TARGET, format="PNG", optimize=True)
        android12 = Image.new("RGBA", (960, 960), (0, 0, 0, 0))
        android12.alpha_composite(image.resize((632, 632), Image.Resampling.LANCZOS), (164, 164))
        android12.save(TARGET.with_name("care360_splash_android12.png"), format="PNG", optimize=True)

    print(f"Prepared native splash from official logo: {TARGET}")


if __name__ == "__main__":
    main()
