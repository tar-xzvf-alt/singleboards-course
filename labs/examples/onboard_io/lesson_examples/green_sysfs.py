"""Пять миганий зелёного LED через файлы sysfs."""

from pathlib import Path
from time import sleep

led = Path("/sys/class/leds/green:status")
maximum = led.joinpath("max_brightness").read_text().strip()
led.joinpath("trigger").write_text("none\n")

try:
    for _ in range(5):
        led.joinpath("brightness").write_text(maximum + "\n")
        sleep(0.5)
        led.joinpath("brightness").write_text("0\n")
        sleep(0.5)
except KeyboardInterrupt:
    pass
finally:
    led.joinpath("brightness").write_text("0\n")
