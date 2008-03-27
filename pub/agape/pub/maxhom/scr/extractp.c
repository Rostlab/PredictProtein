/*	extract.c	lookup protein sequences in the library */

/* 	copyright (c) 1984, 1985 William R. Pearson */

/*	this is a version of libprot that uses an index file */

/*CAL
 * seq.fn is used if sindex was run with @ i.e. a file of
 * library names. It is then used to identify the library file from the
 * @ file. In case there is only one library (no @) seq.fn is 0 
 * 
 * In addition program was modified to have the options of a 
 *	    long merged output file ( -l )
 *	    output to the terminal  ( -t )
 * program was modified to allow
 *	input of only library name (like nrprot) assumed in $BLASTDB
 *	input includes directory (may also include environmental variable)
 *	if no library given and $AABANK defined (points directly to a file or list of files)
 *			    armin 
 *
 *  !!!!!!! if sindex is run withoutdoing a cd into the directory where
 *          the database resides,  the file ...inx will contain ALSO the
 *          directory specification and everything will mess up 
 *	    therefore: run sindex in $BLASTDB
 *			    armin
 */

#include <stdio.h>
#include <string.h>
#include <fcntl.h>

#ifdef THINK_C
#include <stdlib.h>
#define getenv mgetenv
#include <MacTypes.h>
#include <StdFilePkg.h>
SFReply freply;
Point wpos;
int tval;
char prompt[256];
#else
#define TRUE 1
#define FALSE 0
#endif


/*CAL was 15, changed for consistency with sindex */

#define NAMLEN 20

FILE *tptr, *lptr, *optr;	/* file pointers for input, lib, output */
FILE *finx;

int fidx;			/* fd for index */
#ifndef UNIX
#define BMODE 0x8000
#else
#define BMODE 0x0000
#endif
#define RMODE 0
long filen, lseek();
long maxidx;

long lmark;
int lfn;

struct  {
	char nam[NAMLEN];
	char fn;
	long lmark;
	} seq;

long lboff;		/* offset into index file for new type */

#define MAXLF 20
#define MAXLN 50
char *getenv();
char libenv[80];
char lbnarr[1000];	/* name array of libraries to be opened in list */
char *lbnames[MAXLF];	/* names of libraries to be opened */
int libfn;		/* current library file being searched */
int iln, nln;

/*CAL */
int my_optarg;
int	blast_input=0, ssearch_input=0, long_output=0, term_output=0;
char	*long_outname,  *input_search_file;

char lline[512], oline[512], seqnam[120], oname[200];

#ifdef THINK_C
int glvRef,anvRef, sqvRef, ouvRef;
#endif

