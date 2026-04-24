from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path("/Users/pain/Documents/flowtype/FlowType")
SOURCE_DIR = ROOT / "marketing" / "screenshots"
OUTPUT_DIR = ROOT / "marketing" / "app-store"

FONT_BOLD = "/System/Library/Fonts/Avenir Next.ttc"
FONT_REGULAR = "/System/Library/Fonts/Avenir.ttc"

CANVAS_SIZE = (1290, 2796)
SHOT_WIDTH = 820
TOP_MARGIN = 92
SCREENSHOT_TOP = 760

SLIDES = [
    {
        "source": "onboarding.png",
        "output": "01-onboarding-marketing.png",
        "headline": "Speak once.\nSend polished.",
        "body": "Turn rough voice notes into clean writing for email, Slack, notes, and task lists.",
        "bg_top": (13, 46, 71),
        "bg_bottom": (4, 10, 18),
        "accent": (61, 214, 198),
    },
    {
        "source": "home.png",
        "output": "02-home-marketing.png",
        "headline": "Capture ideas fast",
        "body": "Pick a mode, speak naturally, and turn rough thoughts into send-ready writing.",
        "bg_top": (243, 247, 249),
        "bg_bottom": (224, 232, 237),
        "accent": (15, 57, 88),
    },
    {
        "source": "review.png",
        "output": "03-review-marketing.png",
        "headline": "Review before\nyou send",
        "body": "Shorten, polish, copy, or share the result after FlowType cleans up your words.",
        "bg_top": (245, 248, 250),
        "bg_bottom": (233, 238, 243),
        "accent": (47, 209, 191),
    },
    {
        "source": "help.png",
        "output": "04-trust-marketing.png",
        "headline": "Built with trust\nin mind",
        "body": "See privacy, processing, and account controls in one place before you ship it.",
        "bg_top": (239, 242, 249),
        "bg_bottom": (223, 230, 240),
        "accent": (16, 43, 68),
    },
    {
        "source": "usage.png",
        "output": "05-usage-marketing.png",
        "headline": "Know where you stand",
        "body": "Weekly usage stays clear while FlowType is in early release and growing.",
        "bg_top": (247, 248, 252),
        "bg_bottom": (232, 236, 244),
        "accent": (17, 49, 78),
    },
    {
        "source": "history.png",
        "output": "06-history-marketing.png",
        "headline": "Pick up where\nyou left off",
        "body": "Recent polished drafts stay on your iPhone so good work is easy to reuse.",
        "bg_top": (246, 248, 250),
        "bg_bottom": (228, 233, 239),
        "accent": (47, 209, 191),
    },
]


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def gradient_background(size, top_rgb, bottom_rgb):
    width, height = size
    img = Image.new("RGB", size, top_rgb)
    px = img.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(int(top_rgb[i] * (1 - t) + bottom_rgb[i] * t) for i in range(3))
        for x in range(width):
            px[x, y] = color
    return img


def add_glow(base: Image.Image, accent):
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.ellipse((-120, -40, 720, 800), fill=accent + (52,))
    draw.ellipse((790, 1680, 1450, 2520), fill=accent + (40,))
    return Image.alpha_composite(base.convert("RGBA"), glow)


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def fit_screenshot(path: Path):
    shot = Image.open(path).convert("RGBA")
    scale = SHOT_WIDTH / shot.width
    resized = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.Resampling.LANCZOS)
    return resized


def shadow_layer(size, box, radius=46):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(box, radius=radius, fill=(11, 24, 37, 82))
    return layer.filter(ImageFilter.GaussianBlur(24))


def add_pill(draw, accent, text_color):
    x, y, w, h = 76, TOP_MARGIN, 180, 56
    draw.rounded_rectangle((x, y, x + w, y + h), radius=28, fill=accent + (255,))
    label_font = font(FONT_BOLD, 28)
    draw.text((x + 30, y + 12), "FlowType", font=label_font, fill=text_color)


def wrap_text(draw, text, text_font, max_width):
    words = text.split()
    lines = []
    current = []

    for word in words:
        trial = " ".join(current + [word])
        width = draw.textbbox((0, 0), trial, font=text_font)[2]
        if current and width > max_width:
            lines.append(" ".join(current))
            current = [word]
        else:
            current.append(word)

    if current:
        lines.append(" ".join(current))

    return "\n".join(lines)


def add_text(draw, slide, dark_text: bool):
    headline_font = font(FONT_BOLD, 92)
    body_font = font(FONT_REGULAR, 38)
    footer_font = font(FONT_BOLD, 26)

    text_color = (12, 17, 23) if dark_text else (255, 255, 255)
    body_color = (88, 96, 108) if dark_text else (221, 230, 236)

    draw.multiline_text((76, 184), slide["headline"], font=headline_font, fill=text_color, spacing=6)
    wrapped_body = wrap_text(draw, slide["body"], body_font, 1080)
    draw.multiline_text((76, 430), wrapped_body, font=body_font, fill=body_color, spacing=10)
    draw.text((76, 654), "Speak once. Send polished.", font=footer_font, fill=slide["accent"])


def compose_slide(slide):
    base = gradient_background(CANVAS_SIZE, slide["bg_top"], slide["bg_bottom"])
    canvas = add_glow(base, slide["accent"])
    draw = ImageDraw.Draw(canvas)

    dark_text = sum(slide["bg_top"]) > 500
    add_pill(draw, slide["accent"], (8, 13, 18) if sum(slide["accent"]) > 380 else (255, 255, 255))
    add_text(draw, slide, dark_text)

    screenshot = fit_screenshot(SOURCE_DIR / slide["source"])
    x = (CANVAS_SIZE[0] - screenshot.width) // 2
    y = SCREENSHOT_TOP
    box = (x, y, x + screenshot.width, y + screenshot.height)

    canvas = Image.alpha_composite(canvas, shadow_layer(CANVAS_SIZE, box))
    mask = rounded_mask(screenshot.size, 46)
    shot_layer = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    shot_layer.paste(screenshot, (x, y), mask)

    stroke = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    stroke_draw = ImageDraw.Draw(stroke)
    stroke_draw.rounded_rectangle(box, radius=46, outline=(255, 255, 255, 160), width=4)

    canvas = Image.alpha_composite(canvas, shot_layer)
    canvas = Image.alpha_composite(canvas, stroke)
    return canvas.convert("RGB")


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for slide in SLIDES:
        img = compose_slide(slide)
        img.save(OUTPUT_DIR / slide["output"], quality=96)
    print(f"Saved marketing assets to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
