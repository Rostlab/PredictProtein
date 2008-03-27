/*

Usage: `psic aln_file matrix_file [out_file]'

`aln_file' is a fixed column-width file:

CLUSTAL P05091
<empty line>
desc1 seq1
desc2 seq2
...

width of desc is DESC_WIDTH 

*/

#define MAXSEQLEN 20000
#define MAXSEQNUM 10000
#define DESC_WIDTH 67
#define AL_SIZE   20
#define PROBS     0
#define NA_AA     -1

#define NUM_NEFF 35
#define NA_NEFF -1000.0

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

//--------------------------------------------------------------------

int   read_aln_file(char *fname); // modified! not for 'real' clustal format
int   read_matr_file(char *fname);
int   allocate_mem(void);
int   writeProfile(char *fname);
int   getAlphabetSymbolIndex(char symbol);
void  prepare_profile_fname(char *src, char *dst);
int   make_aln_matrix(void);

void   calculateNumSeq(void);
int    calculateSimilarities(void);
void   calculateNEff(void);
void   calculateFreqs(void);
void   calculateProbs(void);
double getTableNEff(double similarity);



//--------------------------------------------------------------------

double table_neff[NUM_NEFF] = {
	1.0, 1.5, 2.0, 2.5, 3.1, 3.8, 4.2, 5.0, 5.8, 6.4, 7.0, 7.8, 8.9,
	9.5, 10.2, 11.2, 12.2, 13.2, 14.2, 15.2, 16.2, 17.5, 19.0, 20.2,
	22.0, 23.5, 25.8, 27.5, 30.0, 33.0, 35.5, 40.0, 44.0, 50.0, 55.0
};

char alphabet[AL_SIZE] = "ARNDCQEGHILKMFPSTWYV";

double symbol_freqs[AL_SIZE] = {
	0.085786, 0.045676, 0.047306, 0.058022, 0.018036,
	0.037722, 0.059724, 0.081155, 0.021639, 0.052944,
	0.081156, 0.058717, 0.021109, 0.039946, 0.048178,
	0.063047, 0.060835, 0.014256, 0.036310, 0.068436
};


int ali_size=0, ali_len=0;

char   **alignment;
int    **aln_matrix, *num_seq; // number of sequences at given position
float  **subst_matrix;
double **profile_matrix, **distances, **pseudofreqs,
	**freqs, **n_eff, **probs, **similarities;

double *NEFF;

double   ZERO_NEFF = 0.0;
double   MAX_SIM = 18.0;
double   SIM_STEP = 0.5;
double   SIM_INIT = 2;
double   MAX_NEFF = 100.0;
double   pseudocount = 5;
int      use_sqrt_neff = 1;
double   lambda = 0.225;


//---------------------------------------------------------------------------

