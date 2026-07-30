# Enter script code
import time
import subprocess

def move_window_right():
    # Simulate the Super + Right Arrow key press
    subprocess.run(["xdotool", "key", "Super+Right"])

move_window_right()
