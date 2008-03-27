/* Change int h to int gh everywhere  DES June 1994 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "clustalw.h"

#define MIN(a,b) ((a)<(b)?(a):(b))
#define MAX(a,b) ((a)>(b)?(a):(b))

#define gap(k)  ((k) <= 0 ? 0 : mp_data->g + mp_data->gh * (k))
#define tbgap(k)  ((k) <= 0 ? 0 : tb + mp_data->gh * (k))
#define tegap(k)  ((k) <= 0 ? 0 : te + mp_data->gh * (k))

/*
 *   Global variables
 */
#ifdef MAC
#define pwint   short
#else
#define pwint   int
#endif
static sint		int_scale;

extern double   **tmat;
extern float    pw_go_penalty;
extern float    pw_ge_penalty;
extern float	transition_weight;
extern sint 	nseqs;
extern sint 	max_aa;
extern sint 	gap_pos1,gap_pos2;
extern sint  	max_aln_length;
extern sint 	*seqlen_array;
extern sint 	debug;
extern sint  	mat_avscore;
extern short 	blosum30mt[],pam350mt[],idmat[],pw_usermat[],pw_userdnamat[];
extern short    clustalvdnamt[],swgapdnamt[];
extern short    gon250mt[];
extern short 	def_dna_xref[],def_aa_xref[],pw_dna_xref[],pw_aa_xref[];
extern Boolean  dnaflag;
extern char 	**seq_array;
extern char 	*amino_acid_codes;
extern char 	pw_mtrxname[];
extern char 	pw_dnamtrxname[];

/* ChB
static float 	mm_score;
static sint 	print_ptr,last_print;
static sint 	*displ;
static pwint 	*HH, *DD, *RR, *SS;
static sint 	g, gh;
static sint   	seq1, seq2;
static sint     matrix[NUMRES][NUMRES];
static pwint    maxscore;
static sint    	sb1, sb2, se1, se2;
*/

typedef struct {
	float 	mm_score;
	sint 	print_ptr,last_print;
	sint 	*displ;
	pwint 	*HH, *DD, *RR, *SS;
	sint 	g, gh;
	sint   	seq1, seq2;
	sint     matrix[NUMRES][NUMRES];
	pwint    maxscore;
	sint    	sb1, sb2, se1, se2;
} ChB_mp_data;

/***/

/*
*	Prototypes
*/
/* ChB
static void add(sint v);
static sint calc_score(sint iat, sint jat, sint v1, sint v2);
static float tracepath(sint tsb1,sint tsb2);
static void forward_pass(char *ia, char *ib, sint n, sint m);
static void reverse_pass(char *ia, char *ib);
static sint diff(sint A, sint B, sint M, sint N, sint tb, sint te);
static void del(sint k);
*/
static void add(sint v, ChB_mp_data *mp_data);
static sint calc_score(sint iat, sint jat, sint v1, sint v2, ChB_mp_data *mp_data);
static float tracepath(sint tsb1,sint tsb2, ChB_mp_data *mp_data);
static void forward_pass(char *ia, char *ib, sint n, sint m, ChB_mp_data *mp_data);
static void reverse_pass(char *ia, char *ib, ChB_mp_data *mp_data);
static sint diff(sint A, sint B, sint M, sint N, sint tb, sint te, ChB_mp_data *mp_data);
static void del(sint k, ChB_mp_data *mp_data);



