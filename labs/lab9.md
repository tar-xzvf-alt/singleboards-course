# Лабораторная №9. Работа с логическими анализаторами

## Цель работы

Изучить принципы работы логического анализатора, освоить методы использования библиотеки libgpiod2 для управления выводами GPIO, получить практические навыки анализа цифровых сигналов и протоколов с использованием программного обеспечения Sigrok/PulseView.

## Подготовительный материал

### Логический анализатор

При работе с различными электронными устройствами для анализа и понимания процессов на физическом уровне часто требуется использование специализированных измерительных приборов. Самым точным инструментом для анализа цифровых сигналов является осциллограф. Однако в случаях, когда высокая точность измерений не требуется, но необходима декодировка сигнала или длительная запись измерений, эффективным решением становится логический анализатор.

Логический анализатор — это инструмент для отладки цифровых протоколов, анализа временных характеристик и обнаружения аппаратных проблем. Прибор позволяет одновременно отслеживать состояние нескольких цифровых линий (каналов) и записывать изменения сигналов во времени.

В операционной системе ALT Linux доступны пакеты проекта Sigrok:

- [sigrok-cli](https://packages.altlinux.org/en/sisyphus/srpms/sigrok-cli/) — утилита командной строки
- [pulseview](https://packages.altlinux.org/en/sisyphus/srpms/pulseview/) — графический интерфейс

**Sigrok** — программный проект, обеспечивающий поддержку различных анализаторов сигналов. **Pulseview** — графическая оболочка для визуализации и декодирования данных.

### Установка программного обеспечения

Для работы с логическим анализатором необходимо установить следующие пакеты:

```
# apt-get install sigrok-cli sigrok-firmware-fx2lafw pulseview
```

### Пример использования логического анализатора

**GPIO (General Purpose Input/Output)** — выводы общего назначения, которые могут работать как входы или выходы. Они позволяют микроконтроллеру взаимодействовать с внешними устройствами: читать сигналы от датчиков, управлять светодиодами, реле, двигателями и другими периферийными устройствами. Выводы GPIO являются основным интерфейсом для связи одноплатного компьютера с внешним миром.

Типичная задача для логического анализатора — измерение параметров цифрового сигнала на выводе GPIO. Например, на определённом пине гребёнки платы формируется сигнал с длительностью импульса 10 мс.

Для подключения анализатора необходимо соединить:

- Вывод GND анализатора с соответствующим пином земли на плате
- Канал CH1-CH8 с исследуемым пином

Запуск PulseView и выбор устройства:

```
$ pulseview
```

В окне выбора устройства выбрать анализатор fx2lafw и нажать Start. Результатом является график изменения сигналов по каналам, позволяющий измерить временные параметры импульсов — длительность высокого и низкого уровня, период и частоту сигнала.

### Анализ протокола UART

Практическое применение логического анализатора — анализ работы последовательного интерфейса UART. На плате Lichee RV Dock при загрузке в UART-консоль выводится диагностическая информация.

Подключение анализатора:

- Вывод GND анализатора — к пину GND платы
- Канал CH0 — к пину TX платы

Настройка PulseView для анализа UART:

1. Удалить лишние каналы, оставить первый
2. Установить частоту дискретизации 1 MHz
3. Добавить декодер протокола: кнопка "Add protocol decoder" → UART

Параметры декодирования UART:

```
Baud rate: 115200
Data bits: 8
Parity: 0
Stop bits: 1
Bit order: lsb-first
Data format: ascii
Invert RX: no
Invert TX: no
Sample point (%): 50
```

Применение настроек позволяет декодировать передаваемые данные и отобразить их в виде символов ASCII.

![Показания анализатора](../pictures/UART_output.png)

### Библиотека libgpiod2

Библиотека libgpiod2 предоставляет удобный интерфейс для управления выводами общего назначения (GPIO) из пользовательского пространства операционной системы Linux. Библиотека является частью проекта GNU и распространяется под лицензией LGPL-2.1+.

#### Основные концепции

**gpiochip** — символьное устройство, представляющее один или несколько выводов GPIO. В системе может быть несколько gpiochip-устройств, каждое из которых имеет уникальное имя и диапазон номеров линий.

**Линия GPIO** — отдельный вывод, который может быть настроен как вход или выход. Каждая линия идентифицируется номером в пределах gpiochip.

**Потребитель (consumer)** — имя процесса, использующего линию GPIO. Используется для идентификации владельца в системе.

#### API библиотеки libgpiod2

Основные структуры и функции:

```c
#include <gpiod.h>

// Открытие gpiochip
struct gpiod_chip *gpiod_chip_open(const char *path);

// Создание настроек для линии
struct gpiod_line_settings *gpiod_line_settings_new();

// Установка направления линии (вход/выход)
void gpiod_line_settings_set_direction(struct gpiod_line_settings *settings,
                                        enum gpiod_line_direction direction);
// GPIOD_LINE_DIRECTION_INPUT или GPIOD_LINE_DIRECTION_OUTPUT

// Установка начального значения для выхода
void gpiod_line_settings_set_output_value(struct gpiod_line_settings *settings, int value);

// Освобождение настроек линии
void gpiod_line_settings_free(struct gpiod_line_settings *settings);

// Создание конфигурации для нескольких линий
struct gpiod_line_config *gpiod_line_config_new();

// Добавление настроек для конкретных линий
int gpiod_line_config_add_line_settings(struct gpiod_line_config *config,
                                         const unsigned int *offsets,
                                         size_t num_offsets,
                                         struct gpiod_line_settings *settings);

// Освобождение конфигурации линий
void gpiod_line_config_free(struct gpiod_line_config *config);

// Создание конфигурации запроса
struct gpiod_request_config *gpiod_request_config_new();

// Установка имени потребителя (процесса)
void gpiod_request_config_set_consumer(struct gpiod_request_config *config,
                                        const char *consumer);

// Освобождение конфигурации запроса
void gpiod_request_config_free(struct gpiod_request_config *config);

// Запрос линий у чипа
struct gpiod_line_request *gpiod_chip_request_lines(struct gpiod_chip *chip,
                                                      struct gpiod_request_config *req_config,
                                                      struct gpiod_line_config *line_config);

// Установка значения на выводе
int gpiod_line_request_set_value(struct gpiod_line_request *request,
                                  unsigned int offset, int value);

// Освобождение запроса линий
void gpiod_line_request_release(struct gpiod_line_request *request);

// Закрытие чипа
void gpiod_chip_close(struct gpiod_chip *chip);
```

#### Пример использования (генератор меандра)

Простой пример генерации меандра на выводе GPIO:

```c
#include <gpiod.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>

#define GPIO_CHIP    "/dev/gpiochip0"
#define GPIO_OFFSET  144  // Line 144 - PE16

static volatile int keep_running = 1;

static void signal_handler(int signum)
{
    (void)signum;
    keep_running = 0;
}

int main() {
    struct gpiod_chip *chip;
    struct gpiod_line_request *req;
    struct gpiod_line_settings *settings;
    struct gpiod_line_config *line_cfg;
    struct gpiod_request_config *req_cfg;
    unsigned int offset = GPIO_OFFSET;

    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    chip = gpiod_chip_open(GPIO_CHIP);
    if (!chip) {
        perror("gpiod_chip_open");
        return 1;
    }

    settings = gpiod_line_settings_new();
    gpiod_line_settings_set_direction(settings, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(settings, 0);

    line_cfg = gpiod_line_config_new();
    gpiod_line_config_add_line_settings(line_cfg, &offset, 1, settings);

    req_cfg = gpiod_request_config_new();
    gpiod_request_config_set_consumer(req_cfg, "wavegen");

    req = gpiod_chip_request_lines(chip, req_cfg, line_cfg);
    if (!req) {
        perror("gpiod_chip_request_lines");
        gpiod_chip_close(chip);
        return 1;
    }

    printf("Generating square wave on GPIO line %u (press Ctrl+C to stop)\n", GPIO_OFFSET);

    while (keep_running) {

    // Генерация меандра должна быть здесь

    }

    printf("\nCleaning up...\n");

    gpiod_line_request_release(req);
    gpiod_chip_close(chip);
    gpiod_line_settings_free(settings);
    gpiod_line_config_free(line_cfg);
    gpiod_request_config_free(req_cfg);

    printf("Done\n");
    return 0;
}
```

#### Установка библиотеки

В ALT Linux библиотека доступна в пакете:

```
# apt-get install libgpiod2 libgpiod-devel
```

Пакет `libgpiod-devel` содержит заголовочные файлы для компиляции приложений.

#### Компиляция программы

Компиляция с использованием libgpiod2:

```
$ gcc blink.c -o blink -lgpiod
```

#### Получение информации о доступных выводах

Просмотр информация о gpiochip и линиях:

```
$ gpioinfo                   # вся информация о GPIO 
$ gpioget -c 0 144           # состояние линии 144 на чипе 0
$ gpioset gpiochip0 144=1    # установить состояние линии 144 на чипе 0 в "1"
$ gpiomon -c 0 144           # остледить прерывания на линии 144 на чипе 0
```

### Задача. Генератор меандра на GPIO

Необходимо, пользуясь примером приведенным ранее создать генератор, реализованный как консольное приложение на языке Си с использованием библиотеки libgpiod2. Параметры длительности должны передаваться через аргументы командной строки в микросекундах. Генерация сигнала должна происходить в непрерывном режиме до получения сигнала прерывания (Ctrl+C), после чего ресурсы (линия GPIO) корректно освобождаются.

Вывод GPIO для генерации — PE16 (линия 144 на gpiochip0).

Пример запуска генератора с периодом 500 мкс (250 мкс высокий уровень, 250 мкс низкий уровень):

```
$ ./generator 250 250
```

#### Анализ работы генератора


Для анализа характеристик сигнала используется логический анализатор в связке с программой PulseView:

1. Подключить канал CH0 анализатора к выводу GPIO с генератором
2. Запустить генератор
3. Запустить захват сигнала в PulseView
4. Измерить параметры сигнала: длительность импульсов высокого и низкого уровня, частоту


## Контрольные вопросы

1. Для чего нужен логический анализатор при отладке цифровых сигналов?
2. Какие параметры необходимо настроить в PulseView для декодирования UART-сигнала?
3. Что такое GPIO-линия в терминах libgpiod2 и как к ней обратиться из программы?
4. Чем управление GPIO через libgpiod2 принципиально отличается от прямой записи в регистры микроконтроллера (как в Arduino)?

## Задание

Ознакомившись с подготовительным материалом решить следующие подзадачи:

### Работа с логическим анализатором

- Установить пакеты sigrok-cli и pulseview
- Подключить логический анализатор к персональному компьютеру
- Запустить pulseview и убедиться в обнаружении анализатора
- Выполнить измерение параметров тестового сигнала (импульс 10 мс)
- Провести анализ вывода данных в UART-консоль одноплатника, подключив анализатор к пину TX

### Работа с libgpiod2

- Установить пакет libgpiod-devel
- Изучить распиновку вывода PE16 на плате Lichee RV Dock
- Собрать пример генератора на основе примера из подготовительного материала
- Запустить генератор и проверить его работу

### Создание генератора меандра

- Разработать консольное приложение генератора меандра с использованием libgpiod2
- Обеспечить приём параметров длительности через аргументы командной строки
- Реализовать корректное освобождение ресурсов при прерывании (Ctrl+C)
- Собрать и запустить генератор на выводе PE16

### Анализ работы генератора

- Подключить логический анализатор к выводу GPIO с генератором
- Выполнить захват сигнала в pulseview
- Измерить длительность импульсов высокого и низкого уровня
- Сохранить результаты измерений в файл

### Демонстрация и отчёт

- Ответить на контрольные вопросы (письменно, в отчёте)
- **Продемонстрировать работу преподавателю**
- Сформировать отчёт о выполнении поставленных задач .doc и **выслать на почту преподавателя до обозначенного срока**