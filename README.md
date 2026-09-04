# Linux на встраиваемых устройствах

Лабораторный практикум по работе с одноплатными компьютерами на RISC-V, сборке embedded Linux и подключению периферии. Основная целевая плата — Lichee RV Dock на Allwinner D1.

Курс идёт от первого подключения по UART до итогового проекта с Arduino, SPI, I2C, MQTT и GUI-приложением на ПК.

## Содержание

- [Резюме лабораторных работ](labs/summary.md)
- [Методичка PDF](labs_pdf/metodichka.pdf)
- [Контрольные вопросы](labs/control_questions.md)
- [Ответы на контрольные вопросы PDF](labs_pdf/control_questions.pdf)
- [Telegram-посты для анонса курса](tg-posts/)

## Лабораторные работы

- Лабораторная №1. Базовые навыки работы с одноплатным компьютером: [Markdown](labs/lab1.md) · [PDF](labs_pdf/lab1.pdf)
- Лабораторная №2. Работа с платой по SSH: [Markdown](labs/lab2.md) · [PDF](labs_pdf/lab2.pdf)
- Лабораторная №3. Использование кросс-компилятора: [Markdown](labs/lab3.md) · [PDF](labs_pdf/lab3.pdf)
- Лабораторная №4. Создание основных компонентов образа: ядро Linux: [Markdown](labs/lab4.md) · [PDF](labs_pdf/lab4.pdf)
- Лабораторная №5. Дерево устройств, корневая файловая система и загрузчик: [Markdown](labs/lab5.md) · [PDF](labs_pdf/lab5.pdf)
- Лабораторная №6. Подготовка носителя и запись образа: [Markdown](labs/lab6.md) · [PDF](labs_pdf/lab6.pdf)
- Лабораторная №7. Добавление поддержки интерфейса SPI: [Markdown](labs/lab7.md) · [PDF](labs_pdf/lab7.pdf)
- Лабораторная №8. Добавление поддержки интерфейса I2C: [Markdown](labs/lab8.md) · [PDF](labs_pdf/lab8.pdf)
- Лабораторная №9. Работа с логическим анализатором: [Markdown](labs/lab9.md) · [PDF](labs_pdf/lab9.pdf)
- Лабораторная №10. Основы программирования микроконтроллеров Arduino: [Markdown](labs/lab10.md) · [PDF](labs_pdf/lab10.pdf)
- Лабораторная №11. Интеграция Arduino и Lichee RV Dock по SPI с датчиком BME280: [Markdown](labs/lab11.md) · [PDF](labs_pdf/lab11.pdf)
- Лабораторная №12. Протокол MQTT: [Markdown](labs/lab12.md) · [PDF](labs_pdf/lab12.pdf)
- Лабораторная №13. Итоговое проектное задание по вариантам: [Markdown](labs/lab13.md) · [PDF](labs_pdf/lab13.pdf)

## Оборудование

- Lichee RV Dock или совместимая плата на Allwinner D1
- microSD-карта и USB Type-C питание
- USB-UART преобразователь на 3.3 В
- Arduino Uno или совместимая плата на ATmega328P
- Датчик BME280, OLED SSD-1306, логический анализатор fx2lafw/Saleae-compatible
- Провода, макетная плата, преобразователь логических уровней 5 В ↔ 3.3 В

## Сборка методички

PDF собирается из лабораторных работ через Pandoc и XeLaTeX. Порядок лабораторных задаётся импортами в `labs/metodichka.md`, а итоговый файл сохраняется в `labs_pdf/metodichka.pdf`.

Зависимости:

```bash
# apt-get install pandoc texlive-xetex texlive-latex-extra fonts-ttf-dejavu
```

Сборка полной методички:

```bash
$ ./latex/build.sh
```

Если сборка прошла успешно, в конце появится сообщение:

```console
Готово: /path/to/repo/labs_pdf/metodichka.pdf
```

Отдельную лабораторную, комплект всех лабораторных или все PDF можно собрать так:

```bash
./latex/build.sh lab1
./latex/build.sh labs
./latex/build.sh all
```

Команда `./latex/build.sh answers` создаёт отдельный PDF с ответами на контрольные вопросы. Он не включается в студенческие лабораторные и общую методичку.

## Дополнительные материалы

- [Разработка и отладка приложений для RISC-V](Additional/remote_development.md)
- [Материалы employer day](Additional/employer_day.md)
- [Идея MQTT-проекта](Additional/mqtt_idea.md)
- [Идеи по развитию заданий и итоговых проектов](course_ideas/README.md)
- [Реестр дополнительных заданий и статусов проверки](course_ideas/additional_tasks.md)