sint pairalign(sint istart, sint iend, sint jstart, sint jend)
{
  short	 *mat_xref;
  static sint    si, sj, i;
  static sint    n,m,len1,len2;
  static sint    maxres;
  static short    *matptr;
  static char   c;
  static float gscale,ghscale;

/* ChB */
	int mp_si_max, mp_sj_max;
	ChB_mp_data mp_data;

#pragma omp parallel private (n,i,c,len1,mp_data,   m,len2,si) 
{
/***/

	mp_data.displ = (sint *)ckalloc((2*max_aln_length+1) * sizeof(sint));
	mp_data.HH = (pwint *)ckalloc((max_aln_length) * sizeof(pwint));
	mp_data.DD = (pwint *)ckalloc((max_aln_length) * sizeof(pwint));
	mp_data.RR = (pwint *)ckalloc((max_aln_length) * sizeof(pwint));
	mp_data.SS = (pwint *)ckalloc((max_aln_length) * sizeof(pwint));
		
#ifdef MAC
       int_scale = 10;
#else
       int_scale = 100;
#endif
  gscale=ghscale=1.0;
  if (dnaflag)
     {
if (debug>1) fprintf(stdout,"matrix %s\n",pw_dnamtrxname);
       if (strcmp(pw_dnamtrxname, "iub") == 0)
          { 
             matptr = swgapdnamt;
             mat_xref = def_dna_xref;
	  }
       else if (strcmp(pw_dnamtrxname, "clustalw") == 0)
          { 
             matptr = clustalvdnamt;
             mat_xref = def_dna_xref;
             gscale=0.6667;
             ghscale=0.751;
	  }
       else
          {
             matptr = pw_userdnamat;
             mat_xref = pw_dna_xref;
          }
            maxres = get_matrix(matptr, mat_xref, mp_data.matrix, TRUE, int_scale);
            if (maxres == 0) return((sint)-1);

            mp_data.matrix[0][4]=transition_weight*mp_data.matrix[0][0];
            mp_data.matrix[4][0]=transition_weight*mp_data.matrix[0][0];
            mp_data.matrix[2][11]=transition_weight*mp_data.matrix[0][0];
            mp_data.matrix[11][2]=transition_weight*mp_data.matrix[0][0];
            mp_data.matrix[2][12]=transition_weight*mp_data.matrix[0][0];
            mp_data.matrix[12][2]=transition_weight*mp_data.matrix[0][0];
    }
  else
    {
if (debug>1) fprintf(stdout,"matrix %s\n",pw_mtrxname);
       if (strcmp(pw_mtrxname, "blosum") == 0)
          {
             matptr = blosum30mt;
             mat_xref = def_aa_xref;
          }
       else if (strcmp(pw_mtrxname, "pam") == 0)
          {
             matptr = pam350mt;
             mat_xref = def_aa_xref;
          }
       else if (strcmp(pw_mtrxname, "gonnet") == 0)
          {
             matptr = gon250mt;
             int_scale /= 10;
             mat_xref = def_aa_xref;
          }
       else if (strcmp(pw_mtrxname, "id") == 0)
          {
             matptr = idmat;
             mat_xref = def_aa_xref;
          }
       else
          {
             matptr = pw_usermat;
             mat_xref = pw_aa_xref;
          }

       maxres = get_matrix(matptr, mat_xref, mp_data.matrix, TRUE, int_scale);
       if (maxres == 0) return((sint)-1);
    }


/* ChB  
  for (si=MAX(0,istart);si<nseqs && si<iend;si++)
*/
  mp_si_max = MIN (nseqs,iend);
  for (si=MAX(0,istart);si<mp_si_max;si++)
/***/
   {
     n = seqlen_array[si+1];
     len1 = 0;
     for (i=1;i<=n;i++) {
		c = seq_array[si+1][i];
		if ((c!=gap_pos1) && (c != gap_pos2)) len1++;
     }

/* ChB  
     for (sj=MAX(si+1,jstart+1);sj<nseqs && sj<jend;sj++)
*/
		mp_sj_max = MIN (nseqs,jend);
#pragma omp for
		for (sj=MAX(si+1,jstart+1);sj<mp_sj_max;sj++) 
/***/
      {
        m = seqlen_array[sj+1];
        if(n==0 || m==0) {
		tmat[si+1][sj+1]=1.0;
		tmat[sj+1][si+1]=1.0;
		continue;
	}
		len2 = 0;
		for (i=1;i<=m;i++) {
			c = seq_array[sj+1][i];
			if ((c!=gap_pos1) && (c != gap_pos2)) len2++;
		}

        if (dnaflag) {
           mp_data.g = 2 * (float)pw_go_penalty * int_scale*gscale;
           mp_data.gh = pw_ge_penalty * int_scale*ghscale;
        }
        else {
           if (mat_avscore <= 0)
              mp_data.g = 2 * (float)(pw_go_penalty + log((double)(MIN(n,m))))*int_scale;
           else
              mp_data.g = 2 * mat_avscore * (float)(pw_go_penalty +
                    log((double)(MIN(n,m))))*gscale;
           mp_data.gh = pw_ge_penalty * int_scale;
        }

if (debug>1) fprintf(stdout,"go %d ge %d\n",(pint)mp_data.g,(pint)mp_data.gh);

/*
   align the sequences
*/
        mp_data.seq1 = si+1;
        mp_data.seq2 = sj+1;

        forward_pass(&seq_array[mp_data.seq1][0], &seq_array[mp_data.seq2][0],
           n, m, &mp_data);

        reverse_pass(&seq_array[mp_data.seq1][0], &seq_array[mp_data.seq2][0], &mp_data);

        mp_data.last_print = 0;
	mp_data.print_ptr = 1;
/*
        mp_data.sb1 = mp_data.sb2 = 1;
        mp_data.se1 = n-1;
        mp_data.se2 = m-1;
*/

/* use Myers and Miller to align two sequences */

        mp_data.maxscore = diff(mp_data.sb1-1, mp_data.sb2-1, mp_data.se1-mp_data.sb1+1, mp_data.se2-mp_data.sb2+1, 
        (sint)0, (sint)0, &mp_data);
 
/* calculate percentage residue identity */

        mp_data.mm_score = tracepath(mp_data.sb1,mp_data.sb2, &mp_data);

		if(len1==0 || len2==0) mp_data.mm_score=0;
		else
			mp_data.mm_score /= (float)MIN(len1,len2);

        tmat[si+1][sj+1] = ((float)100.0 - mp_data.mm_score)/(float)100.0;
        tmat[sj+1][si+1] = ((float)100.0 - mp_data.mm_score)/(float)100.0;

if (debug>1)
{
        fprintf(stdout,"Sequences (%d:%d) Aligned. Score: %d CompScore:  %d\n",
                           (pint)si+1,(pint)sj+1, 
                           (pint)mp_data.mm_score, 
                           (pint)mp_data.maxscore/(MIN(len1,len2)*100));
}
else
{
        info("Sequences (%d:%d) Aligned. Score:  %d",
                                      (pint)si+1,(pint)sj+1, 
                                      (pint)mp_data.mm_score);
}

   }
  }
   mp_data.displ=ckfree((void *)mp_data.displ);
   mp_data.HH=ckfree((void *)mp_data.HH);
   mp_data.DD=ckfree((void *)mp_data.DD);
   mp_data.RR=ckfree((void *)mp_data.RR);
   mp_data.SS=ckfree((void *)mp_data.SS);

/* ChB pragma omp parallel end */
}
/***/

  return((sint)1);
}

