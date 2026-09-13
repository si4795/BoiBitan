import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_book_icon(output_path="assets/icon/app_icon.png", size=1024):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # 1. Base Canvas - Deep Obsidian (#0D111A)
    img = Image.new("RGBA", (size, size), (13, 17, 26, 255))
    draw = ImageDraw.Draw(img)
    
    # Subtle radial glow from the center
    glow_canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_canvas)
    center = size // 2
    for r in range(480, 50, -10):
        alpha = int(35 * (1 - r / 480))
        glow_draw.ellipse(
            (center - r, center - r + 40, center + r, center + r + 40),
            fill=(245, 166, 35, alpha) # Warm golden glow
        )
        glow_draw.ellipse(
            (center - r + 30, center - r, center + r - 30, center + r),
            fill=(45, 212, 191, alpha // 2) # Cyan accent glow
        )
    glow_canvas = glow_canvas.filter(ImageFilter.GaussianBlur(30))
    img.alpha_composite(glow_canvas)

    # 2. Outer App Squircle Border (Subtle luxury border)
    border_margin = 48
    corner_radius = 220
    border_box = [border_margin, border_margin, size - border_margin, size - border_margin]
    
    # Subtle inner container background
    inner_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner_draw = ImageDraw.Draw(inner_bg)
    inner_draw.rounded_rectangle(border_box, radius=corner_radius, fill=(20, 25, 38, 255), outline=(245, 166, 35, 90), width=4)
    img.alpha_composite(inner_bg)

    # 3. Floating glowing pages & Open Book Geometry
    cx, cy = size // 2, size // 2 + 30
    
    book_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(book_layer)

    # Book cover base / spine shadow
    spine_x = cx
    spine_top = cy - 140
    spine_bottom = cy + 220
    
    # Back cover shadow (Cyan / Gold trim)
    # Left back cover
    bdraw.polygon([
        (cx - 15, spine_bottom + 25),
        (cx - 335, cy + 195),
        (cx - 335, cy - 70),
        (cx - 15, spine_top + 15),
    ], fill=(16, 185, 129, 140)) # Emerald/Cyan tint

    # Right back cover
    bdraw.polygon([
        (cx + 15, spine_bottom + 25),
        (cx + 335, cy + 195),
        (cx + 335, cy - 70),
        (cx + 15, spine_top + 15),
    ], fill=(245, 158, 11, 140)) # Amber tint

    # Multi-layered page edges (stacked paper effect)
    for offset in range(12, 0, -3):
        alpha_val = 180 + offset * 5
        # Left stack
        bdraw.polygon([
            (cx - 8, spine_top + offset),
            (cx - 315 + offset, cy - 75 + offset),
            (cx - 315 + offset, cy + 175 + offset),
            (cx - 8, spine_bottom + offset),
        ], fill=(225, 231, 239, alpha_val))
        # Right stack
        bdraw.polygon([
            (cx + 8, spine_top + offset),
            (cx + 315 - offset, cy - 75 + offset),
            (cx + 315 - offset, cy + 175 + offset),
            (cx + 8, spine_bottom + offset),
        ], fill=(243, 244, 246, alpha_val))

    # Top Page Surfaces (Parchment white with warm gold sheen)
    # Left main page
    left_page = [
        (cx - 5, spine_top),
        (cx - 160, spine_top - 40),
        (cx - 310, cy - 70),
        (cx - 310, cy + 170),
        (cx - 160, cy + 200),
        (cx - 5, spine_bottom),
    ]
    bdraw.polygon(left_page, fill=(255, 253, 248, 255))

    # Right main page
    right_page = [
        (cx + 5, spine_top),
        (cx + 160, spine_top - 40),
        (cx + 310, cy - 70),
        (cx + 310, cy + 170),
        (cx + 160, cy + 200),
        (cx + 5, spine_bottom),
    ]
    bdraw.polygon(right_page, fill=(255, 255, 255, 255))

    # Spine Center Fold (Dark shading)
    bdraw.polygon([
        (cx - 6, spine_top - 5),
        (cx + 6, spine_top - 5),
        (cx + 6, spine_bottom + 10),
        (cx - 6, spine_bottom + 10)
    ], fill=(210, 215, 222, 255))

    # Stylized text lines on left and right pages
    for i in range(5):
        ly = cy - 20 + i * 32
        lx_start = cx - 270 + i * 8
        lx_end = cx - 40 - i * 5
        bdraw.line([(lx_start, ly), (lx_end, ly)], fill=(203, 213, 225, 220), width=6)

    for i in range(5):
        ry = cy - 20 + i * 32
        rx_start = cx + 40 + i * 5
        rx_end = cx + 270 - i * 8
        bdraw.line([(rx_start, ry), (rx_end, ry)], fill=(203, 213, 225, 220), width=6)

    # Golden bookmark ribbon hanging from top-center down the spine
    ribbon_points = [
        (cx - 12, spine_top - 10),
        (cx + 12, spine_top - 10),
        (cx + 12, spine_bottom + 60),
        (cx, spine_bottom + 40),
        (cx - 12, spine_bottom + 60),
    ]
    bdraw.polygon(ribbon_points, fill=(245, 158, 11, 255))
    bdraw.line([(cx, spine_top - 10), (cx, spine_bottom + 40)], fill=(217, 119, 6, 255), width=2)

    # Glowing literary particles above the book
    sparks = [
        (cx, cy - 200, 16, (245, 158, 11, 250)),
        (cx - 120, cy - 170, 12, (45, 212, 191, 240)),
        (cx + 120, cy - 170, 12, (245, 158, 11, 240)),
        (cx - 200, cy - 130, 8, (45, 212, 191, 200)),
        (cx + 200, cy - 130, 8, (245, 158, 11, 200)),
        (cx - 60, cy - 240, 6, (255, 255, 255, 220)),
        (cx + 60, cy - 240, 6, (255, 255, 255, 220)),
    ]
    for sx, sy, radius, color in sparks:
        bdraw.polygon([
            (sx, sy - radius * 2),
            (sx + radius // 2, sy),
            (sx, sy + radius * 2),
            (sx - radius // 2, sy)
        ], fill=color)
        bdraw.polygon([
            (sx - radius * 2, sy),
            (sx, sy + radius // 2),
            (sx + radius * 2, sy),
            (sx, sy - radius // 2)
        ], fill=color)
        bdraw.ellipse((sx - 3, sy - 3, sx + 3, sy + 3), fill=(255, 255, 255, 255))

    img.alpha_composite(book_layer)

    img.save(output_path, "PNG")
    print(f"Generated master app icon successfully at: {output_path}")

if __name__ == "__main__":
    create_book_icon()