main(argc,argv)
	int argc; char **argv;
{
	char tname[80], lname[80], iname[80], inname[80], rline[40], *ep;
	char *pp;
	int ac,  i, ilb, tmode;
	char *bp, *strchr();
/*CAL */
	FILE *test_fptr;
	char *ptmp_libname, tmp_libname[1000];
/*CAL */

#ifdef THINK_C
	if (OpenResFile("\pFASTA.rsrc")<0) {
		SysBeep(100); fprintf(stderr," WARNING FASTA.rsrc file could not be found\n");
		}
	GetVol(prompt,&ouvRef);
	sqvRef=ouvRef;
	wpos.h=50; wpos.v=100;
#endif

	tname[0]='\0';

	printf(" extractp [May '90 1.4c] - get sequences from a sequence library\n");


	my_optarg = parse_args (argc,  argv);

	if (my_optarg)
	    {
	    for (ac=1; ac < argc-my_optarg; ac++)
		argv[ac]=argv[ac+my_optarg];
	    for (ac=argc-my_optarg; ac < argc; ac++)
		argv[ac]=NULL;
	    argc = argc - my_optarg;
	    }
	    
	printf ("\n");
	
	if (argc < 2) 
	    {
	    if (strlen(ep=getenv("AABANK"))<1) 
		{
/*CAL try to set at least default to BLASTDB at IRBM */
		if ((ep=getenv("BLASTDB"))==NULL) 
		    ep="\0";
		strcpy (tmp_libname, ep);
/*CAL append a / at end of directory if missing */
		if (strrchr(tmp_libname, '/')-tmp_libname < strlen(tmp_libname))
		    {
		    tmp_libname[strlen(tmp_libname)] ='/';
		    tmp_libname[strlen(tmp_libname)+1] ='\0';
		    strcpy(ep,tmp_libname);
		    }
		printf(" library name (assumed in $BLASTDB): ");
		fgets(lname,40,stdin);
		lname[strlen(lname)-1]='\0';
		strcat (tmp_libname, lname);
		strcpy (lname, tmp_libname);
		while ( (test_fptr=fopen(lname,"r"))==NULL)
		    {
		    strcpy (tmp_libname, ep);
		    printf ("\n Error ! Library does not exist ! \n");
		    printf(" library name (assumed in $BLASTDB): ");
		    fgets(lname,40,stdin);
		    lname[strlen(lname)-1]='\0';
		    strcat (tmp_libname, lname);
		    strcpy (lname, tmp_libname);
		    }
		if (!term_output) printf (" Using = %s library \n\n", ep);
		}	
	    else
		{
		if (!term_output) printf (" Using AABANK = %s library \n\n", ep);
		strcpy(lname,ep);
		ptmp_libname  = ep;
		strncpy (tmp_libname,  ptmp_libname, strrchr(ptmp_libname,'/')-ptmp_libname+1); 
		ep = tmp_libname;
		}
	    }
	else 
	    {
/*CAL 
 *    if 2 arguments database must have been specified, use BLASTDB as env 
 *    if no directory given
 */
	    strncpy(lname,argv[1],80);
	    if (strchr(lname, '/') != NULL)
		{
		ptmp_libname  = argv[1];
		strncpy (tmp_libname,  ptmp_libname, strrchr(ptmp_libname,'/')-ptmp_libname+1); 
		ep = tmp_libname;
		}
	    else
		{
/*CAL set default env to $BLASTDB at IRBM if AABANK not defined */
		ep=getenv("BLASTDB");
		strcpy (tmp_libname, ep);
/*CAL append a / at end of directory if missing */
		if (strrchr(tmp_libname, '/')-tmp_libname < strlen(tmp_libname))
		    {
		    tmp_libname[strlen(tmp_libname)] ='/';
		    tmp_libname[strlen(tmp_libname)+1] ='/';
		    strcat (tmp_libname, lname);
		    strncpy(lname,tmp_libname,strlen(tmp_libname));
		    }
		}
	    }
	    

	newname(iname,lname,"ixx",sizeof(inname));
	newname(inname,lname,"inx",sizeof(inname));

				
l2:	if ((fidx=open(iname,BMODE+RMODE)) == -1) {
#ifndef THINK_C
		printf(" could not open index file: %s\n",iname);
		printf(" index file name [%s]: ",iname);
		fgets(iname,40,stdin);
		if (iname[strlen(iname)-1]=='\n') iname[strlen(iname)-1]='\0';
		goto l2;
#else
		sprintf(prompt," could not open index file: %s\r Select index filename",iname);
		FileDlog(prompt,&freply);
		if (freply.good==TRUE) {
			strcpy(libenv,"\0");	
			PtoCstr((char *)freply.fName);
			strcpy(iname,(char *)freply.fName);
			sqvRef=freply.vRefNum;
			SetVol("\p\0",sqvRef);
			}
		goto l2;
#endif
		}
	
	if ((finx=fopen(inname,"r"))==NULL) {
		printf(" could not open inx file: %s\n",inname);
		exit(0);
	}
	
	if (ep!="\0") strcpy (libenv, ep);



	ilb = i = 0;
	while ((fgets(lline,sizeof(lline),finx))!=NULL) {
		if ((bp=strchr(lline,'\n'))!=NULL) *bp='\0';
		if (lline[0]=='<') {
			strncpy(libenv,&lline[1],sizeof(libenv));
		}
		else {
			lbnames[i++]= &lbnarr[ilb];
			strncpy(&lbnarr[ilb],lline,sizeof(lbnarr)-ilb);
			ilb += strlen(lline)+1;
			if (i>=MAXLF) break;
		}
	}
	
	fclose(finx);
		

	nln = i;

	libfn = -1;

	lboff = 0L;
	filen = lseek(fidx,0L,2);
	maxidx = (filen-lboff)/(long)sizeof(seq);

	if (argc<3) 
	    {
		if  (blast_input || ssearch_input) 
		    {
		    process_dbsearch_output ();
		    }
	 	/* get the sequence names and hash them */
		else
		    {
		    getnames(tname,40);
		    }
	    }
	else for (i=2; i<argc; i++)
		if (lookup(argv[i],&lmark,&lfn)==0)
			{
			printf(" 0  sequence %s not found\n",argv[i]);
			}
		else {
		    putfile(argv[i],lmark,lfn);
		    }

/*CAL close long output file */
	if (long_output) fclose(optr);

	printf ("\n");
	}

/* newname generates a new filename with prefix oname and suffix suff */