static void add(sint v, ChB_mp_data *mp_data)
{
        if(mp_data->last_print<0) {
                mp_data->displ[mp_data->print_ptr-1] = v;
                mp_data->displ[mp_data->print_ptr++] = mp_data->last_print;
        }
        else
                mp_data->last_print = mp_data->displ[mp_data->print_ptr++] = v;

	return;
}

static sint calc_score(sint iat,sint jat,sint v1,sint v2, ChB_mp_data *mp_data)
{
        sint ipos,jpos;
		sint ret;

        ipos = v1 + iat;
        jpos = v2 + jat;

        ret=mp_data->matrix[(int)seq_array[mp_data->seq1][ipos]][(int)seq_array[mp_data->seq2][jpos]];

	return(ret);
}


static float tracepath(sint tsb1,sint tsb2, ChB_mp_data *mp_data)
{
	char c1,c2;
    sint  i1,i2;
    sint i,k,pos,to_do;
	sint count;
	float score;
/*	char *s1, *s2;
*/

        to_do=mp_data->print_ptr-1;
        i1 = tsb1;
        i2 = tsb2;

	pos = 0;
	count = 0;
        for(i=1;i<=to_do;++i) {

if (debug>1) fprintf(stdout,"%d ",(pint)mp_data->displ[i]);
                if(mp_data->displ[i]==0) {
			c1 = seq_array[mp_data->seq1][i1];
			c2 = seq_array[mp_data->seq2][i2];
/*
if (debug>1)
{
if (c1>max_aa) s1[pos] = '-';
else s1[pos]=amino_acid_codes[c1];
if (c2>max_aa) s2[pos] = '-';
else s2[pos]=amino_acid_codes[c2];
}
*/
			if ((c1!=gap_pos1) && (c1 != gap_pos2) &&
                                    (c1 == c2)) count++;
                        ++i1;
                        ++i2;
                        ++pos;
                }
                else {
                        if((k=mp_data->displ[i])>0) {
/*
if (debug>1)
for (r=0;r<k;r++)
{
s1[pos+r]='-';
if (seq_array[mp_data->seq2][i2+r]>max_aa) s2[pos+r] = '-';
else s2[pos+r]=amino_acid_codes[seq_array[mp_data->seq2][i2+r]];
}
*/
                                i2 += k;
                                pos += k;
                        }
                        else {
/*
if (debug>1)
for (r=0;r<(-k);r++)
{
s2[pos+r]='-';
if (seq_array[mp_data->seq1][i1+r]>max_aa) s1[pos+r] = '-';
else s1[pos+r]=amino_acid_codes[seq_array[mp_data->seq1][i1+r]];
}
*/
                                i1 -= k;
                                pos -= k;
                        }
                }
        }
/*
if (debug>1) fprintf(stdout,"\n");
if (debug>1) 
{
for (i=0;i<pos;i++) fprintf(stdout,"%c",s1[i]);
fprintf(stdout,"\n");
for (i=0;i<pos;i++) fprintf(stdout,"%c",s2[i]);
fprintf(stdout,"\n");
}
        if (count <= 0) count = 1;
*/
	score = 100.0 * (float)count;

	return(score);
}


