"""Те же пять миганий через python-periphery."""

from pathlib import Path
from time import sleep
from periphery import LED

Path("/sys/class/leds/green:status/trigger").write_text("none\n")

with LED("green:status") as led:
    try:
        for _ in range(5):
            led.write(True)
            sleep(0.5)
            led.write(False)
            sleep(0.5)
    except KeyboardInterrupt:
        pass
    finally:
        led.write(False)