newname(nname,oname,suff,maxn)
	char *nname, *oname, *suff;
{
	char *tptr;
	int i;

	if (*oname!='@') strncpy(nname,oname,maxn);
	else strncpy(nname,oname+1,maxn);

	for (i=strlen(nname)-1; i>=0 && nname[i]!='.'; i--);
		 /* get to '.' or BOS */
	if (i>0) nname[i+1]='\0';
	else {nname[i=strlen(nname)]='.'; nname[i+1]='\0';}
	strncat(nname,suff,maxn);
	}

getnames(tname,maxnam)	/* read in the names and hash them */
	char *tname; int maxnam;
{
	int i;
	char tline[40];

l1:	if (strlen(tname)==0) {	/* get names from keyboard */
		printf(" protein sequence identifier: ");
		fgets(tname,maxnam,stdin);
		if (tname[i=strlen(tname)-1]=='\n') tname[i]='\0';
		if (tname[0]=='\0') return;
/*CAL */
		if (!term_output) printf ("%s\n",tname);
		}

	if (tname[0]=='@') {
		if ((tptr=fopen(&tname[1],"r"))==0) {
			printf(" cannot open name file %s\n",&tname[1]);
			tname[0]='\0';
			goto l1;
			}
		while (fgets(tline,40,tptr)!=0) {
			if (tline[i=strlen(tline)-1]=='\n') tline[i]='\0';
			if (lookup(tline,&lmark,&lfn)==0)
				printf(" 1 sequence %s not found\n",tline);
			else {
			    putfile(tline,lmark,lfn);
			    printf(" 2 found %s, creating %s.aa\n",tline,tline);
			    }
			}
		}
	else { 
		if (lookup(tname,&lmark,&lfn)==0)
			printf(" 3 sequence %s not found\n",tname);
		else {
		    putfile(tname,lmark,lfn);
		    }
		tname[0]='\0';
		goto l1;
		}
	}

ucase(str)	/* convert a string to upper case */
	char *str;
{
	while (*str) {
		if (*str >= 'a' && *str <= 'z') *str -= 'a' - 'A';
		str++;
		}
	}

lcase(str)	/* convert a string to lower case */
	char *str;
{
	while (*str) {
		if (*str >= 'A' && *str <= 'Z') *str += 'a' - 'A';
		str++;
		}
	}

lookup(name,mark,seqfn)	/* lookup names in library */
	char *name; long *mark; int *seqfn;
{
	long hi, lo, mid, diff;
	long pos;

/*	ucase(name);*/

/* binary search for code */

	lo = 0;
	hi = maxidx;
	while (hi >= lo) {
		mid = (hi + lo)/2l;
		pos = (long)mid * (long)sizeof(seq);
		lseek(fidx, pos+lboff, 0);
		read(fidx,(char *)&seq, sizeof(seq));
/*CAL */
/*		if (!term_output) 
		    printf("%s %d %s \n",seq.nam,seq.lmark, name);
 */
		   /* printf("%s %d %s \n",seq.nam,seq.lmark, name);*/
		if ((diff = strcmp(name, seq.nam)) == 0) {
			*mark = seq.lmark;
			*seqfn = seq.fn;
			return 1;
			}
		else if (diff < 0)
			hi = mid - 1l;
		else
			lo = mid + 1l;
		}
	return 0;
	}