static void forward_pass(char *ia, char *ib, sint n, sint m, ChB_mp_data *mp_data)
{
  sint i,j;
  pwint f,hh,p,t;

  mp_data->maxscore = 0;
  mp_data->se1 = mp_data->se2 = 0;
  for (i=0;i<=m;i++)
    {
       mp_data->HH[i] = 0;
       mp_data->DD[i] = -mp_data->g;
    }

  for (i=1;i<=n;i++)
     {
        hh = p = 0;
		f = -mp_data->g;

        for (j=1;j<=m;j++)
           {

              f -= mp_data->gh; 
              t = hh - mp_data->g - mp_data->gh;
              if (f<t) f = t;

              mp_data->DD[j] -= mp_data->gh;
              t = mp_data->HH[j] - mp_data->g - mp_data->gh;
              if (mp_data->DD[j]<t) mp_data->DD[j] = t;

              hh = p + mp_data->matrix[(int)ia[i]][(int)ib[j]];
              if (hh<f) hh = f;
              if (hh<mp_data->DD[j]) hh = mp_data->DD[j];
              if (hh<0) hh = 0;

              p = mp_data->HH[j];
              mp_data->HH[j] = hh;

              if (hh > mp_data->maxscore)
                {
                   mp_data->maxscore = hh;
                   mp_data->se1 = i;
                   mp_data->se2 = j;
                }
           }
     }

	return;
}


static void reverse_pass(char *ia, char *ib, ChB_mp_data *mp_data)
{
  sint i,j;
  pwint f,hh,p,t;
  pwint cost;

  cost = 0;
  mp_data->sb1 = mp_data->sb2 = 1;
  for (i=mp_data->se2;i>0;i--)
    {
       mp_data->HH[i] = -1;
       mp_data->DD[i] = -1;
    }

  for (i=mp_data->se1;i>0;i--)
     {
        hh = f = -1;
        if (i == mp_data->se1) p = 0;
        else p = -1;

        for (j=mp_data->se2;j>0;j--)
           {

              f -= mp_data->gh; 
              t = hh - mp_data->g - mp_data->gh;
              if (f<t) f = t;

              mp_data->DD[j] -= mp_data->gh;
              t = mp_data->HH[j] - mp_data->g - mp_data->gh;
              if (mp_data->DD[j]<t) mp_data->DD[j] = t;

              hh = p + mp_data->matrix[(int)ia[i]][(int)ib[j]];
              if (hh<f) hh = f;
              if (hh<mp_data->DD[j]) hh = mp_data->DD[j];

              p = mp_data->HH[j];
              mp_data->HH[j] = hh;

              if (hh > cost)
                {
                   cost = hh;
                   mp_data->sb1 = i;
                   mp_data->sb2 = j;
                   if (cost >= mp_data->maxscore) break;
                }
           }
        if (cost >= mp_data->maxscore) break;
     }

	return;
}

