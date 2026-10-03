#define _POSIX_C_SOURCE 200809L
#include "led_io.h"

int main(int argc, char **argv)
{
    char found[PATH_MAX], index[128], values[128], brightness[32];
    unsigned int maximum;
    if (argc > 2) {
        fprintf(stderr, "Использование: %s [каталог_RGB_LED]\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (argc == 1 && led_find("/sys/class/leds/rgb:status*", found, sizeof(found)) < 0)
        return EXIT_FAILURE;
    const char *dir = argc == 2 ? argv[1] : found;
    if (led_max(dir, &maximum) < 0 ||
        led_read(dir, "multi_index", index, sizeof(index)) < 0)
        return EXIT_FAILURE;

    int colors[3], count = 0, mask = 0;
    for (char *p = strtok(index, " \t\r\n"); p; p = strtok(NULL, " \t\r\n")) {
        int color = strcmp(p, "red") == 0 ? 0 :
                    strcmp(p, "green") == 0 ? 1 : strcmp(p, "blue") == 0 ? 2 : -1;
        if (count == 3 || color < 0 || (mask & (1 << color))) {
            fprintf(stderr, "Ожидались три разные компоненты RGB\n");
            return EXIT_FAILURE;
        }
        colors[count++] = color;
        mask |= 1 << color;
    }
    if (count != 3) {
        fprintf(stderr, "Ожидались три компоненты RGB\n");
        return EXIT_FAILURE;
    }
    if (led_write(dir, "trigger", "none") < 0 ||
        led_write(dir, "brightness", "0") < 0)
        return EXIT_FAILURE;
    /* Невысокая общая яркость для первого осмотра. */
    snprintf(brightness, sizeof(brightness), "%u", maximum / 8 ? maximum / 8 : 1);
    signal(SIGINT, stop_demo);
    signal(SIGTERM, stop_demo);
    const char *names[] = { "красный", "зелёный", "синий", "белый" };
    int result = EXIT_SUCCESS;
    for (int step = 0; step < 4 && !stopped; ++step) {
        unsigned int channels[3];
        for (int i = 0; i < 3; ++i)
            channels[i] = step == 3 || colors[i] == step ? maximum : 0;
        snprintf(values, sizeof(values), "%u %u %u", channels[0], channels[1], channels[2]);
        if (led_write(dir, "multi_intensity", values) < 0 ||
            led_write(dir, "brightness", brightness) < 0) {
            result = EXIT_FAILURE;
            break;
        }
        printf("%s: %s\n", names[step], values);
        pause_demo();
    }
    if (led_write(dir, "brightness", "0") < 0)
        result = EXIT_FAILURE;
    return result;
}
