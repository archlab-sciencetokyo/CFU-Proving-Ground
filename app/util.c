void pg_exit() {
    *(int *)0x80000000 = 0x00020000;
}

void pg_printc(char c) {
    *(char *)0x80000000 = c;
}

void pg_printd(int x) {
    if (x == 0) {
        pg_printc('0');
        return;
    }
    if (x < 0) {
        pg_printc('-');
        x = -x;
    }
    char buf[16];
    int i = 0;
    while (x) {
        buf[i++] = x % 10 + '0';
        x /= 10;
    }
    while (i--) {
        pg_printc(buf[i]);
    }
}

void pg_printh(int x) {
    char buf[16];
    int i = 0;
    while (x) {
        buf[i++] = "0123456789ABCDEF"[x & 0xF];
        x >>= 4;
    }
    while (i--) {
        pg_printc(buf[i]);
    }
}

void pg_prints(const char *str) {
    while (*str) {
        pg_printc(*str);
        str++;
    }
}
