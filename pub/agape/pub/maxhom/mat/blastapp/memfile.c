#define EXTERN
#include <ncbi.h>

#ifndef SYSV_IPC_AVAIL
main()
{
	fprintf(stderr,
"Shared memory, semaphores, and message queues are unavailable on this computer\n");
	exit(1);
}
#else /* SYSV_IPC_AVAIL */

#include <gishlib.h>
#include "blastapp.h"
#ifdef VAR_ARGS
#include <varargs.h>
#else
#include <stdarg.h>
#endif

#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <pwd.h>
#include <grp.h>
#include <sys/file.h>
#include <sys/termio.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/msg.h>

#define FILES_MAX	256

char	*module;

char	*filename;
Boolean	verbose;	/* be verbose about the files being read into memory */
Boolean	lockfile;	/* lock data pages in real memory */
Boolean	daemonize;	/* fork and detach from controlling tty */
Boolean	hangup; /* hangup after creating shared memory */
Boolean	output;	/* output a report of the command line to recreate objects */

void	sighup PROTO((int sig));

int		argc;
char	**argv;
int		mmode,	/* permissions for shared memory segments */
		smode,	/* permissions for semaphores */
		qmode;	/* permissions for message queues */
shm_dat	PNTR shmdp; /* the shared memory segment identifier for our file */
int sig = 0;
Boolean	bg;		/* TRUE ==> running in background */
Boolean hexnames; /* TRUE ==> use hexadecimal ID's rather than filenames */
Boolean	uid_flag, gid_flag;
Boolean	quiet = FALSE;
int		uid, gid;
int		retcode = 0; /* return code */
char	opcode;
key_t	filetokey PROTO((CharPtr filename));

