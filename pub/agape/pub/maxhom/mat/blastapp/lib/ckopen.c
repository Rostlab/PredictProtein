#include <ncbi.h>
#include <sys/stat.h>
#include "blastapp.h"

#ifndef S_ISREG
#define S_ISREG(f)	((f)&S_IFREG)
#endif

static FILE *_ckopen PROTO((char *name, char *mode, int die));


/* ckopen - open file; check for success */
FILE *
ckopen(name, mode, die)
	char	*name, *mode;
	int		die;
{
	FILE *fp, *fdopen();

	if (mode == NULL)
		if (die)
			bfatal(ERR_FOPEN, "NULL mode argument to ckopen()");
		else
			return NULL;

	if (strcmp(name, "-") == 0) {
		if (*mode == 'r')
			fp = fdopen(0, mode);
		else
			fp = fdopen(1, mode);
		if (fp == NULL && die)
			bfatal(ERR_FOPEN, "Can not open standard %s.",
				(*mode == 'r' ? "input" : "output") );
	}
	else
		fp = _ckopen(name, mode, die);
	if (fp == NULL && die) {
		CharPtr	modestr;

		switch (*mode) {
		case 'r':
			modestr = "read";
			break;
		case 'w':
			modestr = "writ";
			break;
		case 'a':
			modestr = "append";
			break;
		}
		bfatal(ERR_FOPEN, "Could not open file for %sing:  %s", modestr, name);
	}

	return fp;
}

static FILE *
_ckopen(name, mode, die)
	char	*name, *mode;
	int		die; /* print error message and die if non-zero */
{
	struct stat	sbuf;

	switch (*mode) {
	case 'r':
		if (stat(name, &sbuf) == -1) {
			if (die)
				bfatal(ERR_FOPEN, "Can not find file:  %s", name);
			return NULL;
		}
		if (!S_ISREG(sbuf.st_mode)) {
			if (die)
				bfatal(ERR_FOPEN, "Not a regular file:  %s", name);
			return NULL;
		}
		break;
	case 'a':
	case 'w':
		if (stat(name, &sbuf) != -1 && !S_ISREG(sbuf.st_mode)) {
			if (die)
				bfatal(ERR_FOPEN, "Not a regular file:  %s", name);
			return NULL;
		}
		break;
	default:
		if (die)
			bfatal(ERR_FOPEN, "Invalid open mode specified in ckopen():  \"%s\"", mode);
		return NULL;
	}
#ifdef OS_VMS
	if (*mode == 'w' || *mode == 'a')
		return fopen(name, mode, "ctx=stm");
	return fopen(name, mode); /* is this correct when opening R/O ? */
#else
	return fopen(name, mode);
#endif
}
