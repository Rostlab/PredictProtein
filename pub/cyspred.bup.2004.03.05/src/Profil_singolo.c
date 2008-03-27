/*
   #############################################################

   IL PROGRAMMA COSTRUISCE IL FILE DI INPUT DELLA RETE 
   DAL FILE HSSP,

   OPZIONI:

   EXE <file_input>  <output_binario> finestra  E  IDROF CARIC  W
   itb3_                                ATTIVO    1    1    1   1
   (nome.hssp)                          disattivo 0    0    0   0
   _ o catena

   #############################################################
 */

#define ZERO  '0'
#define FIN  20
#define DIMCOD 21
#define INI 7  /* colonna del file hssp da cui viene ricavato il numero del residuo 8=N. pdb,  2 =N. seq */ 
#define MAX(a,b)  (a)>(b)?(a):(b)
#define PONTI 150
#define NCYS 150
#include <math.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include "profil_singolo.h"
void opNspi (char *);
void opfhssp (char *);
void inizializza (int);
int iniziolett (void);
int
  prova (int, char);
int
  carica (char *, int *);
int
  scrittura (int);
int
  riempi (void);
char amm[DIMCOD] = "VLIMFWYGAPSTCHRKQEND0";
float polarity[DIMCOD] =
{0.86, 0.85, 0.88, 0.85, 0.88, 0.85, 0.76, 0.72, 0.74, 0.64, 0.66, 0.7, 0.91, 0.78, 0.64, 0.52, 0.62, 0.62, 0.63, 0.62, 0};
float chimico[DIMCOD] =
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, -1, 0, -1, 0};

char chain;
int ponti, cys, a1[PONTI], a2[PONTI], a3[NCYS], conto[NCYS];
float mentr[FIN], mwhei[FIN];
double cvect[FIN][DIMCOD];	/*  ATTENZIONE le matrici sono sovrastimate vanno utilizzate solo DIMCOD-1 componenti */
double hvect[FIN][DIMCOD];
double mvect[FIN][DIMCOD];
double entvect[FIN], weivect[FIN];
int finestra;
int CON0 = 10, CON1 = 10, CON2 = 10, CON3 = 10;
FILE *filwrt, *filhssp;
char file_name[250];
char file_name_hssp[250];
main (int argc, char *argv[])
{
  int totale = 0, TSH = 0, TSS = 0, j, k, As, Bs, Cs, Ds, SS = 0, SH = 1;
  char lista[250], passo[5], nome[5], nomeC[6];
  char binario[45];
  if (argc < 6)
    {
      printf ("#################\n");
      printf ("il programma richiede in input i seguenti argomenti\n");
      printf ("Profil <file_input> <file_output> finestra Entropy idrofobicita carica Weight  '\n");
      printf ("################\n");
      exit (-1);
    }
  finestra = atoi (argv[3]); /* finestra */
  CON1 = atoi (argv[4]);   /* entropy */
  CON2 = atoi (argv[5]);   /* idrofobicita' */
  CON3 = atoi (argv[6]);   /* carica */
  CON0 = atoi (argv[7]);   /* weight */

  sprintf (binario, "%s", argv[2]);
  if ((filwrt = fopen (binario, "wb")) == NULL)
    {
      printf ("non apre file di scrittura %s\n", binario);
      exit (1);
    }
  strncpy (passo, argv[1], 5);
  strcpy (file_name, argv[1]);
  strcpy (file_name_hssp, argv[8]);
  sprintf (nomeC, "%s", passo);
  sprintf (nome, "%s", passo);
  nome[4] = '\0';
  nomeC[5] = '\0';
  printf ("nome %s, nomeC %s argv %s file_name_hssp %s\n", nome, nomeC, argv[1], file_name_hssp);
  //  exit (1);
  
  opNspi (nomeC);
  opfhssp (file_name_hssp);
  // opfhssp (nome);
  TSH += cys;
  totale += ponti + ponti + cys;
  for (j = 0; j < ponti; j++)
    {
      /*  tutto a1 */
      inizializza (ponti);
      As = iniziolett ();
      Bs = prova (a1[j], chain);
      Cs = riempi ();
      Ds = scrittura (SS);
    }
  for (j = 0; j < ponti; j++)
    {
      /*  tutto a2r */
      inizializza (ponti);
      As = iniziolett ();
      Bs = prova (a2[j], chain);
      Cs = riempi ();
      Ds = scrittura (SS);
    }
  for (j = 0; j < cys; j++)
    {
      /*  tutto a1 */
      inizializza (cys);
      As = iniziolett ();
      Bs = prova (a3[j], chain);
      Cs = riempi ();
      Ds = scrittura (SH);
    }
  fclose (filhssp);
  printf ("totale CYS %i\n", TSH);
  printf ("totale PONTI %i\n", SS);
  printf ("totale  %i\n", totale);
  fclose (filwrt);
}