main(ac, av)
	int		ac;
	char	**av;
{
	struct passwd	*pwp;
	struct group	*grp;
	int		oldmask;
	int		i, c, childpid, argno;
	CharPtr	cp;
	Boolean	errflg = FALSE;

	/* Establish default permissions */
	oldmask = umask(0);
	umask(oldmask);
	mmode = qmode = smode = BITMASK(9)^oldmask;

	module = str_dup(basename(av[0], NULL));

	argc = ac;
	argv = av;

	while ((c = getopt(ac, av, "hxvldoutm:q:s:p:C:U:G:Q")) != -1)
		switch (c) {
			case 'u':
				if (opcode)
					usage();
				opcode = c;
				/*
				Request files be updated in memory (assuming they have
				been loaded into memory by another memfile process).
				This is accomplished by sending a "hangup" message to each
				message queue being waited on by the memfile processes
				that are managing shared memory segments.
				*/
				sig = SIGHUP;
				break;
			case 't':
				if (opcode)
					usage();
				opcode = c;
				/*
				Request files be removed from memory (assuming they have
				been loaded into memory by an existing memfile process).
				This is accomplished by sending "terminate" messages to each
				message queue being waited on by the memfile processes
				that are managing shared memory segments.
				*/
				sig = SIGTERM;
				break;
			case 'o': /* output the command line necessary to recreate objects */
				if (opcode)
					usage();
				opcode = c;
				break;
			case 'v':
				verbose = TRUE;
				break;
			case 'l':
				/* Lock data pages in memory.  This option only works
				when invoked by root.
				*/
				lockfile = TRUE;
				break;
			case 'h':
				hangup = TRUE;
				break;
			case 'd':
				daemonize = TRUE;
				break;
			case 'm': /* permissions on the shared memory segment */
				mmode = getperms(optarg, mmode);
				break;
			case 's': /* permissions on the semaphore */
				smode = getperms(optarg, smode);
				break;
			case 'q': /* permissions on the message queue */
				qmode = getperms(optarg, qmode);
				break;
			case 'p': /* permissions for all:  memory, semaphores, and queues */
				smode = getperms(optarg, smode);
				qmode = getperms(optarg, qmode);
				mmode = getperms(optarg, mmode);
				break;
			case 'x':
				hexnames = TRUE;
				break;
			case 'C':
				if (chdir(optarg) == -1) {
					perror(optarg);
					exit(errno);
				}
				break;
			case 'U': /* set userid */
				uid_flag = TRUE;
				/* if all digits, convert to binary integer uid */
				for (cp = optarg; *cp != NULLB; ++cp)
					if (!isdigit(*cp))
						break;
				if (*cp == NULLB && sscanf(optarg, "%d", &uid) == 1)
					break;
				pwp = getpwnam(optarg);
				if (pwp == NULL) {
					fprintf(stderr, "User unknown:  %s", optarg);
					exit(1);
				}
				uid = pwp->pw_uid;
				if (!gid_flag)
					gid = pwp->pw_gid;
				gid_flag = TRUE;
				break;
			case 'G': /* set groupid */
				gid_flag = TRUE;
				/* if all digits, convert to binary integer gid */
				for (cp = optarg; *cp != NULLB; ++cp)
					if (!isdigit(*cp))
						break;
				if (*cp == NULLB && sscanf(optarg, "%d", &gid) == 1)
					break;
				grp = getgrnam(optarg);
				if (grp == NULL) {
					fprintf(stderr, "Group unknown:  %s", optarg);
					exit(1);
				}
				gid = grp->gr_gid;
				break;
			case 'Q':
				quiet = TRUE;
				close(2);
				open("/dev/null", O_WRONLY);
				break;
			case '?':
				errflg=TRUE;
		}

	if (errflg || ac == optind)
		usage();

	switch (opcode) {
	case 'u':
	case 't':
		dosignal(sig);
	case 'o':
		c = 0;
		for (i = optind; i < ac; ++i)
			c |= report_options(av[i]);
		if (c != 0)
			exit(1);
		exit(0);
	default:
		break;
	}

	if (uid_flag && uid != getuid() && getuid() != 0) {
		fprintf(stderr, "Permission denied.\n");
		exit(1);
	}
	if (gid_flag && gid != getgid() && getuid() != 0) {
		fprintf(stderr, "Permission denied.\n");
		exit(1);
	}

	bg = (signal(SIGINT, SIG_IGN) == SIG_IGN);

	for (i=argno=optind; ++i < ac; ) {
		if ((childpid = fork()) == 0) {
			argno = i;
			break;
		}
	}

	if (gid_flag)
		setegid(gid);
	if (uid_flag)
		seteuid(uid);

	filename = av[argno];
	if (argno != optind)
		av[optind] = filename;
	for (; ++optind < ac;)
		av[optind] = "";

	if (verbose)
		(void) printf("%s: loading file \"%s\"\n", module, filename);
	if ((shmdp = shm_loadfile(filename, mmode, smode, qmode, lockfile, TRUE)) == NULL) {
		retcode = 2;
		SigTerm(0);
	}

	if (daemonize || !bg)
		signal(SIGINT, SigTerm);
	signal(SIGHUP, sighup);
	signal(SIGQUIT, SigTerm);
	signal(SIGTERM, SigTerm);

	if (lockfile && geteuid() != 0)
		(void) fprintf(stderr,
				"%s:  could not lock data in memory\n", module);

	if (daemonize) {
		childpid = fork();
		if (childpid < 0) {
			perror(module);
			exit(1);
		}
		/* parent goes away */
		if (childpid > 0)
			exit(0);

		{
			/*
			if your system doesn't have sysconf() or getdtablesize(),
			use nfds = 20
			*/
			int		i, nfds = sysconf(_SC_OPEN_MAX);
			for (i = 0; i < nfds; ++i)
				close(i);
		}

		/* Dissociate from controlling tty */
#ifndef OS_UNIX_BSD
		setpgrp();
#else
		setpgrp(0, 0);
#endif

		if ((i = open("/dev/tty", O_RDWR)) >= 0) {
			ioctl(i, TIOCNOTTY, (char *)NULL);
			close(i);
		}
	}

	if (!hangup) /* wait forever (or until killed) */
		for (;;) {
			sig = shm_waitmsg(shmdp);
			switch (sig) {
			case SIGHUP:
				sighup(0);
				break;
			case SIGTERM:
				SigTerm(0);
				break;
			default:
				break;
			}
		}
		/*NOTREACHED*/

	/* We won't be listening on this queue */
	msgctl(shmdp->msqid, IPC_RMID, NULL);
	exit(0);
}


void
sighup(sig)
	int	sig;
{
	/* For old, non-BSD UNIX systems... */
	signal(SIGHUP, SIG_IGN);

	shm_dropfile(shmdp);
	if ((shmdp = shm_loadfile(filename, mmode, smode, qmode, lockfile, TRUE)) == NULL) {
		retcode = 1;
		SigTerm(0);
	}

	signal(SIGHUP, sighup);
}

