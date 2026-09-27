#!/usr/bin/env python3
"""
Generate a stylized "M" logo for Maya Pro with cyan/neon gradient.
Matches the Maya Pro theme colors:
- neonCyan: #00F2FE
- neonViolet: #4FACFE
- neonEmerald: #00FF87
"""

from PIL import Image, ImageDraw, ImageFont
import math

# Maya Pro theme colors
NEON_CYAN = (0, 242, 254)
NEON_VIOLET = (79, 172, 254)
NEON_EMERALD = (0, 255, 135)
BG_DARK = (15, 15, 25)  # slate900-ish

def create_gradient_image(width, height, colors, direction='diagonal'):
    """Create a gradient image."""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for y in range(height):
        for x in range(width):
            if direction == 'diagonal':
                ratio = (x + y) / (width + height)
            elif direction == 'horizontal':
                ratio = x / width
            else:
                ratio = y / height
            
            ratio = max(0, min(1, ratio))
            
            # Interpolate between colors
            if ratio < 0.5:
                r1, g1, b1 = colors[0]
                r2, g2, b2 = colors[1]
                t = ratio * 2
            else:
                r1, g1, b1 = colors[1]
                r2, g2, b2 = colors[2]
                t = (ratio - 0.5) * 2
            
            r = int(r1 + (r2 - r1) * t)
            g = int(g1 + (g2 - g1) * t)
            b = int(b1 + (b2 - b1) * t)
            
            draw.point((x, y), fill=(r, g, b, 255))
    
    return img

def create_stylized_m_logo(size=1024):
    """Create a stylized M logo with gradient."""
    # Create base image
    img = Image.new('RGBA', (size, size), BG_DARK + (255,))
    draw = ImageDraw.Draw(img)
    
    # Center and scale
    center_x = size // 2
    center_y = size // 2
    scale = size / 100.0
    
    # M shape points (normalized to 100x100, then scaled)
    # Main M shape - 5 points forming M
    stroke_width = int(size * 0.06)  # 6% of size
    
    # Define M path points (normalized 0-100)
    m_points = [
        (12, 88),  # bottom left
        (12, 12),  # top left
        (38, 45),  # left peak
        (50, 50),  # center diamond
        (62, 45),  # right peak
        (88, 12),  # top right
        (88, 88),  # bottom right
    ]
    
    # Scale points
    scaled_points = [(center_x + (x - 50) * scale, center_y + (y - 50) * scale) for x, y in m_points]
    
    # Draw main M stroke with gradient
    stroke_width = int(size * 0.055)
    
    # Create gradient for stroke
    gradient_colors = [NEON_CYAN, NEON_VIOLET, NEON_EMERALD]
    
    # Draw main M path
    for i in range(len(scaled_points) - 1):
        x1, y1 = scaled_points[i]
        x2, y2 = scaled_points[i + 1]
        
        # Calculate gradient color for this segment
        t = i / (len(scaled_points) - 2)
        if t < 0.5:
            c1 = NEON_CYAN
            c2 = NEON_VIOLET
            t_seg = t * 2
        else:
            c1 = NEON_VIOLET
            c2 = NEON_EMERALD
            t_seg = (t - 0.5) * 2
        
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        color = (r, g, b, 255)
        
        draw.line([scaled_points[i], scaled_points[i + 1]], fill=color, width=int(size * 0.055), joint='round')
    
    # Draw inner accent line
    accent_points = [
        (22, 78), (30, 35), (50, 60), (70, 35), (78, 78)
    ]
    scaled_accent = [(center_x + (x - 50) * scale, center_y + (y - 50) * scale) for x, y in accent_points]
    
    for i in range(len(scaled_accent) - 1):
        draw.line([scaled_accent[i], scaled_accent[i + 1]], fill=NEON_EMERALD + (180,), width=int(size * 0.02))
    
    # Draw center diamond
    diamond_size = size * 0.04
    diamond_points = [
        (center_x, center_y - diamond_size),
        (center_x + diamond_size, center_y),
        (center_x, center_y + diamond_size),
        (center_x - diamond_size, center_y),
    ]
    draw.polygon(diamond_points, fill=NEON_EMERALD)
    
    # Add outer glow ring
    glow_radius = int(size * 0.48)
    for i in range(3):
        alpha = 80 - i * 20
        radius = int(size * 0.5) - i * 4
        draw.ellipse([
            center_x - radius, center_y - radius,
            center_x + radius, center_y + radius
        ], outline=NEON_CYAN + (alpha,), width=2)
    
    return img

def create_app_icon_sizes(base_image):
    """Create all required app icon sizes for Android/iOS."""
    sizes = {
        'android': {
            'mdpi': 48,
            'hdpi': 72,
            'xhdpi': 96,
            'xxhdpi': 144,
            'xxxhdpi': 192,
        },
        'ios': {
            '20@2x': 40,
            '20@3x': 60,
            '29@2x': 58,
            '29@3x': 87,
            '40@2x': 80,
            '40@3x': 120,
            '60@2x': 120,
            '60@3x': 180,
            '76@1x': 76,
            '76@2x': 152,
            '83.5@2x': 167,
            '1024': 1024,
        }
    }
    
    return sizes

def main():
    # Create the main logo
    print("Generating stylized M logo...")
    logo = create_stylized_m_logo(1024)
    
    # Save master logo
    logo.save('/home/ubuntu/M-2.0/maya_flutter/assets/icon/app_icon.png')
    print("Saved master logo to assets/icon/app_icon.png")
    
    # Also save a version for flutter_launcher_icons
    logo.save('/home/ubuntu/M-2.0/maya_flutter/assets/icon/launcher_icon.png')
    print("Saved launcher icon to assets/icon/launcher_icon.png")
    
    print("Done!")

if __name__ == '__main__':
    main()