import os
import wave
import math
import struct
from PIL import Image, ImageDraw, ImageFont

os.makedirs('assets/audio', exist_ok=True)
os.makedirs('assets/images', exist_ok=True)

# 1. Generate calibration_loop.wav
sample_rate = 44100
duration = 3.0  # seconds
num_samples = int(sample_rate * duration)

with wave.open('assets/audio/calibration_loop.wav', 'w') as wav_file:
    wav_file.setnchannels(1)  # Mono
    wav_file.setsampwidth(2)  # 16-bit
    wav_file.setframerate(sample_rate)
    
    data = []
    for i in range(num_samples):
        t = i / sample_rate
        # Frequency sweep from 350Hz to 850Hz with vibrato
        freq = 440 + 200 * math.sin(2 * math.pi * 3 * t) + 100 * math.sin(2 * math.pi * 0.5 * t)
        # Pulse amplitude
        pulse = 0.6 + 0.4 * math.sin(2 * math.pi * 8 * t)
        # Sine wave + slight harmonic
        val = (0.7 * math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)) * pulse
        sample = int(val * 18000)
        data.append(struct.pack('<h', max(-32767, min(32767, sample))))
    
    wav_file.writeframes(b''.join(data))
print("Generated assets/audio/calibration_loop.wav")

# 2. Generate error_ding.wav
ding_duration = 0.4
num_ding_samples = int(sample_rate * ding_duration)

with wave.open('assets/audio/error_ding.wav', 'w') as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(sample_rate)
    
    data = []
    for i in range(num_ding_samples):
        t = i / sample_rate
        # High crisp ding at 880Hz decaying exponentially
        decay = math.exp(-8 * t)
        val = math.sin(2 * math.pi * 880 * t) * decay
        sample = int(val * 22000)
        data.append(struct.pack('<h', max(-32767, min(32767, sample))))
        
    wav_file.writeframes(b''.join(data))
print("Generated assets/audio/error_ding.wav")

# 3. Generate meme_illegal.png
img1 = Image.new('RGB', (400, 300), color=(15, 23, 42)) # Dark navy
draw1 = ImageDraw.Draw(img1)
# Draw a red warning banner
draw1.rectangle([(20, 20), (380, 80)], fill=(220, 38, 38))
draw1.text((40, 35), "WAIT, THAT'S ILLEGAL", fill=(255, 255, 255))
draw1.rectangle([(30, 100), (370, 220)], outline=(245, 158, 11), width=3, fill=(30, 41, 59))
draw1.text((50, 125), "AUDIO POLICE REPORT:", fill=(245, 158, 11))
draw1.text((50, 150), "User attempted to lower volume", fill=(241, 245, 249))
draw1.text((50, 175), "on a Sound Optimization app.", fill=(241, 245, 249))
draw1.text((50, 245), "Status: REJECTED & MAXED TO 100%", fill=(239, 68, 68))
img1.save('assets/images/meme_illegal.png')
print("Generated assets/images/meme_illegal.png")

# 4. Generate meme_pikachu.png
img2 = Image.new('RGB', (400, 300), color=(254, 240, 138)) # Pikachu yellow tint
draw2 = ImageDraw.Draw(img2)
# Draw surprised face
draw2.ellipse([(140, 50), (260, 170)], fill=(250, 204, 21), outline=(202, 138, 4), width=3)
# Eyes
draw2.ellipse([(165, 85), (185, 105)], fill=(15, 23, 42))
draw2.ellipse([(215, 85), (235, 105)], fill=(15, 23, 42))
# Red cheeks
draw2.ellipse([(145, 115), (165, 135)], fill=(239, 68, 68))
draw2.ellipse([(235, 115), (255, 135)], fill=(239, 68, 68))
# Open mouth (surprised)
draw2.ellipse([(185, 120), (215, 155)], fill=(15, 23, 42))
# Text
draw2.rectangle([(20, 200), (380, 280)], fill=(15, 23, 42))
draw2.text((40, 215), "USER: *clicks stop calibration*", fill=(248, 250, 252))
draw2.text((40, 240), "APP: *plays sound 2x louder*", fill=(248, 113, 113))
img2.save('assets/images/meme_pikachu.png')
print("Generated assets/images/meme_pikachu.png")
