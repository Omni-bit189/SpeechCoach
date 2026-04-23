import traceback
import numpy as np
import soundfile as sf
import audio_processor
import os

try:
    # Create fake 5-second silence WAV
    sf.write('test.wav', np.zeros(44100 * 5), 44100)
    print("Testing extract_metrics...")
    metrics = audio_processor.extract_metrics('test.wav')
    print("SUCCESS, wpm:", metrics.words_per_minute)
except Exception as e:
    print("FAILED!")
    traceback.print_exc()
finally:
    if os.path.exists('test.wav'):
        os.remove('test.wav')