void
SigTerm(sig)
	int	sig;
{
	shm_dropfile(shmdp);
	exit(retcode);
}


dosignal(sig)
	int	sig;
{
	int		i, rc = 0;
	key_t	key;
	char	*cp;

	for (i=optind; i<argc; ++i) {
		if (!hexnames) {
			if (shm_sendto(argv[i], sig) != 0) {
				if (errno == ENOENT) {
				}
				perror(argv[i]);
				rc = 1;
			}
		}
		else {
			key = filetokey(argv[i]);
			if (key == -1) {
				rc = 1;
				continue;
			}
			if (shm_sendtokey(key, sig) != 0) {
				if (errno == ENOENT) {
					if (sig == SIGTERM) {
					}
				}
				perror(argv[i]);
				rc = 1;
			}
		}
	}
	exit(rc);
}


#define USER	4
#define GROUP	2
#define OTHER	1
#define READ	4
#define WRITE	2
#define USHIFT	6
#define GSHIFT	3
#define OSHIFT	0

int
getperms(arg, mode)
	char	*arg;
	int	mode;
{
	int	mask;
	int	who, what, where;

	if (!isdigit(*arg)) {
		while (*arg != NULLB) {
			who = getwho(&arg);
			what = getwhat(&arg);
			where = getwhere(&arg);
			mask = permbits(who, where);
			who = whobits(who);
			switch (what) {
				case '+':
					mode |= mask;
					break;
				case '-':
					mode &= ~mask;
					break;
				case '=':
					mode &= ~who;
					mode |= mask;
					break;
			}
		}
	}
	else
		if (sscanf(arg, "%o", &mode) != 1)
			usage();
	return mode;
}

int
getwho(arg)
	char	**arg;
{
	int	who = 0;

	for (;;) {
		switch (**arg) {
			case ',':
				++*arg;
				break;
			case 'u':
				who |= USER;
				++*arg;
				break;
			case 'g':
				who |= GROUP;
				++*arg;
				break;
			case 'o':
				who |= OTHER;
				++*arg;
				break;
			case 'a':
				who = USER|GROUP|OTHER;
				++*arg;
				break;
			default:
				if (who == 0)
					who = USER|GROUP|OTHER;
				return who;
		}
	}
}

int
getwhat(arg)
	char	**arg;
{
	char	ch;

	for (;;) {
		switch (ch = **arg) {
			case '+':
			case '-':
			case '=':
				++*arg;
				return ch;
			case ',':
				++*arg;
				break;
			default:
				return '=';
		}
	}
}

int
getwhere(arg)
	char	**arg;
{
	int	mask = 0;

	for (;;) {
		switch (**arg) {
			case ',':
				++*arg;
				break;
			case 'r':
				mask |= READ;
				++*arg;
				break;
			case 'w':
				mask |= WRITE;
				++*arg;
				break;
			case 'x': /* ignore (execute permission is nonsensical) */
				++*arg;
				break;
			default:
				return mask;
		}
	}
}


int
permbits(who, perm)
	int	who, perm;
{
	int	mode = 0;

	perm &= (READ|WRITE);

	if (who & USER)
		mode = (perm<<USHIFT);
	if (who & GROUP)
		mode |= (perm<<GSHIFT);
	if (who & OTHER)
		mode |= (perm<<OSHIFT);
	return mode;
}

int
whobits(who)
	int	who;
{
	int	bits = 0;

	if (who & USER)
		bits = 0700;
	if (who & GROUP)
		bits |= 0070;
	if (who & OTHER)
		bits |= 0007;
	return bits;
}