putfile(seqnam,seqmark,seqfn)
	char *seqnam; long seqmark; int seqfn;
{
	int i;
	char *p1,*p2,*p3,*p_sp,*newseqnam;

	/*CAL prepare for the |'s in blast2 standard db entry names 
	 * take last part (entry name as real name) for output filename
	 */

	if ((! term_output) && (! long_output))
	    {
	    if ( (p1  = strstr(seqnam,"|")) != NULL)
		{
		if ( ( p2  = strstr(p1+1,"|")) != NULL)
		    {
		    p2++;
		    seqnam = p2;
		    }
		else
		    {
		    p1++;
		    seqnam = p1;
		    }
		}
	    }
	strncpy(oname,seqnam,40);
	lcase(oname);

/*CAL changed from .aa to .pep at IRBM */



	strcat(oname,".pep");

#ifdef THINK_C
	SetVol("\p0\0",ouvRef);
#endif


/*CAL changed to allow output to term or merged output file ? */

	if (term_output)
	    {
	    if (seqfn!=libfn) 
		{
		closelib();
		if (openlib(lbnames[seqfn],libenv)<0) return;
		libfn=seqfn;
		}
	    /*printf (" lline = %s \n", lline);
	    printf (" seqmark = %d \n", seqmark);*/
	    if (fseek(lptr,seqmark,0) != 0)
		printf (" error in fseek \n");
	    /*fgets(lline,10240,lptr);*/
	    fgets(lline, sizeof(lline), lptr);
	    /*printf (" lline = %s \n", lline);*/
/*CAL not applied for term or HTML */
/*	    
	    if (strlen(lline)>72) {lline[72]='\0'; lline[73]='\0';}
 */
	    printf ("%s",lline);
	    while(fgets(lline,71,lptr) && lline[0]!='>') {
/*CAL not needed for terminal or HTML */
/*		if (lline[(i=strlen(lline)-1)]!='\n') {
			lline[i+1]='\n'; lline[i+2]='\0';
		    }
 */
		printf ("%s",lline);
		}
	    }
	else
	    {
	    if (long_output)
		{
		if ( optr == 0) 
			{
		    	if ((optr=fopen(long_outname,"w"))==0)
			    {
			    printf(" cannot open %s\n",long_outname);
			    exit (1);
			    }
			}
		}
	    else
		{

		if ((optr=fopen(oname,"w"))==0)
		    {
		    printf(" cannot open %s\n",oname);
		    exit (0);
		    }
		}
	    if (seqfn!=libfn) 
		{
		closelib();
		if (openlib(lbnames[seqfn],libenv)<0) return;
		libfn=seqfn;
		}
	    fseek(lptr,seqmark,0);
	    fgets(lline,10240,lptr);
/*CAL not needed for terminal or HTML but apply if automatically processing an
 * output of a database search; for example hssp doesn't like documentation lines 
 * that are too long
 */
	    if (blast_input || ssearch_input ) 
		if (strlen(lline)>72) {lline[72]='\n'; lline[73]='\0';}
	    fputs(lline,optr);
	    while(fgets(lline,71,lptr) && lline[0]!='>') {
		if (lline[(i=strlen(lline)-1)]!='\n') {
		    lline[i+1]='\n'; lline[i+2]='\0';
		    }
		fputs(lline,optr);
		}
	    }
	if (!long_output) fclose(optr);
	}

openlib(lname,libenv)
	char *lname, *libenv;
{
	char lbname[80],rline[10], *pp;
	long ftell();
	int wcnt;

	wcnt=0;



	if (*libenv!='\0') {
		strncpy(lbname,libenv,sizeof(lbname));
#ifdef UNIX
		strcat(lbname,"/");
#endif
		}
	else *lbname='\0';



/*	if ( (pp=getenv("AABANK"))==NULL)
	    strncat(lbname,lname,sizeof(lbname)-strlen(lbname));
 */
	    strncat(lbname,lname,sizeof(lbname)-strlen(lbname));

#ifdef THINK_C
	SetVol("\p",sqvRef);
l1:	if ((lptr=fopen(lbname,"r"))==NULL) {
		sprintf(prompt," cannot open %s\r Select library filename",lbname);
		FileDlog(prompt,&freply);
		if (freply.good==TRUE) {
			strcpy(libenv,"\0");	
			PtoCstr((char *)freply.fName);
			strcpy(lbname,(char *)freply.fName);
			sqvRef=anvRef=freply.vRefNum;
			SetVol("\p\0",sqvRef);
			goto l1;
			}
		else return -1;
		}
#else		/* MSDOS */

l1:	if ((lptr=fopen(lbname,"r"))==0) {
		rline[0]='\0';
		fprintf(stderr," Cannot open %s library\n",lbname);
		fprintf(stderr," insert another disk or type Y to skip <N> ");
		fflush(stderr);
		if (fgets(rline,10,stdin)==NULL) return -1;
		if (my_toupper(rline[0])=='Y') return 0;
		if (++wcnt > 10) return -1;
		goto l1;
		}
#endif
	return 1;
	}

closelib()
{
	if (lptr!=NULL) fclose(lptr);
	}

my_toupper(c)
     char c;
{
  if (c>='a' && c<='z') return c-'a'+'A';
  return c;
}


int parse_args (argc,argv)
    int argc;
    char **argv;