void
opNspi (char *nome_prot)
{
  int k;
  FILE *filsp;
  char tmp[125], prot[5], CHAIN;

  for (k = 0; k < 5; k++)
    {
      prot[k] = nome_prot[k];
    }

  //  sprintf(file_name,"%s",argv[1]);
  //   sprintf (file_name, "%s%c%c%c%c%c.Nspi", direttorio, prot[0], prot[1], prot[2], prot[3], prot[4]);
  //  printf("%s\n",direttorio);
  //printf ("%s\n",file_name);

  if ((filsp = fopen (file_name, "rt")) == NULL)
    {
      printf ("Can't open  il file di input %s\n", file_name);
      exit (-1);
    }

  fgets (tmp, 125, filsp);
  //  printf("tmp is : %s\n",tmp);

  fscanf (filsp, "%c\t%i\n", &CHAIN, &ponti);

  chain = CHAIN;
  for (k = 0; k < ponti; k++)
    {
      fscanf (filsp, "%c\t%i\t%i\n", &CHAIN, &a1[k], &a2[k]);
	  //      printf ("a1 %i a2 %i\n", a1[k], a2[k]);
	  
    }
  fgets (tmp, 125, filsp);
  fscanf (filsp, "%i\n", &cys);
  printf("cys %i\n", cys); 
  for (k = 0; k < cys; k++)
    {
      fscanf (filsp, "%c\t%i\n", &CHAIN, &a3[k]);
	  //	  printf ("a3 %i\n", a3[k]);
      
    }
  fclose (filsp);
  return;
}


void
opfhssp (char *prot)
{
  //  char file_name[60];
  //  sprintf(file_name,"%s",argv[1]);
  ////sprintf (file_name, "%s%c%c%c%c.hssp", direttorio, prot[0], prot[1], prot[2], prot[3], prot[4]);
  //  sprintf (file_name, "%s", prot);
  //  printf ("file name is %s\n", file_name_hssp);
  printf("%s\n",file_name_hssp);
  if ((filhssp = fopen (file_name_hssp, "rt")) == NULL)
    {
      printf ("Can't open hssp il file di input\n");
      exit (-1);
    }
  return;
}

void
inizializza (int key)
{
  int j, m, n;
  for (m = 0; m < finestra; m++)
    {
      for (n = 0; n < DIMCOD; n++)
	{
	  cvect[m][n] = 0.0;
	  mvect[m][n] = 0.0;
	  hvect[m][n] = 0.0;
	}
      conto[m] = 0;
    }
  for (m = 0; m < finestra; m++)
    {
      entvect[m] = 0.0;
      weivect[m] = 0.0;
    }

  return;
}

