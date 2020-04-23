/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Assembly listing generation.
 * ===========================================================================
 */

#ifndef LIST_H
#define LIST_H

extern int s_codes;
extern int s_list_on;

void list_open(const char *fname);
void list_close(void);
void list_startln(const char *line, int linenum, int pc, int nested_files);
void list_setpc(int pc);
void list_skip(int on);
void list_eject(void);
void list_genb(int b);
void list_endln(void);

#endif
