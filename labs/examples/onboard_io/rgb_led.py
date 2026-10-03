#!/usr/bin/env python3
"""Красный, зелёный, синий и белый на встроенном RGB LED."""

from led_io import (
    controlled_led,
    led_directory,
    led_max,
    led_read,
    led_write,
    run_demo,
)


def main():
    directory = led_directory("rgb:status*")
    maximum = led_max(directory)
    colors = led_read(directory, "multi_index").split()
    if len(colors) != 3 or set(colors) != {"red", "green", "blue"}:
        raise ValueError("Ожидались три разные компоненты RGB")

    steps = (
        ("красный", "red"),
        ("зелёный", "green"),
        ("синий", "blue"),
        ("белый", None),
    )
    with controlled_led(directory) as stopped:
        led_write(directory, "brightness", 0)
        brightness = max(maximum // 8, 1)
        for name, selected in steps:
            if stopped.is_set():
                break
            values = " ".join(
                str(maximum if selected is None or color == selected else 0)
                for color in colors
            )
            led_write(directory, "multi_intensity", values)
            led_write(directory, "brightness", brightness)
            print("{}: {}".format(name, values), flush=True)
            stopped.wait(0.5)


if __name__ == "__main__":
    raise SystemExit(run_demo(main))
