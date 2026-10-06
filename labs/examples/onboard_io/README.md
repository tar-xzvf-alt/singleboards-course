# Встроенные светодиоды Lichee RV Dock

Комплект для Linux 6.16 на Allwinner D1: зелёный LED модуля на PC1
и RGB WS2812C-2020 платы Dock на PC0. Управление платой выполняется
через UART, установка не требует картридера.

## Занятие для студенческого кружка

[`student_lesson.md`](student_lesson.md) — текст для студентов в форме
последовательного дневника: от включения LED одной командой к sysfs,
драйверам, Device Tree, библиотеке и аппаратному управлению RGB.

[`lesson.md`](lesson.md) — конспект встречи на 90 минут для начинающих:
теория взаимодействия Linux с оборудованием, сценарий демонстраций,
вопросы для обсуждения и подготовка преподавателя. Студентам не требуется
писать программы. Минимальные примеры в [`lesson_examples/`](lesson_examples/)
показывают прямой sysfs и управление через библиотеку `python-periphery`.
Основные демонстрации этого каталога остаются более универсальными.

Для учебного `lesson_examples/green_library.py` библиотека устанавливается
из текущего Sisyphus для RISC-V пакетом **`python3-module-periphery`**:

```bash
apt-get update
apt-get install python3-module-periphery
unset PYTHONPATH PYTHONHOME
python3 -c 'import periphery; print(periphery.__version__); print(periphery.__file__)'
```

