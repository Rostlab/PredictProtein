/* Last update: 12/3/99  */
/* 
   With respect to Net.h
   2 new funcions are added, namely

   void G_printw(char C , char * filename);
   print the weight junctions in a file "filename"
   with the modality C ('A' for text, 'B' for binary mode) 
   void G_getw(char C , char * filename); 
   read the weight junctions from a file "filename"
   with the modality C ('A' for text, 'B' for binary mode) 

   The input definition DEFNET.NET now
   * has one more line that represent the binary (or ascii) mode 
   to write the weight file junction
   * has 2 more line that represent the dimension code DIMC and the windows (finestra)

 */

/*                    */
/*--- Definintions ---*/
/*                    */
/*  example 3 layer net
   here the prefix G_ is omitted 

   3   ------  o[3]  a[3]  N[3]  t[3]
   w[3]
   2   ------  o[2]  a[2]  N[2]  t[2]
   w[2]
   1   ------  o[1]  a[1]  N[1]  t[1]
   w[1]
   0   ------  o[0]  NULL  N[0]  NULL
   NULL
 */
/*=================================*/


/*=================================*/
/* Global variables   */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <math.h>

#define MAXL 6			/* maximun layer dimension */

int G_nl;			/* number of weight layers */
double G_initw;			/*flag or boundary of initialization weights */
int finestra;
int DIMC;
int OUT_scrittura ;
//char G_Netname[] = "NETDEF.NET";	/* file that contains the net definitions */
char G_Netname[50];	/* file that contains the net definitions */
/* ----- like 
   # network definition
   # leave the number in this order
   # any comment has to start with '#'
   #
   # number of weight layers
   5
   # neuron in the first neuron layer (input)
   1
   #neuron in the second neuron layer
   2
   #neuron in the second neuron layer
   3
   #neuron in the second neuron layer
   4
   #neuron in the second neuron layer
   5
   #neuron  in the 3th neuron layer (output)
   6
   # learning rate
   0.01
   # momentum    
   0.95
   # weight 0 = read input file 
   # a nubrer K !=0 (ex. K=0.001) to initialize random
   # the weights in the interval [-K,K]
   0.001
   # ascii(0)  Binary(1) version of weight file
   1
   #DIMCODE

   #FINESTRA
   #valori dei neuroni di output in uscita nel file 'scrittura'
   ---------------------------- END EXAMPLE */

int G_WriteBin = 1;

//char G_weightfile[] = "WEIGHT.BIN";
char G_weightfile[50];


double **G_w[MAXL + 1];		/* weights matrix */
		       /* it will be allocated by matdoub */
		       /* each elements G_w[i] -> the weight layer i
		          G_w[layer][raws][cols] */
double **G_dw[MAXL + 1];	/* matrix vector pointer to the derivative of G_w */

double *G_dE[MAXL + 1];		/* retropropagating errors */

double **G_Dw[MAXL + 1];	/* matrix vector pointer to weight variations */

int G_N[MAXL + 1];		/* vector of dimension of each layers */

double *G_a[MAXL + 1];		/* vec. pointer to local fields */

double *G_o[MAXL + 1];		/* vec. pointer to the neuron outputs */

double *G_od;			/*  pointer to the last (desired) output layer */

double *G_t[MAXL + 1];		/* vec. pointer to the tresholds */

double *G_Dt[MAXL + 1];		/* vec. pointer to the treshold back derivative */

double G_alpha = 0.01;		/* learning rate */

double G_beta = 0.95;		/* momentum term */

/*=========================================*/
/*              Declarations               */
/*--------- network global functions ------*/
/*=========================================*/

void G_initialize ();		/* it calls     G_read_net();
				   G_init_net();
				   G_init_weights();
				   G_writew();
				 */

void G_printw (char, char *);	/* print an ASCII or Binary Weight File */
void G_getw (char, char *);	/* read an ASCII or Binary Weight File */
void G_wasci (void);
void G_read_net (void);		/* read the net dimensions from the file
				   G_Netname[] */
