import os
import shutil
from PIL import Image, ImageDraw, ImageFont, ImageStat
import textwrap
import math

# Paths
PROJECT_DIR = "/Users/sergeisobolev/Brains/second-brain/01_Projects/Dogovor24 - консалтинг клиента/AI Coding Training"

# Text Content Mapping (from Presentation MD)
SLIDE_TEXTS = {
    1: "\"Цель — получить преимущества от использования агентов, но без каких-либо компромиссов в качестве программного обеспечения.\" — Андрей Карпаты, 4.2.2026",
    2: "Описать -> Сгенерировать -> Принять ->\nНадеяться на лучшее.\nПроблема: уязвимости и технический долг.",
    3: "Разрыв между \"почти работает\" и \"работает в продакшене\"\n— это и есть разница между\nvibe coding и agentic engineering.",
    4: "99% времени вы НЕ пишете код напрямую.\nВы оркестрируете агентов, которые пишут код.",
    5: "Определить цель -> Обсудить план -> Подтвердить ->\nИИ выполняет -> Ревью -> Merge",
    6: "Стажёр: учится\nМенеджер: управляет агентами\nАрхитектор: проектирует системы",
    7: "Vibe Coding: Сделать чтобы работало (Демо).\nAgentic: Продакшен-качество без компромиссов.",
    8: "1. Prompt Engineering -> Solution Architecture.\n2. Написание кода -> Code Review at Scale.\n3. Тестирование -> Continuous Validation.",
    9: "Модели становятся умнее, инструменты оркестрации улучшаются. Тот кто освоит этот подход — будет строить системы, которые требовали целых команд.",
    10: "Вопрос не в том, использовать ли ИИ.\nВопрос — научитесь ли вы делать это правильно."
}

def get_dominant_color_bottom(img):
    # Sample the bottom strip of the image
    width, height = img.size
    crop = img.crop((0, height - 1, width, height))
    stat = ImageStat.Stat(crop)
    avg = stat.mean
    return (int(avg[0]), int(avg[1]), int(avg[2]))

def is_bright(color):
    # Calculate luminance
    # Y = 0.299 R + 0.587 G + 0.114 B
    lum = 0.299 * color[0] + 0.587 * color[1] + 0.114 * color[2]
    return lum > 128