int main(int argc, char* argv[])
{

	int i, j;
	char profile_fname[50];

	if(argc!=3 && argc!=4) {
		printf("Usage: %s  aln_file matrix_file [out_file]\n", argv[0]);
		return 1;
	} // end if


	if(!read_aln_file(argv[1])) {
		printf("Error: can't read alignment from %s\n", argv[1]);
		return 1;
	} // end if

	if(!allocate_mem()) {
		printf("Error: can't alloc memory\n");
		return 1;
	} // end if

	if(!make_aln_matrix()) {
		printf("Error: can't make alignment matrix\n");
		return 1;
	} // end if

	calculateNumSeq();

	if(read_matr_file(argv[2])!=AL_SIZE*AL_SIZE) {
		printf("Error: can't read matrix from %s\n", argv[2]);
		return 1;
	} // end if

   calculateSimilarities();

   calculateNEff();

   calculateFreqs();

   calculateProbs();

	for (i=0; i<AL_SIZE; i++) {
		for (j=0; j<ali_len; j++) {
			profile_matrix[j][i] = PROBS?probs[j][i]:log(probs[j][i]/symbol_freqs[i]);
		} // end for
	} // end for

	if(argc==3) {
   	prepare_profile_fname(argv[1], profile_fname);
	} // end if
	else {
		strcpy(profile_fname, argv[3]);
	} // end else 

   if (!writeProfile(profile_fname)) {
		printf("Error: can't write profile to %s\n", profile_fname);
      return 1;
   }

	return NULL;

} // end main
//---------------------------------------------------------------------------
int getAlphabetSymbolIndex(char symbol)
{

	int i;

	for (i=0; i<AL_SIZE; i++)
		if (toupper(symbol)==alphabet[i])
			return i;

   return NA_AA;

} // end sub
//---------------------------------------------------------------------------
// Similarity = average num of different amino acids at positions
int calculateSimilarities(void)
{

	int *seqs_indices;

   int   seqs_count, length, index, posIndex, symbolIndex, symbols_count;
   double symbols_num;

	int pos_index, res_index, seq_index;


	if(!(seqs_indices=(int*)calloc(ali_size, sizeof(int)))) {
		printf("Error: calloc fail\n");
		return NULL;
	} // end if


   for (pos_index=0; pos_index<ali_len; pos_index++) {
	   for (res_index=0; res_index<AL_SIZE; res_index++) {

     // Prepare set of seqs with residue #res_index at position #pos_index
	   seqs_count = 0;
	   for (seq_index=0; seq_index<ali_size; seq_index++) {
   	   if (aln_matrix[pos_index][seq_index]==res_index) {
       		seqs_indices[seqs_count]=seq_index;
       		seqs_count++;
      	} // end if
     } // end for

     // Calc seqs_similarity
     if (seqs_count==0) {
	     similarities[pos_index][res_index] = 0;
     } // end if
     else if(seqs_count==1) {
	     similarities[pos_index][res_index] = 1;
     } // end else if
     else {

      symbols_num = 0;
      length = 0;

      for (posIndex=0; posIndex<ali_len; posIndex++) {

       	// Calc num of different a.a. at pos #posIndex
			symbols_count=0;
			for (symbolIndex=0; symbolIndex<AL_SIZE; symbolIndex++) {
				index = 0;
				while (index<seqs_count) {
					if (symbolIndex==aln_matrix[posIndex][seqs_indices[index]]) {
						symbols_count++;
						index = seqs_count;
					} // end if
					index++;
				} // end while
			} // end for

			if (symbols_count>0) {
				symbols_num += symbols_count;
				length++;
			} // end if

      } // end for


      if(length>0) {
      	similarities[pos_index][res_index] = symbols_num/length;
      } // end if
      else {
	      similarities[pos_index][res_index] = 0;
      } // end else

     } // end else

    } // end for res_index
   } // end for pos_index

   // Free the memory

   free(seqs_indices);

	return 1;

} // end calculateSimilarities(void)
//---------------------------------------------------------------------------
void calculateNEff(void)
{

   int posIndex, resIndex;

   for(posIndex=0; posIndex<ali_len; posIndex++) {
	   NEFF[posIndex] = 0;
    	for(resIndex=0; resIndex<AL_SIZE; resIndex++) {
     		n_eff[posIndex][resIndex] = getTableNEff(similarities[posIndex][resIndex]);
		   NEFF[posIndex] += n_eff[posIndex][resIndex];
    	} // end for
   } // end for

   for(posIndex=0; posIndex<ali_len; posIndex++) {
   	if (NEFF[posIndex]!=0) {
     		for(resIndex=0; resIndex<AL_SIZE; resIndex++) {
      		freqs[posIndex][resIndex]=n_eff[posIndex][resIndex]/NEFF[posIndex];
     		} // end for
    	} // end if
    	else {
     		for (resIndex=0; resIndex<AL_SIZE; resIndex++) {
      		freqs[posIndex][resIndex] = symbol_freqs[resIndex];
     		} // end for
    	} // end else
   } // end for

	return;

} // end calculateNEff()
//---------------------------------------------------------------------------
void calculateFreqs(void)
{

   int posIndex, resIndex, symbolIndex;

	for (resIndex=0; resIndex<AL_SIZE; resIndex++) {
		for (posIndex=0; posIndex<ali_len; posIndex++) {
			pseudofreqs[posIndex][resIndex] = 0;
			for (symbolIndex=0; symbolIndex<AL_SIZE; symbolIndex++) {
				pseudofreqs[posIndex][resIndex] += (freqs[posIndex][symbolIndex])
							*(exp(lambda*subst_matrix[resIndex][symbolIndex]));
			} // end for
			pseudofreqs[posIndex][resIndex] = (pseudofreqs[posIndex][resIndex])
				*(symbol_freqs[resIndex]);
		} // end for
	} // end for

	return;

} // end calculateFreqs(void)
//---------------------------------------------------------------------------
void calculateProbs(void)
{

   double new_pseudocount;

   int posIndex, resIndex;

	if (use_sqrt_neff) {
		for (resIndex=0; resIndex<AL_SIZE; resIndex++) {
			for (posIndex=0; posIndex<ali_len; posIndex++) {
				new_pseudocount = pseudocount*sqrt(NEFF[posIndex]);
				probs[posIndex][resIndex] = ((NEFF[posIndex]-1)*freqs[posIndex][resIndex]+new_pseudocount*pseudofreqs[posIndex][resIndex])/(NEFF[posIndex]-1.0+new_pseudocount);
			} // end for
		} // end for
	} // end if
	else {
		for (resIndex=0; resIndex<AL_SIZE; resIndex++) {
			for (posIndex=0; posIndex<ali_len; posIndex++) {
				probs[posIndex][resIndex] = ((NEFF[posIndex]-1)*freqs[posIndex][resIndex]+pseudocount*pseudofreqs[posIndex][resIndex])/(NEFF[posIndex]-1.0+pseudocount);
			} // end for
		} // end for
	} // end else

	return;

} // end calculateProbs(void)
//---------------------------------------------------------------------------
double getTableNEff(double similarity)
{

	double work_value, int_part;
	int    work_index;

	if (similarity<1.0) {
		if (similarity == 0.0) {
			return ZERO_NEFF;
		}
		else {
			return 1.0;
		}
	} // end if
	else {
		if (similarity<MAX_SIM) {
			work_value = (similarity/SIM_STEP)-SIM_INIT;
			work_index = floor(2*modf(work_value,&int_part))+floor(int_part);

			if( work_index<0 || work_index>NUM_NEFF-1 ) {
				printf("Error: invalid index %d\n", work_index);
				exit(1);
			} // end if

			return table_neff[work_index];
		} // end if
		else {
			return MAX_NEFF;
		} // end else
	} // end else

//	return NA_NEFF; // dummy value!

} // end getTableNEff()
//---------------------------------------------------------------------------
int writeProfile(char* fname)
{

	FILE *fp;
   int posIndex, symbolIndex;

   if( !(fp=fopen(fname, "w"))) {
      printf("Error: can't open %s\n", fname);
      return NULL;
   } // end if

	fprintf(fp, "File: %s  Length: %d  Sequences: %d\nPos ",
		fname, ali_len, ali_size);

   for (symbolIndex = 0; symbolIndex<AL_SIZE; symbolIndex++) {
		fprintf(fp, "%7c", alphabet[symbolIndex]);
   } // end for

	fprintf(fp, " NumSeq\n");

   for (posIndex=0; posIndex<ali_len; posIndex++) {

		fprintf(fp, "%04d", posIndex+1);

    	for (symbolIndex=0; symbolIndex<AL_SIZE; symbolIndex++) {
			fprintf(fp, " %+5.3f", profile_matrix[posIndex][symbolIndex]);
    	} // end for

		fprintf(fp, "   %3d\n", num_seq[posIndex]);

   } // end for

	fclose(fp);

   return 1;
} // end sub
//---------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////
/// it is assumed that every sequence
/// is preceded by 67-column description from BLAST
//////////////////////////////////////////////////////////////////
/// it would be great to rewrite this function so that it 
/// indicates when MAXSEQ* are excessed
//////////////////////////////////////////////////////////////////
int read_aln_file(char *fname)
{

	FILE   *fp;
	char   *s, *seq;
	int    i, tot=0;
	char   **pp;


   if( !(fp=fopen(fname, "r"))) {
      printf("Error: can't open %s\n", fname);
      return NULL;
   } // end if

	if(
			!(s=(char*)calloc(MAXSEQLEN+DESC_WIDTH, sizeof(char))) ||
			!(seq=(char*)calloc(MAXSEQLEN, sizeof(char)))
	) {
		printf("Error: string alloc fail\n");
		return NULL;
	} // end if

	if(!(pp=(char**)calloc(MAXSEQNUM, sizeof(char*)))) {
		printf("Error: array alloc fail\n");
		return NULL;
	} // end if


	if( !fgets(s, MAXSEQLEN, fp) || strstr(s, "CLUSTAL")!=s ) {
		printf("Error: file does not start with CLUSTAL\n");
		return NULL;
	} // end if

	i=0; // if not set to 0, crashes on files without spaceline preceding first block

	while( fgets(s, MAXSEQLEN, fp) ) {
		if(isspace(s[0]) || s[0]=='!' ) { // begins with whitespace
			i=0;
			continue;
		} // end if
		else {
			if(pp[i]==NULL) { // first block
				if(!(pp[i]=(char*)calloc(MAXSEQLEN, sizeof(char)))) {
					printf("Error: string alloc fail\n");
					return NULL;
				} // end if
				tot++;
			} // end if

			*seq = '\0';

///////	sscanf(s, "%*s%s", seq); //// old variant
			sscanf(s+DESC_WIDTH, "%s", seq);

			if(!strlen(seq)) {
				printf("Error: empty sequence lines\n");
				return NULL;				
			} // end if

			strcat(pp[i], seq);

			i++;

		} // end else
	} // end while

	fclose(fp);
	free(s);

	if(tot) {
		alignment = pp;
		ali_len = strlen(pp[0]); // dangerous if pp[i] not allocated
		ali_size = tot;
	} // end if

	return tot;

} // end read_param_file()
//--------------------------------------------------------------------
int make_aln_matrix(void)
{

	int i, j;

	if(!(aln_matrix=(int**)calloc(ali_len, sizeof(int*)))) {
		printf("Error: calloc fail\n");
		return NULL;
	} // end if

	for(i=0; i<ali_len; i++) {

		if(!(aln_matrix[i]=(int*)calloc(ali_size, sizeof(int)))) {
			printf("Error: calloc fail\n");
			return NULL;
		} // end if

		for(j=0; j<ali_size; j++) { // NB: i,j -> j,i
			aln_matrix[i][j]=getAlphabetSymbolIndex(alignment[j][i]);
		} // end if
	} // end for i<ali_len

	return 1;

} // end sub
//--------------------------------------------------------------------
int read_matr_file(char *fname)
{

	int i,j, tot=0;
	float **pp;
	FILE  *fp;

   if( !(fp=fopen(fname, "r"))) {
      printf("Error: can't open %s\n", fname);
      return NULL;
   } // end if

	if(!(pp=(float**)calloc(AL_SIZE, sizeof(float*)))) {
		printf("Error: matrix alloc fail\n");
		return NULL;
	} // end if


	for(i=0; i<AL_SIZE; i++) {
		if(!(pp[i]=(float*)calloc(AL_SIZE, sizeof(float)))) {
			printf("Error: matrix alloc fail\n");
			return NULL;
		} // end if

		for(j=0; j<AL_SIZE; j++) {
			tot +=  fscanf(fp, "%f", pp[i]+j);
		} // end for
	} // end for

	fclose(fp);
	subst_matrix=pp;
	return tot;

} // end sub()
//--------------------------------------------------------------------
int allocate_mem(void)
{

	int i;


	if(

		!(NEFF=(double*)calloc(ali_len, sizeof(double))) ||

		!(profile_matrix=(double**)calloc(ali_len, sizeof(double*))) ||
		!(similarities=(double**)calloc(ali_len, sizeof(double*))) ||
		!(distances=(double**)calloc(ali_len, sizeof(double*))) ||
		!(pseudofreqs=(double**)calloc(ali_len, sizeof(double*))) ||
		!(freqs=(double**)calloc(ali_len, sizeof(double*))) ||
		!(n_eff=(double**)calloc(ali_len, sizeof(double*))) ||
		!(num_seq=(int*)calloc(ali_len, sizeof(int))) ||
		!(probs=(double**)calloc(ali_len, sizeof(double*)))

	)
		return NULL;

	for(i=0; i<ali_len; i++) {
		if(

			!(similarities[i]=(double*)calloc(AL_SIZE, sizeof(double))) ||
			!(profile_matrix[i]=(double*)calloc(AL_SIZE, sizeof(double))) ||
			!(distances[i]=(double*)calloc(AL_SIZE, sizeof(double))) ||
			!(pseudofreqs[i]=(double*)calloc(AL_SIZE, sizeof(double))) ||
			!(freqs[i]=(double*)calloc(AL_SIZE, sizeof(double))) ||
			!(n_eff[i]=(double*)calloc(AL_SIZE, sizeof(double))) ||
			!(probs[i]=(double*)calloc(AL_SIZE, sizeof(double)))

		)
			return NULL;
	} // end for

	return 1;

} // end sub
//--------------------------------------------------------------------
void prepare_profile_fname(char *src, char *dst)
{

	char *dot;

	strcpy(dst, src);

	// removes last dot, to handle ./Directory/1234.prf  correctly
	if((dot=strrchr(dst, '.'))!=NULL)
		*dot = '\0';

	strcat(dst, ".prf");

	return;

} // end sub
//--------------------------------------------------------------------
void calculateNumSeq(void)
{

	int i,j, n;	

	for(i=0; i<ali_len; i++) {
		n=0;
		for(j=0; j<ali_size; j++) { // NB: i,j -> j,i
			if(aln_matrix[i][j]!=NA_AA) n++;
		} // end for
		num_seq[i]=n;
	} // end for i<ali_len

} // end sub
//--------------------------------------------------------------------
