#ifndef SCREEN_H
#define SCREEN_H

#include "stdint.h"

#define MODE_INFO_BLOCK 0x5000
#define WIDTH 1920
#define HEIGHT 1080
#define BG_COLOR 0xff010b17
#define FG_COLOR 0xffebddf4

struct cursor_s {
    uint32_t x;
    uint32_t y;
};

char* font;
uint32_t* vidmem;
uint16_t bytesPerScanline;

struct cursor_s cursor = { 0, 0 };

void setupScreen() {
    vidmem = *(uint32_t**)(MODE_INFO_BLOCK + 40); // Vidmem pointer location
    bytesPerScanline = *(uint16_t*)(MODE_INFO_BLOCK + 16); // Bytes per scanline location
}

void putcAt(char c, uint32_t x, uint32_t y) {
    uint32_t offset = WIDTH * y * 16 + x * 8;

    char* bitmap = &font[(c-1) * 16];
    for (uint8_t i = 0; i < 16; i++) { // Rows
        char bitmapRow = bitmap[i];
        for (uint8_t j = 0; j < 8; j++) { // Cols
            vidmem[offset + j] = (bitmapRow & 0x80) ? FG_COLOR : BG_COLOR;
            bitmapRow = bitmapRow << 1;
        }
        offset += WIDTH;
    }
}

void printAt(const char* str, uint32_t x, uint32_t y) {
    while (*str != '\0') {
        putcAt(*str++, x, y);
        x++;
    }
}

void putc(char c) {
    if (c == '\n') {
        putcAt(' ', cursor.x, cursor.y); // Make sure we don't leave an extra cursor
        cursor.y++;
        cursor.x = 0;
    } else if (c == '\b') {
        putcAt(' ', cursor.x, cursor.y); // Make sure we don't leave an extra cursor TODO: make this better
        cursor.x--;
        putcAt(' ', cursor.x, cursor.y);
    } else {
        putcAt(c, cursor.x, cursor.y);
        cursor.x++;
    }
}

void print(const char* str) {
    while (*str != '\0') {
        putc(*str++);
    }
}

void clear() {
    size_t i = 0;
    while (i < WIDTH*HEIGHT) {
        vidmem[i] = BG_COLOR; // #1f2937
        i++;
    }

    cursor.x = 0;
    cursor.y = 0;
}

void loadFont(char* address) {
    font = address;
}

#endif
