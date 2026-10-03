#define _POSIX_C_SOURCE 200809L
#include "led_io.h"

int main(int argc, char **argv)
{
    char found[PATH_MAX], brightness[32];
    unsigned int maximum;
    if (argc > 2) {
        fprintf(stderr, "Использование: %s [каталог_LED]\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (argc == 1 && led_find("/sys/class/leds/green:status*", found, sizeof(found)) < 0)
        return EXIT_FAILURE;
    const char *dir = argc == 2 ? argv[1] : found;
    if (led_max(dir, &maximum) < 0 || led_write(dir, "trigger", "none") < 0)
        return EXIT_FAILURE;
    snprintf(brightness, sizeof(brightness), "%u", maximum);
    signal(SIGINT, stop_demo);
    signal(SIGTERM, stop_demo);
    printf("LED: %s; 10 миганий с периодом 1 с\n", dir);
    int result = EXIT_SUCCESS;
    for (int i = 0; i < 10 && !stopped; ++i) {
        if (led_write(dir, "brightness", brightness) < 0) {
            result = EXIT_FAILURE;
            break;
        }
        pause_demo();
        if (led_write(dir, "brightness", "0") < 0) {
            result = EXIT_FAILURE;
            break;
        }
        pause_demo();
    }
    if (led_write(dir, "brightness", "0") < 0)
        result = EXIT_FAILURE;
    return result;
}
