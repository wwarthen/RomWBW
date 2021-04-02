/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Target list.
 * ===========================================================================
 */

#include "targets.h"
#include "uz80as.h"

#ifndef STRING_H
#include <string.h>
#endif

extern const struct target s_target_z80;
extern const struct target s_target_hd64180;
extern const struct target s_target_z280;
extern const struct target s_target_gbcpu;
extern const struct target s_target_dp2200;
extern const struct target s_target_dp2200ii;
extern const struct target s_target_i4004;
extern const struct target s_target_i4040;
extern const struct target s_target_i8008;
extern const struct target s_target_i8021;
extern const struct target s_target_i8022;
extern const struct target s_target_i8041;
extern const struct target s_target_i8048;
extern const struct target s_target_i8051;
extern const struct target s_target_i8080;
extern const struct target s_target_i8085;
extern const struct target s_target_mos6502;
extern const struct target s_target_r6501;
extern const struct target s_target_g65sc02;
extern const struct target s_target_r65c02;
extern const struct target s_target_r65c29;
extern const struct target s_target_w65c02s;
extern const struct target s_target_mc6800;
extern const struct target s_target_mc6801;
extern const struct target s_target_m68hc11;

static const struct target *s_targets[] = {
	&s_target_z80,
	&s_target_hd64180,
	&s_target_z280,
	&s_target_gbcpu,
	&s_target_dp2200,
	&s_target_dp2200ii,
	&s_target_i4004,
	&s_target_i4040,
	&s_target_i8008,
	&s_target_i8021,
	&s_target_i8022,
	&s_target_i8041,
	&s_target_i8048,
	&s_target_i8051,
	&s_target_i8080,
	&s_target_i8085,
	&s_target_mos6502,
	&s_target_r6501,
	&s_target_g65sc02,
	&s_target_r65c02,
	&s_target_r65c29,
	&s_target_w65c02s,
	&s_target_mc6800,
	&s_target_mc6801,
	&s_target_m68hc11,
	NULL,
};

static int s_index;

const struct target *find_target(const char *id)
{
	const struct target **p;

	for (p = s_targets; *p != NULL; p++) {
		if (strcmp(id, (*p)->id) == 0) {
			return *p;
		}
	}

	return NULL;
}

const struct target *first_target(void)
{
	s_index = 0;
	return next_target();
}

const struct target *next_target(void)
{
	if (s_targets[s_index] != NULL) {
		return s_targets[s_index++];
	} else {
		return NULL;
	}
}