{
    char    opt,*cp;
    int	    my_optarg=0,  ac;

/*CAL see if we have - options present; if yes interpret them and shift
 *    the argv 
 */
 
    if (argc < 2)
	return; 
    else
	{
	/*CAL look if nothing to do */
	if ( (cp = strchr(argv[1], '-') ) == NULL) 
	    return 0;
	else
	    {
	    for (ac = 1; ac < argc ; ac++)
		{
		 /*CAL done, this must be either seq db or seq name */
		if ((cp = strchr(argv[ac], '-')) == NULL) 
		    break;
		cp += (*cp == '-'); /* skip over any leading '-' */
		my_optarg++;
		opt = *cp;
		switch (opt)
		    {
		    case 'l':
			long_output = 1;
			if ((strncmp(argv[ac+1], "-",1)) == 0)
			    {
			    printf (" ERROR! No filename given ! \n");
			    exit(1);
			    }
			long_outname = argv[ac+1];
			ac++;
			my_optarg++;
			break;
		    case 't':
			term_output = 1;
			break;
		    case 'b':
			if (ssearch_input) 
			    {
			    printf (" IGNORED ! ONly blast OR ssearch input file! \n");
			    ac++;
			    my_optarg++;
			    break;
			    }
			blast_input = 1;
			if ((strncmp(argv[ac+1], "-",1)) == 0)
			    {
			    printf (" ERROR! No blast input filename given ! \n");
			    exit(1);
			    }
			input_search_file = argv[ac+1];
			ac++;
			my_optarg++;
			break;
		    case 's':
			if (blast_input) 
			    {
			    printf (" IGNORED ! ONly blast OR ssearch input file! \n");
			    ac++;
			    my_optarg++;
			    break;
			    }
			ssearch_input = 1;
			if ((strncmp(argv[ac+1], "-",1)) == 0)
			    {
			    printf (" ERROR! No ssearch (or fasta) input filename given ! \n");
			    exit(1);
			    }
			input_search_file = argv[ac+1];
			ac++;
			my_optarg++;
			break;
		    case 'u':
			print_usage ();
		    default:
			printf (" ERROR undefined option %c ! Ignored \n", opt);
			exit(1);
		    }
		}
	    }
	}

    return(my_optarg);
    
}

process_dbsearch_output ()

{
FILE	*infile_fpt;
int	i;
char	*p,  seq_name[40], str[200];

    if ( (infile_fpt=fopen(input_search_file,"r")) == NULL )
	{
	printf(" could not open input file: %s\n",input_search_file);
	exit(0);
	}
    while (( p = fgets (str, sizeof str, infile_fpt)) != NULL)
	{
	if (blast_input) 
	    {
	    if (strstr (p, "Sequences producing") != NULL)
		break;
	    }
	else
	    {
	    if (strstr (p, "The best scores are") != NULL)
		break;
	    }
	}
    
    if (p==NULL)
	{
	printf (" ERROR Premature End of file reached ! <p> \n");
	exit(1);
	}
    if (blast_input) fgets (str, sizeof str, infile_fpt);
    while (( p = fgets (str, sizeof str, infile_fpt)) != NULL)
	{
	if (str [0] == '\n')
	    break;
	sscanf(str,"%s", seq_name);
	/*printf ("seq_name = X%sX\n", seq_name);*/
	if (lookup(seq_name,&lmark,&lfn)==0)
	    printf(" 4 sequence %s not found\n",seq_name);
	else
	    putfile(seq_name,lmark,lfn);
	}
}

print_usage()

{
    printf ("\nUsge:\n extractp [-t -l long.pep -u] dbname seq_name1 seq_name2 ..... \n");
    printf ("   or \n");
    printf (" extractp [-t -l long.pep -u] dbname < file.name  \n");
    printf (" \n");
    printf (" Neither dbname or seq_name have to given,  but it is advisable \n");
    printf ("   to use one of the names or qualifiers defined in $FASTLIBS: \n\n");
    printf ("   -t		sequence output to terminal \n");
    printf ("   -l long.pep	merged sequence output to long.pep \n");
    printf ("   -b blast.output	   process blast output file \n");
    printf ("   -s ssearch.output  process ssearch or fasta output file \n");
    printf ("   -u		program usage \n");
    printf (" \n");
    printf ("  Database can be defined as follows: \n");
    printf ("    if nothing is given the environmental variable $BLASTDB is searched \n");
    printf ("                   default: nrprot  \n");
    printf ("    dbname		searches dbname in $BLASTDB \n");
    printf ("    /nfs/bacco/...	searches specified db (.inx file has to be present \n");
    printf ("\n");
    printf ("  Sequence names can be given on the command; otherwise you \n");
    printf ("   will be asked interactively. Giving a < file.name will \n");
    printf ("   make the program loop through the file and extract all \n");
    printf ("   the sequences \n");
    printf (" \n");
    printf (" Remember that sequence names are case SENSITIVE,  also don\'t \n");
    printf ("   leave a blank after them if given interactively or in a file \n");
    printf ("\n Available databases: \n\n");
    system ("cat $FASTLIBS");
    printf ("\n\n Instead for use in ssearch or fasta just give a %% followed by the db id \n");
    printf ("   for example:   ssearch %%Z searches the pdb100 database \n");
    exit(0);
    
}
