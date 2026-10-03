#!/usr/bin/env python3
"""Десять миганий зелёного LED с периодом одна секунда."""

from led_io import controlled_led, led_directory, led_max, led_write, run_demo


def main():
    directory = led_directory("green:status*")
    maximum = led_max(directory)
    with controlled_led(directory) as stopped:
        print("LED: {}; 10 миганий с периодом 1 с".format(directory), flush=True)
        for _ in range(10):
            if stopped.is_set():
                break
            led_write(directory, "brightness", maximum)
            stopped.wait(0.5)
            led_write(directory, "brightness", 0)
            stopped.wait(0.5)


if __name__ == "__main__":
    raise SystemExit(run_demo(main))