int
iniziolett ()
{
  int alti, allconto = 1;
  char temp[230], inizio[34] = "## SEQUENCE PROFILE AND ENTROPY", *aort;
  char inibi[20] = "## PROTEINS : EMBL", *iort;
  rewind (filhssp);
  /*  
     ##########  da utilizzare solo con file hssp veri e propri 
     per avere il numero di proteine allineate  'allconto' 
    do
     {
     fgets (temp, 230, filhssp);
     iort = strstr (temp, inibi);
     }
     while (iort == NULL);
     fgets (temp, 230, filhssp);
     fgets (temp, 230, filhssp);
     do
     {
     allconto++;
     alti = temp[0] - '#';
     fgets (temp, 230, filhssp);
     ###########        nomi delle   allineate 
     }
     while (alti != 0);
   */
  fgets (temp, 230, filhssp);
  do
    {
      fgets (temp, 230, filhssp);
      aort = strstr (temp, inizio);
    }
  while (aort == NULL);
  fgets (temp, 230, filhssp);
  return (allconto);
}

int
prova (int a12, char chain)
{
  char temp1[220], chsp, convert[5];
  int residuo, shift, eci, ecik, fin, ifi;
  int ni, indiceriga, indice, fin2;
  float indiceF;
  fin2 = (finestra - 1) / 2;
  fgets (temp1, 220, filhssp);
  strncpy (&convert[0], &temp1[INI], 4);
  residuo = atoi (convert);
  do
    {
      strncpy (&convert[0], &temp1[INI], 4);
      residuo = atoi (convert);
      chsp = temp1[11];
      if ((!(eci = '_' - chain)) || (!(ecik = chain - chsp)))
	{
	  indice = (int) (fabs ((float) (residuo - a12)));
	  if (indice <= fin2)
	    {
	      shift = fin2 - a12;
	      indiceriga = residuo + shift;
	      ni = carica (&temp1[0], &indiceriga);
	    }
	}
      fgets (temp1, 220, filhssp);
      fin = temp1[0] - '#';
      ifi = temp1[0] - '/';
    }
  while (fin && ifi);
  return (1);
}

int
carica (char *ptemp, int *indi)
{
  int nall, indice, i, k, j;
  double entropy, wheight;
  float vect[20];
  int ni;
  float mentropy[DIMCOD];
  char convert[4], conv[6], temp[220];
  indice = *indi;
  for (j = 0; j < DIMCOD - 1; j++)
    {
      vect[j] = 0.0;
    }
  for (j = 0; j < DIMCOD - 1; j++)
    {
      strncpy (&convert[0], &ptemp[13 + (4 * j)], 4);
      vect[j] = atof (convert);
      /*     printf("%.1f ", vect[j]); 
       */ if (vect[j] != 0)
	{
	  mvect[indice][j] += (double) (vect[j]);
	  /*###########
		     carica e idrofobicita' 
		     non pesate 
	     cvect[indice][j] = (double) (polarity[j]*100);
	     hvect[indice][j] = (double) (chimico[j]*100);
	  ########## */

	  /*###########
	     carica e idrofobicita' 
	     pesate 
	  ########## */
	  cvect[indice][j] = (double) (polarity[j] * vect[j]);
	  hvect[indice][j] = (double) (chimico[j] * vect[j]);
	}
    }
  strncpy (&convert[0], &ptemp[120], 4);
  entropy = atof (convert);
  strncpy (&convert[0], &ptemp[125], 4);
  wheight = atof (convert);
  entvect[indice] = (float) entropy;
  weivect[indice] = (float) (wheight * 100);
/*      printf("%s\n",ptemp);
   printf("entropy %f\n", entvect[indice] );
   printf("wheight %f\n", weivect[indice]);
 */
  /*  attivare se si vuole la statistica sul: 
     RELENT             strncpy(&convert[0], &ptemp[120],4);
     entropy            strncpy(&convert[0], &ptemp[111],4);
     WEIGHT             strncpy(&convert[0], &ptemp[125],4);
   */
/*
   for (j = 0; j < DIMCOD - 1; j++)
   {
   printf ("%i  ", vect[j]);
   }
   printf("\n");
 */
  conto[indice]++;
  return (1);
}

