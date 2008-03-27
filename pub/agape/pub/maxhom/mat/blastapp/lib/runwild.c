#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#define PERIOD	60

static AlarmBlkPtr	abp;
static time_t	lasttick;
static int	lineticks, goodticks;
static unsigned long	incr;
static TaskBlkPtr	tp;


static void
tickproc(userp)
	Nlm_VoidPtr	userp;
{
	BlastIoPtr	biop = &b_out;
	FILE	*fp;

	mproc_lock();
	time(&lasttick);
	++goodticks;

	fp = biop->fp;

	if (fp != NULL) {
		++lineticks;
		putc('.', fp);
		if (lineticks >= 60) {
			lineticks = 0;
			putc('\n', fp);
			putc(' ', fp);
			putc(' ', fp);
			putc(' ', fp);
			putc(' ', fp);
		}
		fflush(fp);
	}

	if (biop->aip != NULL) {
		Bio_JobProgressAsnWrite(biop, goodticks * incr, TaskPosSum(tp));
	}
	mproc_unlock();
}

static void
waitproc(userp)
	Nlm_VoidPtr	userp;
{
	BlastIoPtr	biop = &b_out;
	time_t	now, next;
	double	since;
	FILE	*fp;

	mproc_lock();
	time(&now);
/* RS changed; because SunOs 4.x doesn't have difftime */
/*	since = difftime(now, lasttick); */
	since = lasttick - now ;
	if (since >= (double)PERIOD) {
		fp = biop->fp;
		if (fp != NULL) {
			++lineticks;
			putc('*', fp);
			if (lineticks >= 60) {
				lineticks = 0;
				putc('\n', fp);
				putc(' ', fp);
				putc(' ', fp);
				putc(' ', fp);
				putc(' ', fp);
			}
			fflush(fp);
		}

		if (biop->aip != NULL) {
			Bio_JobProgressAsnWrite(biop, goodticks * incr, TaskPosSum(tp));
		}
	}
	else {
		AlarmReset(abp, MAX(10, PERIOD - since));
	}
	mproc_unlock();
}

void
job_start(jobid, desc, size)
	int		jobid;
	CharPtr	desc;
	unsigned long	size;
{
	goodticks = lineticks = 0;

	incr = MAX(1, size / NTICKS);

	if (b_out.fp != NULL) {
		fprintf(b_out.fp, "%s", desc);
		fflush(b_out.fp);
	}
	Bio_JobStartAsnWrite(&b_out, jobid, desc, size);

	abp = AlarmEvery(PERIOD, (FnPtr)waitproc, NULL);
}


void
job_done(done, pos)
	unsigned long	done;
	unsigned long	pos;
{
	AlarmClr(abp);
	if (b_out.fp != NULL) {
		fprintf(b_out.fp, "done\n");
		fflush(b_out.fp);
	}
	Bio_JobDoneAsnWrite(&b_out, done, pos);
}


void
RunWild(jobid, desc, n, func)
	int		jobid;
	char	*desc; /* Human readable name for the task to perform */
	unsigned long	n; /* Number of discrete subtasks */
	void	(*func) PROTO((void));
{
	job_start(jobid, desc, n);

#ifdef MPROC_AVAIL
#define run_wild mrun_wild
#endif
	tp = run_wild(n, func, NULL, &tp, tickproc, NTICKS, numprocs, &nprocs, SigTerm);
	if (tp != NULL && tp->proc_max == 0 && n > 0)
		bfatal(ERR_MPFORK, "Could not fork for multiprocessing; Is your OS current?");

	numprocs = tp->proc_max;

	job_done(n, TaskPosSum(tp));
	TaskDestruct(tp);
}