На карте sda установлен `python3-module-periphery-1.1.1-alt1.noarch`.
Пример использует явные `LED(...)` и `close()`: в этой версии
`with LED(...) as led` не возвращает объект. Подготовка и проверка
принадлежности модуля RPM описаны в [конспекте](lesson.md#подготовка-библиотеки).

**Проверено на плате 3 октября 2026 года:** установлен полный Image
с onboard-io DTB, загружено ядро `6.16.0-onboard-io-lab` с PREEMPT_RT.
Обе C-демонстрации завершились с кодом 0; повторный запуск и визуальный
осмотр подтвердили мигание зелёного LED и правильные цвета RGB.
Python-версии также запущены на плате: обе завершились с кодом 0
и оставили светодиоды выключенными. На хосте проверены обработка ошибок,
переставленный порядок RGB и выключение по SIGINT/SIGTERM.

Электрические подключения проверены по
[схеме Dock, лист 2](../../../pictures/archive/lichee_rv_schematic.pdf).
Оранжевый LED подключён к питанию и не управляется программно.
PC0/PC1 не пересекаются с лабораторными SPI1 (PD10–PD15),
I²C2 (PE12/PG15), SD-картой (PF0–PF5) и UART0 (PB8/PB9).
Не включайте альтернативные UART2/I²C2-функции PC0/PC1 одновременно.

## Файлы комплекта

| Файл | Назначение |
|---|---|
| `green_led.c`, `rgb_led.c` | Демонстрации на C |
| `led_io.h` | Общие операции LED class для C |
| `green_led.py`, `rgb_led.py` | Демонстрации на Python с тем же поведением |
| `led_io.py` | Общие операции LED class и обработка остановки для Python |
| `onboard-io.config` | Фрагмент конфигурации ядра для светодиодов и лабораторных SPI/I²C |
| `sun20i-d1-lichee-rv-dock-onboard-io-lab.dts` | Device Tree с добавлением LEDC |

## Почему светодиоды заработали

Для работы нужны три согласованных слоя: конфигурация ядра, Device Tree
конкретной платы и пользовательская программа.

| Устройство | Описание оборудования | Драйвер | Интерфейс программы |
|---|---|---|---|
| Зелёный LED | PC1, active high, узел `gpio-leds` | `leds-gpio` | LED class: `brightness` |
| RGB WS2812C-2020 | LEDC `0x02008000`, PC0, один пиксель, GRB | `leds-sun50i-a100` | LED multicolor: `multi_index`, `multi_intensity`, `brightness` |

Программы на C и Python работают через sysfs, не обращаясь напрямую
к GPIO или регистрам. Для зелёного LED драйвер управляет уровнем PC1.
Для RGB драйвер загружает данные в FIFO через PIO, а точные импульсы
WS2812 формирует аппаратный LEDC. Для одного пикселя DMA не требуется.

Порядок компонент в sysfs объявляет `multi_index`: на этой плате это
`red green blue`. Порядок GRB на проводе задаётся отдельно свойством
`allwinner,pixel-format`; пользовательский массив переставлять в GRB не нужно.

## Что именно добавлено в DTS для светодиодов

**Основное дополнение — отдельный файл
[`sun20i-d1-lichee-rv-dock-onboard-io-lab.dts`](sun20i-d1-lichee-rv-dock-onboard-io-lab.dts).
Он добавляет контроллер RGB LED и выбор функции LEDC на PC0.**
Цепочка включения файлов:

```text
sun20i-d1-lichee-rv-dock-onboard-io-lab.dts   ← дополнение для RGB
└── sun20i-d1-lichee-rv-dock-spi-i2c-lab.dts ← лабораторные SPI1 и I²C2
    └── sun20i-d1-lichee-rv-dock.dts        ← описание Dock
        └── sun20i-d1-lichee-rv.dts        ← модуль, включая зелёный PC1
            └── sun20i-d1.dtsi            ← описание SoC
```

Полное содержимое добавленного DTS:

```dts
// SPDX-License-Identifier: (GPL-2.0+ OR MIT)

#include "sun20i-d1-lichee-rv-dock-spi-i2c-lab.dts"

/ {
    soc {
        ledc: led-controller@2008000 {
            compatible = "allwinner,sun20i-d1-ledc",
                         "allwinner,sun50i-a100-ledc";
            reg = <0x2008000 0x400>;
            interrupts = <SOC_PERIPHERAL_IRQ(20) IRQ_TYPE_LEVEL_HIGH>;
            clocks = <&ccu CLK_BUS_LEDC>, <&ccu CLK_LEDC>;
            clock-names = "bus", "mod";
            resets = <&ccu RST_BUS_LEDC>;
            pinctrl-0 = <&ledc_pc0_pin>;
            pinctrl-names = "default";
            allwinner,pixel-format = "grb";
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";

            multi-led@0 {
                reg = <0>;
                color = <LED_COLOR_ID_RGB>;
                function = LED_FUNCTION_STATUS;
            };
        };
    };
};

&pio {
    ledc_pc0_pin: ledc-pc0-pin {
        pins = "PC0";
        function = "ledc";
    };
};
```

| Добавленная часть | Что она даёт |
|---|---|
| `compatible` | Выбор драйвера по fallback `allwinner,sun50i-a100-ledc` |
| `reg = <0x2008000 0x400>` | Адрес и размер области регистров LEDC |
| `interrupts` | Завершение передачи через источник PLIC 36: для D1 макрос прибавляет 16 к 20 |
| `clocks`, `clock-names`, `resets` | Тактирование шины и контроллера, управление reset |
| `ledc_pc0_pin`, `pinctrl-0` | Переключение PC0 в аппаратную функцию `ledc` |
| `allwinner,pixel-format = "grb"` | Порядок передачи компонент WS2812 на проводе |
| `status = "okay"` | Разрешение создания устройства LEDC |
| `multi-led@0` | Один RGB-пиксель с адресом 0; цвет и функция задают имя `rgb:status` |

Свойства `dmas` и `dma-names` не заданы: драйвер работает через PIO.
Зелёный LED уже описан в DTS модуля и наследуется:

```dts
leds {
    compatible = "gpio-leds";
    led-0 {
        color = <LED_COLOR_ID_GREEN>;
        function = LED_FUNCTION_STATUS;
        gpios = <&pio 2 1 GPIO_ACTIVE_HIGH>; /* банк C (2), пин 1: PC1 */
    };
};
```

При установке на плату изменена ссылка `fdt` в Extlinux: вместо MangoPi DTB
загрузчик использует DTB, собранный из onboard-io DTS.

## Подготовка ядра и DTB на хосте

Используйте проверенную **RISC-V конфигурацию фактически загруженного ядра**
как основу. Фрагмент `onboard-io.config` не является полной конфигурацией:
он не заменяет настройки rootfs, MMC, PREEMPT_RT и Wi-Fi.
Конфигурацию платы можно получить через UART командой
`zcat /proc/config.gz`; текущий `.config` исходников может относиться
к другой сборке.

В локальном дереве 6.16 уже должны быть DTS лабораторных SPI и I²C,
используемые в [лабораторной №8](../../lab8.md).
Если уже объявлены `ledc`/`ledc_pc0_pin`, адаптируйте пример к существующим узлам.
Если исходники содержат результаты сборки, используйте чистую копию
исходного дерева для `O=`; не удаляйте существующую сборку ради примера.

```bash
KERNEL_SRC=/home/taranev/work_repos/kernel-source-6.16
EXAMPLES=/home/taranev/work_repos/singleboards-course/labs/examples/onboard_io
BUILD_DIR="$HOME/kernel-out-onboard-io"
BASE_CONFIG=/путь/к/проверенной/riscv.config

mkdir -p "$BUILD_DIR"
cp "$EXAMPLES/sun20i-d1-lichee-rv-dock-onboard-io-lab.dts" \
  "$KERNEL_SRC/arch/riscv/boot/dts/allwinner/"
```

Добавьте в `arch/riscv/boot/dts/allwinner/Makefile` строку:

```makefile
dtb-$(CONFIG_ARCH_SUNXI) += sun20i-d1-lichee-rv-dock-onboard-io-lab.dtb
```

Объедините конфигурации и разрешите зависимости Kconfig:

```bash
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- \
  "$KERNEL_SRC/scripts/kconfig/merge_config.sh" -m -O "$BUILD_DIR" \
  "$BASE_CONFIG" "$EXAMPLES/onboard-io.config"
make -C "$KERNEL_SRC" O="$BUILD_DIR" ARCH=riscv \
  CROSS_COMPILE=riscv64-linux-gnu- olddefconfig
make -C "$KERNEL_SRC" O="$BUILD_DIR" ARCH=riscv \
  CROSS_COMPILE=riscv64-linux-gnu- -j"$(nproc)" Image dtbs
```

После `olddefconfig` проверьте требуемые опции `=y`, особенно
`LEDS_SUN50I_A100`, `LEDS_CLASS_MULTICOLOR`, `LEDS_GPIO` и `NLS_ISO8859_1`.
Проверьте DTB декомпиляцией: модель **Sipeed Lichee RV Dock**, PC1 для
зелёного LED, PC0 для RGB, прерывание LEDC 36 и активные SPI1/I²C2.
Рассчитайте SHA-256 Image и DTB.

### Какие артефакты использованы при установке

Использован уже подготовленный полный образ из отдельной сборки `O=`:

```text
/tmp/.private/taranev/opencode/kernel-out-onboard-io/arch/riscv/boot/Image
/tmp/.private/taranev/opencode/onboard-io-lab.dtb
```

Версия образа — `6.16.0-onboard-io-lab`, сборка `#1 SMP PREEMPT_RT`
от 3 октября 2026 года. Конфигурация из самого Image совпала с `.config`
его каталога сборки. Подтверждены встроенные опции:

```text
CONFIG_PREEMPT_RT=y
CONFIG_NEW_LEDS=y
CONFIG_LEDS_GPIO=y
CONFIG_LEDS_CLASS_MULTICOLOR=y
CONFIG_LEDS_SUN50I_A100=y
```

Старый `arch/riscv/boot/Image` в каталоге исходников имел другую
конфигурацию с выключенной LED-подсистемой. Текущий `.config` исходников
также не соответствовал тому старому образу.

На хосте C-примеры проверены обычным и RISC-V GCC с
`-std=c11 -O2 -Wall -Wextra -Werror -fsyntax-only`. DTS успешно
препроцессирован и скомпилирован `dtc` без предупреждений.

Контрольные суммы использованного комплекта:

```text
Image (36033024 байта):
3c6b5631fcfdeffecf8c6354a5632eace251b0a9cfb4424901adc915f0ef348d

onboard-io-lab.dtb (21435 байт):
6ceab36cdd58f297eb00ee1629bf9bed3d7c61e65d91277ba8ce9694bf88a29d
```

Это пути и суммы конкретной проверенной сборки. Изменение фрагмента
конфигурации не меняет уже собранный Image; при новой сборке суммы
необходимо вычислить заново.

## Запуск демонстраций

### Python

Нужен Python 3.6 или новее, внешние библиотеки не требуются.
Передайте `green_led.py`, `rgb_led.py` и `led_io.py` в один каталог на плате:

```bash
python3 green_led.py
python3 rgb_led.py
```

Скрипты уже установлены на проверенной плате:

```bash
python3 /root/onboard-io-install/green_led.py
python3 /root/onboard-io-install/rgb_led.py
```

Поведение совпадает с C-версиями:

- Зелёный LED мигает десять раз с периодом 1 с: 0,5 с включён, 0,5 с выключен.
- RGB показывает красный, зелёный, синий и белый по 0,5 с.
  Общая яркость — `max_brightness // 8`, но не меньше 1; на плате это 31 из 255.
- LED находятся автоматически по `green:status*` и `rgb:status*`.
  Если совпадений несколько, передайте каталог явно:

  ```bash
  python3 green_led.py /sys/class/leds/green:status
  python3 rgb_led.py /sys/class/leds/rgb:status
  ```

- Перед ручным управлением trigger отключается записью `none`.
- RGB проверяет, что `multi_index` содержит три разные компоненты
  `red`, `green`, `blue`, и использует именно объявленный порядок.
- При завершении, ошибке, Ctrl-C или SIGTERM программа пытается выключить LED.
  Прежний trigger не восстанавливается. Принудительное завершение SIGKILL
  не позволяет выполнить очистку.
- При ошибках поиска устройства, чтения или записи sysfs программа
  сообщает причину и возвращает ненулевой код завершения.

Запуск требует прав записи LED sysfs; для первого опыта используйте
root через UART. Не запрашивайте PC1 через libgpiod, когда линией
уже владеет `gpio-leds`.

### C

Передайте два `.c`-файла и `led_io.h` в один каталог на плате:

```bash
gcc -std=c11 -O2 -Wall -Wextra -o green_led green_led.c
gcc -std=c11 -O2 -Wall -Wextra -o rgb_led rgb_led.c
./green_led
./rgb_led
```

Уже установленные бинарные программы доступны как
`/root/onboard-io-install/green_led` и `/root/onboard-io-install/rgb_led`.
Они также принимают необязательный путь к каталогу LED.

## Проверка на плате

```bash
uname -a
cat /proc/device-tree/model
zcat /proc/config.gz | grep -E \
  'CONFIG_(PREEMPT_RT|LEDS_GPIO|LEDS_SUN50I_A100|LEDS_CLASS_MULTICOLOR)='
ls -l /sys/class/leds
cat /sys/class/leds/rgb:status/multi_index
ls -l /dev/spidev* /dev/i2c-*
i2cdetect -l
grep -i led /proc/interrupts
```

На проверенной плате доступны `green:status`, `rgb:status`, `/dev/spidev1.0`
и `/dev/i2c-2`. Чтение SPI-настроек через ioctl вернуло режим 0, 8 бит,
1 МГц. UART и Wi-Fi работают; адрес платы при установке — `10.0.1.121`.
Обмен с внешними SPI/I²C-устройствами в этой проверке не выполнялся.

## Текущее состояние остальных компонентов

- **Модули ядра:** `/lib/modules/6.16.0-onboard-io-lab` пока не установлен.
  Проверенные LED, SPI, I²C и Wi-Fi используют встроенные драйверы;
  для модульных функций нужны модули именно этой сборки.
- **OLED-служба:** существующая `oled-display.service` перезапускается
  с `I2C device not found`; такая ошибка была и до обновления.
  Её скрипт проверяет `/dev/i2c-0` и `/dev/i2c-1`, а для лабораторной
  конфигурации доступен `/dev/i2c-2`. Подключение OLED и настройку службы
  необходимо проверить отдельно.
