/*
contiene le path per i programma
*/


char direttorio[30] = "./";
char result[45] = "./";


/*
*/
FILE           *filhssp;
FILE           *filsp;
FILE           *filwrt;
#include <malloc.h>
#define NR_END 1
#define FREE_ARG char*



void 
breakpoint(char message_text[])
{
	printf("\n%s\n", message_text);
	scanf("%*c");
}

void 
error(char error_text[])
{				/* ERROR  */
	printf("\n%s\n", error_text);
	exit(1);
}

void 
nerror(char error_text[])
{				/* NERROR */
	fprintf(stderr, "run time error ...\n");
	fprintf(stderr, "%s\n", error_text);
	fprintf(stderr, ".....now exiting to sistem..\n");
	exit(1);
}

int           **
imatrix(long nrl, long nrh, long ncl, long nch)
{
	long            i, nrow = nrh - nrl + 1, ncol = nch - ncl + 1;
	int           **m;

	/* alloco puntatore di riga  */

	m = (int **) malloc((size_t) ((nrow + NR_END) * sizeof(int *)));
	if (!m)
		nerror("allocation failure 1 in matrix");
	m += NR_END;
	m -= nrl;

	/* allocazione riga e setto il puntatore a questa  */

	m[nrl] = (int *) malloc((size_t) ((nrow * ncol + NR_END) * sizeof(int)));
	if (!m[nrl])
		nerror("allocation failure 2 in matrix()");
	m[nrl] += NR_END;
	m[nrl] -= ncl;
	for (i = nrl + 1; i <= nrh; i++) {
		m[i] = m[i - 1] + ncol;
	}

	/* return pointer to array of pointers to rows  */
	return m;
}


void 
free_imatrix(int **m, int nrl, int nrh, int ncl, int nch)
/* free an int matrix allocated by imatrix()  */
{
	free((FREE_ARG) (m[nrl] + ncl - 1));
	free((FREE_ARG) (m + nrl - 1));
}



/* allocazione vettore intero    */

int            *
ivector(int nl, int nh)
{
	int            *v;
	v = (int *) malloc((size_t) ((nh - nl + 1 + NR_END) * sizeof(int)));
	if (!v)
		nerror("allocation failure in cvecto");
	return v - nl + NR_END;
}


void 
free_ivector(int *v, int nl, int nh)
{
	free((FREE_ARG) (v + nl - NR_END));
}
/*   ********** allocazione  vettore carattere  *****  */
unsigned char  *
cvector(int nl, int nh)
{
	unsigned char  *v;
	v = (unsigned char *) malloc((size_t) ((nh - nl + 1 + NR_END) * sizeof(unsigned char)));
	if (!v)
		nerror("allocation failure in cvector()");
	return v - nl + NR_END;
}

void 
free_cvector(unsigned char *v, int nl, int nh)
{
	free((FREE_ARG) (v + nl - NR_END));
}