void G_init_net (void);		/* set and allocate each pointer */
void G_init_weights (void);	/* set and allocate each pointer */
double **G_matdoub (int, int);	/*  allocate a  matrix of double */
double *G_vecdoub (int);	/*  allocate a  vector of double */
int *G_vecint (int);		/*  allocate a  vector of int */
double G_stepf (void);		/* step forward */
void G_gbp (void);		/*gradient backprop */
void G_conjgrad (void);		/*Conjugate gradient backprop */
void G_updatew (void);		/* update the network weights & thresholds */
double G_fun (double);		/*activation funcion */
double G_derf (double);		/* derivative of act. fun. */
void G_writew (void);		/* write weights in binary form */
void G_readw (void);		/* write weights in binary form */




/*=========================================*/
/*               Functions                 */
/*--------- network global functions ------*/
/*=========================================*/

/* --------     G_printw ------------ */
void 
G_printw (char c, char *file)
{
  char oldfile[80];
  int Flagp = G_WriteBin;

  sprintf (oldfile, "%s", G_weightfile);
  sprintf (G_weightfile, "%s", file);

  if (c == 'A')
    {
      G_WriteBin = 0;
    }
  else
    {
      G_WriteBin = 1;
    }
  /*G_wasci ();
     */ 
   G_writew();
  G_WriteBin = Flagp;
  sprintf (G_weightfile, "%s", oldfile);

}
/* --------End  G_printw ------------ */


/* --------     G_getw ------------ */
void 
G_getw (char c, char *file)
{
  char oldfile[80];
  int Flagp = G_WriteBin;

  sprintf (oldfile, "%s", G_weightfile);
  sprintf (G_weightfile, "%s", file);

  if (c == 'A')
    {
      G_WriteBin = 0;
    }
  else
    {
      G_WriteBin = 1;
    }

  G_readw ();

  G_WriteBin = Flagp;
  sprintf (G_weightfile, "%s", oldfile);

}
/* --------End  G_getw ------------ */




/* --------     G_writew ------------ */
void 
G_writew (void)
{
  FILE *fp;
  int s, i, j;


  if (G_WriteBin)
    {
      if ((fp = fopen (G_weightfile, "wb")) == NULL)
	{
	  printf ("Can't open %s\n", G_weightfile);
	  exit (-1);
	}

      for (s = 1; s <= G_nl; s++)
	{
	  fwrite (G_t[s], sizeof (double), G_N[s], fp);
	  for (j = 0; j < G_N[s]; j++)
	    {
	      fwrite (G_w[s][j], sizeof (double), G_N[s - 1], fp);
	    }
	}
      fclose (fp);
    }
  else
    {
      if ((fp = fopen (G_weightfile, "wt")) == NULL)
	{
	  printf ("Can't open %s\n", G_weightfile);
	  exit (-1);
	}
      for (s = 1; s <= G_nl; s++)
	{
	  for (i = 0; i < G_N[s]; i++)
	    {
	      fprintf (fp, "%lf\n", G_t[s][i]);
	      for (j = 0; j < G_N[s - 1]; j++)
		{
		  fprintf (fp, "%lf ", G_w[s][i][j]);
		}
	      fprintf (fp, "\n");
	    }
	}
      fclose (fp);
    }

}
/* --------End  G_writew ------------ */

void 
G_wasci (void)
{
  FILE *fp;
  int j, i, k = 0, s,n = 0 ;
  if ((fp = fopen (G_weightfile, "wt")) == NULL)
    {
      printf ("Can't open %s\n", G_weightfile);
      exit (-1);
    }
   fprintf (fp, "VLIMFWYGAPSTCHRKQEND0 + idrofob + carica + WE\n");
 
for (s = 1; s <= G_nl; s++)
    {
      for (i = 0; i < G_N[s]; i++)
	{
      fprintf (fp, "############SS %i \n", i);
	      fprintf (fp, "%f\n", G_t[s][i]);
	  for (j = 0; j < G_N[s - 1]; j++)
	    {
	      fprintf (fp, "%f ", G_w[s][i][j]);
	          k++; 
	          if(k == DIMC){
	                n++; 
                     	fprintf(fp,"\n posizione %i\n",n );
 			k = 0;
			} 
             }
	  fprintf (fp, "\n");
	}
      fclose (fp);
    }
}

