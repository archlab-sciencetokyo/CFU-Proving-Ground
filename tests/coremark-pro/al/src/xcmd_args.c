#include "th_lib.h"

#ifndef XCMD_STRING
#define XCMD_STRING ""
#endif

#define MAX_ARGS 16

static char xcmd_buffer[256];
static char *argv_storage[MAX_ARGS + 1];

static char prog_name[] = "coremark-pro";

/* Declaration of renamed workload main */
int workload_main(int argc, char *argv[]);

/*
 * Parse the XCMD string into argc/argv format and call workload_main
 */
#undef main
int main(int argc, char *argv[]) {
    char *src = XCMD_STRING;
    char *dst;
    int in_arg = 0;
    int new_argc = 1;

    (void)argc;
    (void)argv;

    argv_storage[0] = prog_name;

    th_strncpy(xcmd_buffer, src, sizeof(xcmd_buffer) - 1);
    xcmd_buffer[sizeof(xcmd_buffer) - 1] = '\0';

    for (dst = xcmd_buffer; *dst && new_argc < MAX_ARGS; dst++) {
        if (*dst == ' ' || *dst == '\t') {
            *dst = '\0';
            in_arg = 0;
        } else if (!in_arg) {
            argv_storage[new_argc++] = dst;
            in_arg = 1;
        }
    }

    argv_storage[new_argc] = NULL;

    return workload_main(new_argc, argv_storage);
}
