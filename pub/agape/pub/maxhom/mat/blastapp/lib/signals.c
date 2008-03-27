#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

extern enum blast_error	blastapp_errno;

void
SigTerm(sig)
	int		sig;
{
	static char	*msg = "terminated prior to completion.";

#ifdef SIGTERM
	signal(SIGTERM, SIG_IGN);
#endif /* SIGTERM */
	if (blastapp_errno == ERR_NONE)
		bfatal(ERR_TERMINATED, msg);
	exit_code(blastapp_errno, msg);
}

static void
alarmproc()
{
	bfatal(ERR_ALARM, "Alarm clock expired");
}


alarmprocset()
{
	AlarmSet(alarm(0), (FnPtr)alarmproc, NULL);
}