int
riempi (void)
{
  int pio, fin2;
  int contobuco = 1;
  fin2 = (finestra - 1) / 2;
  for (pio = 0; pio < fin2; pio++)
    {
      if ((conto[pio] == 0) && (contobuco))
	{

	  mvect[pio][DIMCOD - 1] = 100.0;
	  contobuco++;
	}
      else
	{
	  contobuco = 0;
	}
    }
  contobuco = 1;
  for (pio = finestra; pio > fin2; pio--)
    {
      if ((conto[pio] == 0) && (contobuco))
	{
	  mvect[pio][DIMCOD - 1] = 100.0;
	  contobuco++;
	}
      else
	{
	  contobuco = 0;
	}
    }
  return (1);
}

int
scrittura (int odsc)
{
  double *convert;
  int car[2];
  int inx[DIMCOD], inc[DIMCOD], inh[DIMCOD], inw[2], od[2];
  int i, j, k;

  /* attivare per avere scrittura su video   scrittura su video  */
   /*

   for (k = 0; k < DIMCOD; k++)
   {
   printf ("%c\t", amm[k]);
   for (i = 0; i < finestra; i++)
   {
   printf ("%.1f\t", mvect[i][k]);
   }
   printf ("\n");
   }
   printf (" profilo ####################\n");
   scanf("%*c");
   for (k = 0; k < DIMCOD; k++)
   {
   printf ("%c\t", amm[k]);
   for (i = 0; i < finestra; i++)
   {
   printf ("%.1f\t",  cvect[i][k]);
   }
   printf ("\n");
   }
   printf (" idrofobicita' ####################\n");
   for (k = 0; k < DIMCOD; k++)
   {
   printf ("%c\t", amm[k]);
   for (i = 0; i < finestra; i++)
   {
   printf("%.1f\t", hvect[i][k]);
   }
   printf ("\n");
   }       
   printf (" carica ####################\n");
   scanf("%*c");
 */

/*scrittura sul file binario */
  for (i = 0; i < finestra; i++)
    {
      car[0] = 0;
      car[1] = 0;
      for (k = 0; k < DIMCOD; k++)
	{
	  inx[k] = (int) mvect[i][k];	/* profilo */
	  inc[k] = (int) cvect[i][k];	/* idrofobicita' */
	  inh[k] = (int) hvect[i][k];	/* carica  */
	}
      for (k = 0; k < DIMCOD; k++)
	{
	  if (hvect[i][k] == 0)
	    car[0] = 0;
	  if (hvect[i][k] > 0)
	    car[1] += hvect[i][k];
	  if (hvect[i][k] < 0)
	    car[0] += hvect[i][k];
	}
      fwrite (inx, sizeof (int), DIMCOD, filwrt);

      if (CON2 == 1)
	{
	  fwrite (inc, sizeof (int), DIMCOD, filwrt);
	}
      if (CON3 == 1)
	{
	  fwrite (car, sizeof (int), 2, filwrt);
	}

      inw[0] = (int) entvect[i];
      inw[1] = (int) weivect[i];
      if (CON1 == 1)
	{
	  fwrite (&inw[0], sizeof (int), 1, filwrt);
	}
      if (CON0 == 1)
	{
	  fwrite (&inw[1], sizeof (int), 1, filwrt);
	}

    }
  /*
     printf ("informazioni in input alla rete \n");
     printf ("####      profilo di allineamento\n");
     if (CON1 == 1)
     printf ("####       relent\n");
     if (CON0 == 1)
     printf ("####      peso di conservazione \n");
     if (CON2 == 1)
     printf ("####      matrice di idrofobicita'\n");
     if (CON3 == 1)
     {
     printf ("####      carica indicata con due neuroni \n");
     printf ("  neutro 0 0 , negetivo -1 0 , positivo * 1\n");
     }
   */

  if (odsc == 1)
    {
      od[0] = 0.0;
      od[1] = 1.0;
    }
  if (odsc == 0)
    {
      od[0] = 1.0;
      od[1] = 0.0;
    }
  fwrite (od, sizeof (int), 2, filwrt);
  return (1);
}
