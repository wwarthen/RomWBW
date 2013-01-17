/* Copyright (C) 1984 by Manx Software Systems */

struct stat {
	char st_attr;
	long st_mtime;
	long st_size;
};

/* settings of the st_attr field */
#define ST_RDONLY	0x01	/* read only file */
#define ST_HIDDEN	0x02	/* hidden file */
#define ST_SYSTEM	0x04	/* system file */
#define ST_VLABEL	0x08	/* volume label */
#define ST_DIRECT	0x10	/* file is a sub-directory */
#define ST_ARCHIV	0x20	/* set when file has been written and closed */

/* the format of the st_mtime field is:
	<   year    > < month> <  day  >  < hours > <  minutes > < sec/2 >
	3 3 2 2 2 2 2 2  2 2 2 2 1 1 1 1  1 1 1 1 1 1 0 0  0 0 0 0 0 0 0 0
	1 0 9 8 7 6 5 4  3 2 1 0 9 8 7 6  5 4 3 2 1 0 9 8  7 6 5 4 3 2 1 0

where:
	year is from 0-119 for 1980-2099
	month is 1-12
	day is 1-31
	hours is 0-23
	minutes is 0-59
	sec/2 is 0-29
*/
