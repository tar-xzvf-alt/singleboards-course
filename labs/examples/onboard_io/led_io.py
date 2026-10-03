"""Общие операции LED class для учебных демонстраций на Python."""

import argparse
from contextlib import contextmanager
from pathlib import Path
import signal
import sys
from threading import Event


def led_directory(pattern):
    """Получить явно заданный каталог либо найти единственный LED."""
    parser = argparse.ArgumentParser(description="Демонстрация встроенного LED")
    parser.add_argument("directory", nargs="?", help="каталог LED в /sys/class/leds")
    args = parser.parse_args()
    if args.directory is not None:
        return Path(args.directory)
    matches = sorted(Path("/sys/class/leds").glob(pattern))
    if len(matches) != 1:
        raise ValueError("LED не найден однозначно; укажите каталог явно")
    return matches[0]


def led_read(directory, name):
    return (directory / name).read_text(encoding="ascii").strip()


def led_write(directory, name, value):
    # Закрытие файла завершает запись в sysfs и сообщает её ошибки.
    with (directory / name).open("w", encoding="ascii") as stream:
        stream.write("{}\n".format(value))


def led_max(directory):
    text = led_read(directory, "max_brightness")
    if not text or any(char not in "0123456789" for char in text):
        raise ValueError("Некорректный max_brightness")
    maximum = int(text)
    if not 0 < maximum <= 0xFFFFFFFF:
        raise ValueError("Некорректный max_brightness")
    return maximum


@contextmanager
def controlled_led(directory):
    """Отключить trigger и гарантировать попытку выключения LED."""
    stopped = Event()

    def stop_demo(signum, frame):
        stopped.set()

    previous = {}
    try:
        for signum in (signal.SIGINT, signal.SIGTERM):
            previous[signum] = signal.signal(signum, stop_demo)
        led_write(directory, "trigger", "none")
        yield stopped
    finally:
        try:
            led_write(directory, "brightness", 0)
        finally:
            for signum, handler in previous.items():
                signal.signal(signum, handler)


def run_demo(main):
    try:
        main()
    except (OSError, ValueError) as error:
        print("Ошибка: {}".format(error), file=sys.stderr)
        return 1
    return 0