int
report_options(filename)
	CharPtr	filename;
{
	struct passwd	*pwp;
	struct group	*grp;
	struct semid_ds	sem_ds;
	struct msqid_ds	msq_ds;
	struct shmid_ds	shm_ds;
	int	semid, msgid, shmid;
	key_t	key;
	int		rc;

	key = filetokey(filename);
	if (key == -1) {
		perror(filename);
		return -1;
	}

	semid = semget(key, 1, 0);
	if (semid == -1) {
		fprintf(stderr, "%s (%#010lx): semget: ", filename, key);
		perror(NULL);
		return -1;
	}
	msgid = msgget(key, 0);
	if (msgid == -1) {
		fprintf(stderr, "%s (%#010lx): msgget: ", filename, key);
		perror(NULL);
		return -1;
	}
	shmid = shmget(key, 0, 0);
	if (shmid == -1) {
		fprintf(stderr, "%s (%#010lx): shmget: ", filename, key);
		perror(NULL);
		return -1;
	}

	rc = semctl(semid, 0, IPC_STAT, &sem_ds);
	if (rc == -1) {
		perror("semctl");
		return -1;
	}
	rc = msgctl(msgid, IPC_STAT, &msq_ds);
	if (rc == -1) {
		perror("msgctl");
		return -1;
	}
	rc = shmctl(shmid, IPC_STAT, &shm_ds);
	if (rc == -1) {
		perror("shmctl");
		return -1;
	}

	printf("%s\t%#010lx", filename, key);

	printf("\t-U");
	if (pwp = getpwuid(sem_ds.sem_perm.uid))
		printf("%s", pwp->pw_name);
	else
		printf("%d", sem_ds.sem_perm.uid);

	printf(" -G");
	if (grp = getgrgid(sem_ds.sem_perm.gid))
		printf("%s", grp->gr_name);
	else
		printf("%d", sem_ds.sem_perm.gid);

	printf(" -s%o", sem_ds.sem_perm.mode & BITMASK(9));

	printf(" -q%o", msq_ds.msg_perm.mode & BITMASK(9));

	printf(" -m%o\n", shm_ds.shm_perm.mode & BITMASK(9));

	return 0;
}

key_t
filetokey(filename)
	CharPtr	filename;
{
	key_t	key;
	CharPtr	cp, cp2;

	if (hexnames) {
		if ((cp = str_chr(filename, 'x')) != NULL ||
				(cp = str_chr(filename, 'X')) != NULL)
			++cp;
		else
			cp = filename;
		cp2 = cp;
		while (*cp2 != NULLB && isxdigit(*cp2))
			++cp2;
		if (*cp == NULLB || *cp2 != NULLB) {
			fprintf(stderr, "Not a hexadecimal key:  %s\n", filename);
			return -1;
		}
		if (sscanf(cp, "%lx", &key) != 1) {
			perror(filename);
			return -1;
		}
		return key;
	}
	key = shm_mkkey(filename);
	if (key == -1)
		perror(filename);
	return key;
}

void
usage()
{
	static char *ray[] = {
	"Where valid options are:",
	"\t-v   [be verbose]",
	"\t-d   [run as a background daemon]",
	"\t-C dirname   [change directory before accessing files]",
	"\t-m shm_perm   [permissions on shared memory segments]",
	"\t-s sem_perm   [permissions on semaphores (re: concurrent access)]",
	"\t-q msq_perm   [permissions on message queues (re: updates and termination)]",
	"\t-p all_perm   [permissions for all three:  memory, semaphores, and queues]",
	"\t-l   [lock shared segments in physical memory (must be superuser)]",
	"\t-U uid  [all actions should be performed as user uid]",
	"\t-G gid  [all actions should be performed as group gid]",
	"\t-x   [use hexadecimal keys instead of filenames (with -u and -t only)]",
	"\t-Q   quiet flag (no output to stderr)",
	"\nAlternative usage options:",
	"\t-o   [report the command line options used to create the IPC objects]",
	"\t-u   [update an existing shared segment with the current file contents]",
	"\t-t   [terminate an existing shared segment]",
	"\nNote:  the syntax for permissions is either in octal notation, e.g. 644,",
	"       or in ugo (user, group, other) +-= rwx (read, write, execute) form.",
	"       (See the manual page for chmod(1)).",
	"CAUTION:  default permissions are taken from the user's current umask.",
	"",
	"This program synchronizes using the ftok() system call.  The manual page",
	"for ftok() should be studied for potential pitfalls to this technique,",
	"particularly when files currently in use by this program are deleted",
	"from the file system or replaced.",
		(char *)0
	};
	register char **cp;

	(void) fprintf(stderr,
		"Usage:  %s [options] file1 [file2 [file3 ... ] ]\n", module);
	for (cp = ray; *cp != NULL; cp++) {
		if (**cp == '\t')
			fprintf(stderr, "    %s\n", *cp + 1);
		else
			fprintf(stderr, "%s\n", *cp);
	}
	exit(1);
}
#endif /* SYSV_IPC_AVAIL */
