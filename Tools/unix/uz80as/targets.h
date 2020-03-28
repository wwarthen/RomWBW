/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Target list.
 * ===========================================================================
 */

#ifndef TARGETS_H
#define TARGETS_H

struct target;

const struct target *find_target(const char *id);

const struct target *first_target(void);
const struct target *next_target(void);

#endif