/* --------     G_readw ------------ */
  void G_readw (void)
  {
    FILE *fp;
    int s, i, j;
    int TR = 1;
      /*if(TR)*/ 

    if (G_WriteBin)
{
	if ((fp = fopen (G_weightfile, "rb")) == NULL)
	  {
	    printf ("Can't open %s\n", G_weightfile);
	    exit (-1);
	  }
	for (s = 1; s <= G_nl; s++)
	  {
	    fread (G_t[s], sizeof (double), G_N[s], fp);
	    for (j = 0; j < G_N[s]; j++)
	      {
		fread (G_w[s][j], sizeof (double), G_N[s - 1], fp);
	      }
	  }
	fclose (fp);
      }
    else
      {
	if ((fp = fopen (G_weightfile, "rt")) == NULL)
	  {
	    printf ("Can't open %s\n", G_weightfile);
	    exit (-1);
	  }
	for (s = 1; s <= G_nl; s++)
	  {
	    for (i = 0; i < G_N[s]; i++)
	      {
		fscanf (fp, "%lf", &G_t[s][i]);
		for (j = 0; j < G_N[s - 1]; j++)
		  {
		    fscanf (fp, "%lf", &G_w[s][i][j]);
		  }
	      }
	  }
	fclose (fp);
      }
  }
/* --------End  G_readw ------------ */



/* --------     G_read_net ------------ */

  void G_read_net ()
  {
    FILE *fp;
    char flag = 0;
    int i;

    int maxlen = 150;		/*maxline and buffer string stin */
    char stin[150];

    if ((fp = fopen (G_Netname, "rt")) == NULL)
      {
	printf ("Can't open %s\n", G_Netname);
	exit (-1);
      }
    i = 0;
/*   while((fgets(stin,maxlen,fp)!=NULL)) */
    while (!feof (fp))
      {
	fgets (stin, maxlen, fp);
	if ((strchr (stin, '#') == NULL))
	  {
	    switch (flag)
	      {
	      case 0:
		G_nl = atoi (stin);
		flag = 1;
		break;
	      case 1:
		{
		  G_N[i] = atoi (stin);
		  i++;
		  if (i == (G_nl + 1))
		    {
		      flag = 2;
		    }
		  break;
		}
	      case 2:
		G_alpha = (double) atof (stin);
		flag = 3;
		break;
	      case 3:
		G_beta = (double) atof (stin);
		flag = 4;
		break;
	      case 4:
		G_initw = (double) atof (stin);
		flag = 5;
		break;
	      case 5:
		G_WriteBin = (int) atoi (stin);
		flag = 6;
		break;
	      case 6:
		DIMC = atoi (stin);
		flag = 7;
		break;
	      case 7:
		finestra = atoi (stin);
		flag = 8;
		break;
	      case 8:
		OUT_scrittura = atoi (stin);
		flag = 9;
		break;

	      default:
		break;
	      }
	  }
      }
    fclose (fp);
    return;
  }
/* --------End  G_read_net ------------ */


/* --------     G_init_weights ------------ */
  void G_init_weights ()
  {
    int s, i, j;

      srand (1);

    if (G_initw)
      {				/*initialize random */
	for (s = 1; s <= G_nl; s++)
	  {
	    for (i = 0; i < G_N[s]; i++)
	      {
		G_t[s][i] = ((double) (RAND_MAX / 2.0 - rand ()) / RAND_MAX) * G_initw;
		for (j = 0; j < G_N[s - 1]; j++)
		  {
		    G_w[s][i][j] = ((double) (RAND_MAX / 2.0 - rand ()) / RAND_MAX) * G_initw;
		  }
	      }
	  }
      }
    else
      {				/* read old weights */
	G_readw ();
      }
    /*initialze all others */
    for (s = 1; s <= G_nl; s++)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    G_dE[s][i] = 0.0;	/* back-error */
	    G_Dt[s][i] = 0.0;	/* threshold error */
	    for (j = 0; j < G_N[s - 1]; j++)
	      {
		G_dw[s][i][j] = 0.0;	/* back-derivative */
		G_Dw[s][i][j] = 0.0;	/* weight error */
	      }
	  }
      }
    return;
  }