def process_slide(slide_num, text):
    filename = f"carousel_slide_{slide_num:02d}.png"
    input_path = os.path.join(PROJECT_DIR, filename)
    output_path = os.path.join(PROJECT_DIR, f"carousel_slide_{slide_num:02d}_text.png")
    
    if not os.path.exists(input_path):
        print(f"Skipping {filename} (not found)")
        return

    try:
        img = Image.open(input_path).convert("RGB")
    except Exception as e:
        print(f"Error opening {filename}: {e}")
        return

    # Canvas Setup
    CANVAS_WIDTH = 1080
    CANVAS_HEIGHT = 1350
    
    # Text area is bottom 20%
    TEXT_AREA_RATIO = 0.2
    TEXT_AREA_HEIGHT = int(CANVAS_HEIGHT * TEXT_AREA_RATIO) # 270px
    IMAGE_AREA_HEIGHT = CANVAS_HEIGHT - TEXT_AREA_HEIGHT     # 1080px (80%)

    # "Continue Background" Logic
    if slide_num == 6:
        bg_color = (0, 0, 0) # Force solid black for slide 6
    else:
        bg_color = get_dominant_color_bottom(img)
    
    canvas = Image.new('RGB', (CANVAS_WIDTH, CANVAS_HEIGHT), bg_color)
    
    # Scale Image to fit HEIGHT of Image Area (1080px)
    target_h = IMAGE_AREA_HEIGHT
    ratio = target_h / img.height
    target_w = int(img.width * ratio)
    
    img_resized = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    # Position: Centered horizontally, Top aligned (y=0)
    x = (CANVAS_WIDTH - target_w) // 2
    y = 0 
    canvas.paste(img_resized, (x, y))
    
    # Gradient Fade Logic - Create smooth transition to background
    # Only for slide 6 as requested
    if slide_num == 6:
        FADE_HEIGHT = 300 # Pixel height of the fade
        fade_overlay = Image.new('RGB', (CANVAS_WIDTH, FADE_HEIGHT), bg_color)
        mask = Image.new('L', (CANVAS_WIDTH, FADE_HEIGHT))
        mask_draw = ImageDraw.Draw(mask)
        
        for i in range(FADE_HEIGHT):
            # Linear fade from 0 (transparent) to 255 (opaque)
            # Using linear for simplicity, but could be i/FADE_HEIGHT**2 for smoother
            alpha = int(255 * (i / FADE_HEIGHT))
            mask_draw.line((0, i, CANVAS_WIDTH, i), fill=alpha)
            
        # Paste the fade overlay at the bottom of the IMAGE AREA
        fade_y = IMAGE_AREA_HEIGHT - FADE_HEIGHT
        canvas.paste(fade_overlay, (0, fade_y), mask)
    
    # Text Setup
    draw = ImageDraw.Draw(canvas)
    text_color = (0, 0, 0) if is_bright(bg_color) else (200, 200, 200)
    
    # Font Logic - Trying for Oswald or similar condensed font
    try:
        possible_fonts = [
            "/Applications/Camtasia.app/Contents/Resources/fonts/Oswald-Regular.ttf",
            "/Applications/Camtasia.app/Contents/Resources/fonts/Oswald-Bold.ttf",
            "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/Library/Fonts/Arial.ttf" # Fallback
        ]
        
        chosen_font = None
        for f in possible_fonts:
            if os.path.exists(f):
                # Try simple load check
                try:
                    ImageFont.truetype(f, 20)
                    chosen_font = f
                    break
                except:
                    continue
        
        # Oswald is condensed, so we can use slightly larger font size
        font_size = 45 if chosen_font and "Oswald" in str(chosen_font) else 45
        font = ImageFont.truetype(chosen_font or "/Library/Fonts/Arial.ttf", font_size)
        print(f"Using font: {chosen_font}")
    except Exception as e:
        print(f"Font loading error: {e}, using default")
        font = ImageDraw.getdraw().getfont()
        font_size = 20

    # Text Layout Logic
    # Center text in bottom area
    
    lines = text.split('\n')
    wrapped_lines = []
    # Use narrower wrap width to ensure margins
    # With font size 55px (Oswald), ~40 chars fits width 1080 okay but tight. 35 chars is safer margin.
    wrap_width = 55 
    for line in lines:
        wrapped_lines.extend(textwrap.wrap(line, width=wrap_width))
        
    # Calculate Total Text Height
    line_spacing = 1 # Tighter spacing for Oswald
    
    # Using 'ascent-descent' logic for accurate height
    single_line_h = font_size
    try:
        ascent, descent = font.getmetrics()
        single_line_h = ascent + descent
    except:
        pass
        
    total_lines = len(wrapped_lines)
    total_text_h = single_line_h * total_lines + (single_line_h * (line_spacing - 1)) * (total_lines - 1)
    
    # Center Y in the text area
    text_box_center_y = IMAGE_AREA_HEIGHT + (TEXT_AREA_HEIGHT / 2)
    start_y = text_box_center_y - (total_text_h / 2)
    
    current_y = start_y
    for w_line in wrapped_lines:
        bbox = draw.textbbox((0, 0), w_line, font=font)
        w = bbox[2] - bbox[0]
        
        draw_x = (CANVAS_WIDTH - w) // 2
        draw.text((draw_x, current_y), w_line, font=font, fill=text_color)
        
        current_y += single_line_h * line_spacing
            
    canvas.save(output_path)
    print(f"Saved {output_path}")

def main():
    print("Processing slides with new font (Oswald) and margins...")
    for i in range(1, 11):
        if i in SLIDE_TEXTS:
            process_slide(i, SLIDE_TEXTS[i])
    print("Done.")

if __name__ == "__main__":
    main()
