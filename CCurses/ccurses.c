#include "ccurses.h"
#include <curses.h>
#include <stdarg.h>
#include <unistd.h>

void cc_init(void) {
    initscr();
    raw();
    noecho();
    keypad(stdscr, TRUE);
    curs_set(0);
    nodelay(stdscr, TRUE);
    timeout(100);
}

void cc_shutdown(void) {
    endwin();
}

void cc_clear(void) {
    erase();
}

void cc_refresh(void) {
    refresh();
}

void cc_move(int row, int col) {
    move(row, col);
}

void cc_addch(char ch) {
    addch(ch);
}

void cc_addstr(const char* str) {
    addstr(str);
}

int cc_getch(void) {
    int c = wgetch(stdscr);
    if (c == ERR) return -1;
    if (c == KEY_UP) return 259;
    if (c == KEY_DOWN) return 258;
    if (c == KEY_LEFT) return 260;
    if (c == KEY_RIGHT) return 261;
    return c;
}

void cc_set_blocking(bool blocking) {
    nodelay(stdscr, !blocking);
}

bool cc_has_colors(void) {
    return has_colors();
}

void cc_start_color(void) {
    start_color();
}

int cc_init_pair(short pair, short fg, short bg) {
    return init_pair(pair, fg, bg);
}

void cc_attr_on(int attrs) {
    attron(attrs);
}

void cc_attr_off(int attrs) {
    attroff(attrs);
}

void cc_color_set(short pair) {
    attron(COLOR_PAIR(pair));
}

void cc_use_default_colors(void) {
    use_default_colors();
}

void cc_mvprintw(int row, int col, const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    move(row, col);
    vwprintw(stdscr, fmt, args);
    va_end(args);
}

int cc_cols(void) {
    return COLS;
}

int cc_lines(void) {
    return LINES;
}

void cc_curs_set(int visibility) {
    curs_set(visibility);
}

void cc_nodelay(bool on) {
    nodelay(stdscr, on);
}