/* --------End   G_init_weights ------------ */

/* --------     G_init_net ------------ */
  void G_init_net ()
  {
    int i;

    if (G_nl > MAXL)
      {
	printf ("Error: net too large (maxlayer = %d)\n", MAXL);
	exit (-1);
      }

    for (i = 1; i <= G_nl; i++)
      {
	G_w[i] = G_matdoub (G_N[i], G_N[i - 1]);
	G_dw[i] = G_matdoub (G_N[i], G_N[i - 1]);
	G_Dw[i] = G_matdoub (G_N[i], G_N[i - 1]);
	G_dE[i] = G_vecdoub (G_N[i]);
	G_a[i] = G_vecdoub (G_N[i]);
	G_o[i] = G_vecdoub (G_N[i]);
	G_t[i] = G_vecdoub (G_N[i]);
	G_Dt[i] = G_vecdoub (G_N[i]);
      }
    G_o[0] = G_vecdoub (G_N[0]);
    if ((G_od = (double *) malloc (G_N[G_nl] * sizeof (double))) == NULL)
      {
	printf ("Malloc error \n");
	exit (-1);
      }
    return;
  }
/* --------End  G_init_net ------------ */



/* --------     G_matdoub ------------ */
  double **G_matdoub (int raws, int cols)
  {
    int i;
    double **m;

    if ((m = (double **) malloc (raws * sizeof (double *))) == NULL)
      {
	printf (" ERROR allocation matrix (raws)  \n");
	exit (-1);
      }
    for (i = 0; i < raws; i++)
      {
	if ((m[i] = (double *) malloc (cols * sizeof (double))) == NULL)
	  {
	    printf (" ERROR allocation matrix (cols)\n");
	    exit (-1);
	  }
      }
    return (m);
  }
/* -------- End G_matdoub ------------ */


/* --------     G_vecdoub ------------ */
  double *G_vecdoub (int raws)
  {
    double *m;

    if ((m = (double *) malloc (raws * sizeof (double))) == NULL)
      {
	printf (" ERROR allocation vector \n");
	exit (-1);
      }
    return (m);
  }
/* -------- End G_vecdoub ------------ */


/* --------     G_vecint ------------ */
  int *G_vecdint (int raws)
  {
    int *m;

    if ((m = (int *) malloc (raws * sizeof (int))) == NULL)
      {
	printf (" ERROR allocation vector(int) \n");
	exit (-1);
      }
    return (m);
  }
/* -------- End G_vecdoub ------------ */



/* --------     G_stepf ------------ */
/* */
  double G_stepf ()
  {
    int s, i, j;
    double etmp;
    double error = 0;

    for (s = 1; s <= G_nl; s++)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    G_a[s][i] = G_t[s][i];	/* sum threshold */
	    for (j = 0; j < G_N[s - 1]; j++)
	      {			/* weight sum */
		G_a[s][i] += G_w[s][i][j] * G_o[s - 1][j];
	      }
	    G_o[s][i] = G_fun (G_a[s][i]);
	  }
      }
    for (i = 0; i < G_N[G_nl]; i++)
      {
	etmp = G_o[G_nl][i] - G_od[i];
	error += etmp * etmp;
      }
    return (error);
  }
/* --------End  G_stepf ------------ */


/* --------     G_gbp ------------ */
  void G_gbp (void)
  {
    int i, s, j;


/* COMPUTE the back Errors  */
    /*last layer (output) */
    for (i = 0; i < G_N[G_nl]; i++)
      {
	G_dE[G_nl][i] = 2 * (G_o[G_nl][i] - G_od[i]) * G_derf (G_a[G_nl][i]);
      }

    /*other layers */
    for (s = G_nl - 1; s >= 1; s--)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    G_dE[s][i] = 0.0;
	    for (j = 0; j < G_N[s + 1]; j++)
	      {
		G_dE[s][i] += G_dE[s + 1][j] * G_w[s + 1][j][i] * G_derf (G_a[s][i]);
	      }
	  }
      }
/* END :COMPUTE the back Errors  */

