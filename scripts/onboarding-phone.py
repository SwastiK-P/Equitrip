#!/usr/bin/env python3
"""Composite docs/onboarding/OnboardingItinerary.png into PhoneFrame.png.

Writes Equitrip/Assets.xcassets/OnboardingPhone.imageset/OnboardingPhone.png,
the phone on onboarding's bookings page. Baked into one image so the
screenshot fits the bezel's screen exactly (the screen shape is flood-filled
from the frame's transparent centre). Re-run after replacing the screenshot.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

root = Path(__file__).resolve().parent.parent
src = root / "docs/onboarding"
frame = Image.open(src / "PhoneFrame.png").convert("RGBA")
shot = Image.open(src / "OnboardingItinerary.png").convert("RGBA")
W, H = frame.size


def erase(img, box, pad=14):
    """Fills `box` from the rows just above and below it, then softens it.

    Used on the status bar, which sits over the trip photo's blurred sky: a
    vertical blend between the clean rows either side is indistinguishable
    from the sky once blurred, and a mockup reads better without a clock.
    """
    x0, y0, x1, y1 = box
    top = img.crop((x0, y0 - pad, x1, y0 - pad + 1))
    bottom = img.crop((x0, y1 + pad - 1, x1, y1 + pad))
    patch = Image.new("RGBA", (x1 - x0, y1 - y0 + 2 * pad))
    rows = patch.height
    for y in range(rows):
        patch.paste(Image.blend(top, bottom, y / (rows - 1)), (0, y))
    patch = patch.filter(ImageFilter.GaussianBlur(6))
    feather = Image.new("L", patch.size, 0)
    ImageDraw.Draw(feather).rectangle((pad, pad, patch.width - pad, patch.height - pad), fill=255)
    feather = feather.filter(ImageFilter.GaussianBlur(pad / 2))
    img.paste(patch, (x0, y0 - pad), feather)


# Status bar of a 1206 × 2622 capture: the clock, and signal/wifi/battery.
erase(shot, (150, 52, 340, 142))
erase(shot, (795, 52, 1120, 142))

binary = frame.split()[3].point(lambda a: 255 if a < 8 else 0)
ImageDraw.floodfill(binary, (W // 2, H // 2), 128)
mask = binary.point(lambda v: 255 if v == 128 else 0)
x0, y0, x1, y1 = mask.getbbox()
sw, sh = x1 - x0, y1 - y0

scale = max(sw / shot.width, sh / shot.height)
shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.LANCZOS)
left = (shot.width - sw) // 2
shot = shot.crop((left, 0, left + sw, sh))  # top-aligned

layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
layer.paste(shot, (x0, y0))
out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
out.paste(layer, (0, 0), mask)
out.alpha_composite(frame)
out.save(root / "Equitrip/Assets.xcassets/OnboardingPhone.imageset/OnboardingPhone.png", optimize=True)
print("wrote OnboardingPhone.png")
