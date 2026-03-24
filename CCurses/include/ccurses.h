#ifndef CCURSES_H
#define CCURSES_H

#include <ncurses.h>
#include <stdbool.h>

void cc_init(void);
void cc_shutdown(void);
void cc_clear(void);
void cc_refresh(void);
void cc_move(int row, int col);
void cc_addch(char ch);
void cc_addstr(const char* str);
int cc_getch(void);
bool cc_has_colors(void);
void cc_start_color(void);
int cc_init_pair(short pair, short fg, short bg);
void cc_attr_on(int attrs);
void cc_attr_off(int attrs);
void cc_color_set(short pair);
void cc_use_default_colors(void);
void cc_mvprintw(int row, int col, const char* fmt, ...);
int cc_cols(void);
int cc_lines(void);
void cc_curs_set(int visibility);
void cc_nodelay(bool on);
void cc_set_blocking(bool blocking);

#endif