/* COMPUTE the back derivatives G_Dw and G_Dt */
    for (s = 1; s <= G_nl; s++)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    G_Dt[s][i] = G_alpha * G_dE[s][i] - G_beta * G_Dt[s][i];
	    for (j = 0; j < G_N[s - 1]; j++)
	      {
		/*G_beta=(G_dE[s][i]*G_o[s-1][j])^2/(G_dw[s][i][j])^2 */
		G_dw[s][i][j] = G_dE[s][i] * G_o[s - 1][j];
		G_Dw[s][i][j] = G_alpha * G_dw[s][i][j] - G_beta * G_Dw[s][i][j];
	      }
	  }
      }
/* END :COMPUTE the back derivatives G_Dw and G_Dt */
    return;
  }
/* --------End  G_gbp ------------ */


/* --------     G_conjgrad ------------ */
  void G_conjgrad (void)
  {
    int i, s, j;
    double tmp;


/* COMPUTE the back Errors  */
    /*last layer (output) */
    for (i = 0; i < G_N[G_nl]; i++)
      {
	G_dE[G_nl][i] = 2 * (G_o[G_nl][i] - G_od[i]) * G_derf (G_a[G_nl][i]);
      }

    /*other layers */
    for (s = G_nl - 1; s >= 1; s--)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    G_dE[s][i] = 0.0;
	    for (j = 0; j < G_N[s + 1]; j++)
	      {
		G_dE[s][i] += G_dE[s + 1][j] * G_w[s + 1][j][i] * G_derf (G_a[s][i]);
	      }
	  }
      }
/* END :COMPUTE the back Errors  */

/* COMPUTE the back derivatives G_Dw and G_Dt */
    for (s = 1; s <= G_nl; s++)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    tmp = G_Dt[s][i];
	    if (tmp)
	      {
		G_beta = ((G_dE[s][i]) * (G_dE[s][i])) / (tmp * tmp);
	      }
	    else
	      {
		G_beta = 0.95;
	      }
	    G_Dt[s][i] = G_alpha * G_dE[s][i] - G_beta * G_Dt[s][i];
	    for (j = 0; j < G_N[s - 1]; j++)
	      {
		/*G_beta=(G_dE[s][i]*G_o[s-1][j])^2/(G_dw[s][i][j])^2 */
		tmp = G_dw[s][i][j];
		if (tmp)
		  {
		    G_beta = ((G_dE[s][i] * G_o[s - 1][j]) * (G_dE[s][i] * G_o[s - 1][j]))
		      / (tmp * tmp);
		  }
		else
		  {
		    G_beta = 0.95;
		  }
		G_dw[s][i][j] = G_dE[s][i] * G_o[s - 1][j];
		G_Dw[s][i][j] = G_alpha * G_dw[s][i][j] - G_beta * G_Dw[s][i][j];
	      }
	  }
      }
/* END :COMPUTE the back derivatives G_Dw and G_Dt */
    return;
  }
/* --------End  G_conjgrad ------------ */


/* --------     G_updatew ------------ */
/* printf("G_Dt[%d][%d] =%f \n",s,i,(float)G_Dt[s][i]);
   printf("G_Dw[%d][%d][%d] =%f \n",s,i,j,(float)G_Dt[s][i]);
 */
  void G_updatew ()
  {
    int s, i, j;

    for (s = 1; s <= G_nl; s++)
      {
	for (i = 0; i < G_N[s]; i++)
	  {
	    G_t[s][i] -= G_Dt[s][i];
	    for (j = 0; j < G_N[s - 1]; j++)
	      {
		G_w[s][i][j] -= G_Dw[s][i][j];
	      }
	  }
      }
    return;
  }
/* --------End  G_updatew ------------ */

/* --------     G_fun ------------ */
  double G_fun (double a)
  {
    return (1 / (1 + exp (-a)));
  }
/* --------End  G_fun ------------ */



/* --------     G_derf ------------ */
  double G_derf (double a)
  {
    double tmp;
      tmp = 1 / (1 + exp (-a));
      return (tmp * (1 - tmp));
  }
/* --------End  G_derf ------------ */


/* --------     G_initialize --------- */
  void G_initialize ()
  {
    G_read_net ();
    G_init_net ();
    G_init_weights ();
    G_writew ();
    return;
  }
/* --------End  G_initialize --------- */
