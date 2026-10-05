"""Четыре цвета RGB LED; порядок компонент проверен перед показом."""

from pathlib import Path
from time import sleep

led = Path("/sys/class/leds/rgb:status")
assert led.joinpath("multi_index").read_text().split() == ["red", "green", "blue"]
led.joinpath("trigger").write_text("none\n")
led.joinpath("brightness").write_text("0\n")

try:
    for color in ("255 0 0", "0 255 0", "0 0 255", "255 255 255"):
        print(color, flush=True)
        led.joinpath("multi_intensity").write_text(color + "\n")
        led.joinpath("brightness").write_text("31\n")
        sleep(1)
except KeyboardInterrupt:
    pass
finally:
    led.joinpath("brightness").write_text("0\n")