static int diff(sint A,sint B,sint M,sint N,sint tb,sint te, ChB_mp_data *mp_data)
{
		sint type;
        sint midi,midj,i,j;
        int midh;
 /* ChB 
       static  pwint f, hh, e, s, t;
*/
	pwint f, hh, e, s, t;
/***/

        if(N<=0)  {
                if(M>0) {
                        del(M, mp_data);
                }

                return(-(int)tbgap(M));
        }

        if(M<=1) {
                if(M<=0) {
                        add(N, mp_data);
                        return(-(int)tbgap(N));
                }

                midh = -(tb+mp_data->gh) - tegap(N);
                hh = -(te+mp_data->gh) - tbgap(N);
		if (hh>midh) midh = hh;
                midj = 0;
                for(j=1;j<=N;j++) {
                        hh = calc_score(1,j,A,B, mp_data)
                                    - tegap(N-j) - tbgap(j-1);
                        if(hh>midh) {
                                midh = hh;
                                midj = j;
                        }
                }

                if(midj==0) {
                        del(1, mp_data);
                        add(N, mp_data);
                }
                else {
                        if(midj>1)
                                add(midj-1, mp_data);
                        mp_data->displ[mp_data->print_ptr++] = mp_data->last_print = 0;
                        if(midj<N)
                                add(N-midj, mp_data);
                }
                return midh;
        }

/* Divide: Find optimum midpoint (midi,midj) of cost midh */

        midi = M / 2;
        mp_data->HH[0] = 0.0;
        t = -tb;
        for(j=1;j<=N;j++) {
                mp_data->HH[j] = t = t-mp_data->gh;
                mp_data->DD[j] = t-mp_data->g;
        }

        t = -tb;
        for(i=1;i<=midi;i++) {
                s=mp_data->HH[0];
                mp_data->HH[0] = hh = t = t-mp_data->gh;
                f = t-mp_data->g;
                for(j=1;j<=N;j++) {
                        if ((hh=hh-mp_data->g-mp_data->gh) > (f=f-mp_data->gh)) f=hh;
                        if ((hh=mp_data->HH[j]-mp_data->g-mp_data->gh) > (e=mp_data->DD[j]-mp_data->gh)) e=hh;
                        hh = s + calc_score(i,j,A,B, mp_data);
                        if (f>hh) hh = f;
                        if (e>hh) hh = e;

                        s = mp_data->HH[j];
                        mp_data->HH[j] = hh;
                        mp_data->DD[j] = e;
                }
        }

        mp_data->DD[0]=mp_data->HH[0];

        mp_data->RR[N]=0;
        t = -te;
        for(j=N-1;j>=0;j--) {
                mp_data->RR[j] = t = t-mp_data->gh;
                mp_data->SS[j] = t-mp_data->g;
        }

        t = -te;
        for(i=M-1;i>=midi;i--) {
                s = mp_data->RR[N];
                mp_data->RR[N] = hh = t = t-mp_data->gh;
                f = t-mp_data->g;

                for(j=N-1;j>=0;j--) {

                        if ((hh=hh-mp_data->g-mp_data->gh) > (f=f-mp_data->gh)) f=hh;
                        if ((hh=mp_data->RR[j]-mp_data->g-mp_data->gh) > (e=mp_data->SS[j]-mp_data->gh)) e=hh;
                        hh = s + calc_score(i+1,j+1,A,B, mp_data);
                        if (f>hh) hh = f;
                        if (e>hh) hh = e;

                        s = mp_data->RR[j];
                        mp_data->RR[j] = hh;
                        mp_data->SS[j] = e;

                }
        }

        mp_data->SS[N]=mp_data->RR[N];

        midh=mp_data->HH[0]+mp_data->RR[0];
        midj=0;
        type=1;
        for(j=0;j<=N;j++) {
                hh = mp_data->HH[j] + mp_data->RR[j];
                if(hh>=midh)
                        if(hh>midh || (mp_data->HH[j]!=mp_data->DD[j] && mp_data->RR[j]==mp_data->SS[j])) {
                                midh=hh;
                                midj=j;
                        }
        }

        for(j=N;j>=0;j--) {
                hh = mp_data->DD[j] + mp_data->SS[j] + mp_data->g;
                if(hh>midh) {
                        midh=hh;
                        midj=j;
                        type=2;
                }
        }

        /* Conquer recursively around midpoint  */


        if(type==1) {             /* Type 1 gaps  */
                diff(A,B,midi,midj,tb,mp_data->g, mp_data);
                diff(A+midi,B+midj,M-midi,N-midj,mp_data->g,te, mp_data);
        }
        else {
                diff(A,B,midi-1,midj,tb,0.0, mp_data);
                del(2, mp_data);
                diff(A+midi+1,B+midj,M-midi-1,N-midj,0.0,te, mp_data);
        }

        return midh;       /* Return the score of the best alignment */
}

static void del(sint k, ChB_mp_data *mp_data)
{
        if(mp_data->last_print<0)
                mp_data->last_print = mp_data->displ[mp_data->print_ptr-1] -= k;
        else
                mp_data->last_print = mp_data->displ[mp_data->print_ptr++] = -(k);
         
         return;
}


