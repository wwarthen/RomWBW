/*

	CPMREDIR: CP/M filesystem redirector
	Optional Open file tracker
	Copyright (C) 2021, Mark Ogden <mark.pm.ogden@btinternet.com>

	This is an addition to the CPMREDIR
	Copyright (C) 1998, John Elliott <jce@seasip.demon.co.uk>

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Library General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Library General Public License for more details.

	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the Free
	Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

#include "cpmint.h"

/* CP/M does not require that files opened for reading need to be closed,
 * this has two impacts
 * 1) a lot of file handles can remain opened even when the file is no
 *    longer used. For modern OS builds this isn't a major problem as
 *    the system limits are quite high. It is however wasteful
 * 2) for windows it can lead to issues when trying to delete / rename a file
 *    as normally windows will not allow files to be deleted/renamed if the
 *    file is currently open. Unix variants don't have this restriction.
 *
 * As an example the build of cgen.com using my decompiled sources
 * the linq phase without tracking left 42 open files
 * with tracking this was reduced to 2
 *
 * This code keeps track of files that are opened until they are explicitly
 * closed or the FCB used to open the file is reused, or the file needs to be
 * renamed or deleted.
 * To do this it keeps track of the expanded filename, fcb location and allocated
 * file handle
 *
 * Two public functions are used to manage the file list, and are called from
 * within the bdos emulation
 *
 * trackFile(char *fname, void *fcb, int fd)
 *	removes existing tracking with matchin fcb or fd and
 *	if (fname != NULL) - add the info to the head of the open files list
 *	it returns fd
 *
 * the function is called in the following circumstances
 * 1) before closing a file (fname is NULL)
 * 2) just after the file has been  opened/created.
 * 3) to remove association with a given fcb trackFile(NULL, fcb, -1)
 *
 * note a helper macro releaseFCB(fcb) can be used for (3) above
 *
 * releaseFile(char *fname)
 *  this scans through the list of open files and for each open file
 *  with a matching fname, the file is closed
 *
 * the function is called before deleting a file or renaming a file
 *
 *
 * there is a helper function that removes the info from the list
 *
 * Notes:
 * For most applications the tracker could in principle automatically
 * close existing open files at the start of a new executable invocation.
 * Unfortunately this does not support the case where there is a scripting
 * engine intercepting the warm reboots, as it may need to keep the script
 * source file open.
 *
 * Note in theory it would be possible for a CP/M program to open a file
 * with a given fcb, move the fcb internally and then open another file
 * with the original fcb. If this happens the FCB tracking could cause
 * a problem. I am not aware of any real programs that do this.
 * Please let me know if the situation arises.
*/

/*
 * The FILETRACKER functionality was implemented primarily because
 * MSDOS file interface does not allow opening files in shared mode.
 * This port of zxcc deprecates MSDOS and uses WIN32 API calls to handle
 * all file I/O.  So, this means that FILETRACKER is now optional for
 * for Windows as well as Unix.  I have found some edge cases where
 * FILETRACKER caused a CP/M program to misbehave.  Specifically, ZSM4
 * reuses FCBs if files are included and does it such a way that the
 * FILETRACKER is unable to solve the problem.  For maximum
 * compatibility, FILETRACKER may now be left off with the implication
 * that a lot of file handles will be left open.
 */

#ifdef FILETRACKER

#include "cpmint.h"

typedef struct _track {
	struct _track* next;
	int handle;
	void* fcb;
	char* fname;
} track_t;

track_t* openFiles;

static track_t* rmHandle(track_t* s) {
	track_t* next = s->next;
	free(s->fname);
	free(s);
	return next;
}

void releaseFile(char* fname) {
	track_t* s = (track_t*)&openFiles;
	DBGMSGV("releaseFile: \"%s\"\n", fname);
	while (s->next)
		if (strcmp(s->next->fname, fname) == 0) {
			DBGMSGV("  closing file #%i: \"%s\"\n", s->next->handle, s->next->fname);
#ifdef _WIN32
			{
				BOOL b;
				b = CloseHandle((HANDLE)s->next->handle);
				if (!b)
					DBGMSGV("  failed to close file #%i (Error=%lu): %s\n", s->next->handle, GetLastError(), GetErrorStr(GetLastError()));
			}
#else
			if (close(s->next->handle))
				DBGMSGV("  failed to close file #%i (errno=%lu): %s\n", s->next->handle, errno, strerror(errno));
#endif
			s->next = rmHandle(s->next);
		}
		else
			s = s->next;
}

int trackFile(char* fname, void* fcb, int fd) {
	track_t* s = (track_t*)&openFiles;
	DBGMSGV("trackFile: \"%s\", FCB=0x%X, Handle=%i\n", fname, (byte*)fcb - RAM, fd);
	while (s->next) {	/* find any existing fcb or fd */
		if (s->next->fcb == fcb || s->next->handle == fd) {
			if (s->next->handle != fd) {
				DBGMSGV("  closing file #%i: \"%s\"\n", s->next->handle, s->next->fname);
#ifdef _WIN32
				{
					BOOL b;
					b = CloseHandle((HANDLE)s->next->handle);
					if (!b)
						DBGMSGV("  failed to close file #%i (Error=%lu): %s\n", s->next->handle, GetLastError(), GetErrorStr(GetLastError()));
				}
#else
				if (close(s->next->handle))
					DBGMSGV("  failed to close file #%i (errno=%lu): %s\n", s->next->handle, errno, strerror(errno));
#endif
			}
			DBGMSGV("  released file \"%s\", Handle=%i\n", s->next->fname, s->next->handle);
			s->next = rmHandle(s->next);	/* release the tracker */
		}
		else
			s = s->next;
	}
	if (fname && fd >= 0) {
		if ((s = malloc(sizeof(track_t))) == NULL) {
			fprintf(stderr, "out of memory\n");
			exit(1);
		}
		s->next = openFiles;
		s->fname = strdup(fname);
		s->fcb = fcb;
		s->handle = fd;
		openFiles = s;
	}
	return fd;
}

#else

void releaseFile(char* fname) {}
int trackFile(char* fname, void* fcb, int fd) { return fd; }

#endif
