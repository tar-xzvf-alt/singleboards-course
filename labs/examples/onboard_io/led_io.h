/* Общие операции LED class для учебных демонстраций. */
#ifndef LED_IO_H
#define LED_IO_H

#include <errno.h>
#include <glob.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static volatile sig_atomic_t stopped;

static void stop_demo(int sig)
{
    (void)sig;
    stopped = 1;
}

static int led_path(char *path, size_t size, const char *dir, const char *file)
{
    int n = snprintf(path, size, "%s/%s", dir, file);
    if (n < 0 || (size_t)n >= size) {
        fprintf(stderr, "Слишком длинный путь LED\n");
        return -1;
    }
    return 0;
}

static int led_read(const char *dir, const char *file, char *text, size_t size)
{
    char path[PATH_MAX];
    if (led_path(path, sizeof(path), dir, file) < 0)
        return -1;
    FILE *stream = fopen(path, "r");
    if (!stream) {
        perror(path);
        return -1;
    }
    int ok = fgets(text, (int)size, stream) != NULL;
    if (!ok)
        fprintf(stderr, "Не удалось прочитать %s\n", path);
    if (fclose(stream) != 0)
        ok = 0;
    return ok ? 0 : -1;
}

static int led_write(const char *dir, const char *file, const char *text)
{
    char path[PATH_MAX];
    if (led_path(path, sizeof(path), dir, file) < 0)
        return -1;
    FILE *stream = fopen(path, "w");
    if (!stream) {
        perror(path);
        return -1;
    }
    int ok = fprintf(stream, "%s\n", text) >= 0;
    if (fclose(stream) != 0)
        ok = 0;
    if (!ok)
        fprintf(stderr, "Не удалось записать %s\n", path);
    return ok ? 0 : -1;
}

static int led_max(const char *dir, unsigned int *value)
{
    char text[64], *end;
    if (led_read(dir, "max_brightness", text, sizeof(text)) < 0)
        return -1;
    errno = 0;
    unsigned long n = strtoul(text, &end, 10);
    if (errno || end == text || strspn(end, " \t\r\n") != strlen(end) ||
        text[0] == '-' || n == 0 || n > UINT_MAX) {
        fprintf(stderr, "Некорректный max_brightness\n");
        return -1;
    }
    *value = (unsigned int)n;
    return 0;
}

static int led_find(const char *pattern, char *dir, size_t size)
{
    glob_t matches = {0};
    int result = glob(pattern, 0, NULL, &matches);
    if (result != 0 || matches.gl_pathc != 1) {
        fprintf(stderr, "LED не найден однозначно; укажите каталог явно\n");
        globfree(&matches);
        return -1;
    }
    int n = snprintf(dir, size, "%s", matches.gl_pathv[0]);
    globfree(&matches);
    return n >= 0 && (size_t)n < size ? 0 : -1;
}

static void pause_demo(void)
{
    struct timespec delay = { .tv_sec = 0, .tv_nsec = 500000000 };
    while (!stopped && nanosleep(&delay, &delay) < 0 && errno == EINTR)
        ;
}

#endif
