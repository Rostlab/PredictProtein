#include "Uni2.h"

#define WINDOW           10	/* ...Dimensione della finestra di lettura:
				 * Nø di lettere alla sinistra + Nø di quelle
				 * a destra del carattere da indovinare ... */
#define PRESPOT          5	/* ...l'indice dell'ultima lettera prima di
			 quello da indovinare ( SPOT centrale ) ... */

#define NUMSCIFT         6	/* ..Numero di volte che si deve shiftare a
				 * sini_ stra , di una lettera quando viene
				 * incontrata nella lettura la fine della
				 * stringa .. */

#define DIMCOD 60	
#define FIN 25
#define  MODULO(x)   ( ( (x)>= 0 )?(x):-(x) )
#define MAX(a,b)  (a)>(b)?(a):(b)
#define  TRUE        1
/*#define  MAXCOUNT   1000*/ 
#define  MAXCOUNT   1000 
#define  PREC        0.0005

#define NS           2

#define Nout            G_N[G_nl]	/* ... Numero dei nodi dell' OUTPUT
					 * layer ... */
#define Nin             G_N[0]	/* ... Numero dei nodi dell'INPUT layer ... */
#define xout            G_o[G_nl]	/* ... associate xout to the outpult
					 * layer */
#define xin             G_o[0]	/* .. associate xin to the input layer */
/* ........................Variabili Globali................................. */

char            fpesi[] = "frecw.dat";	/* ..nome del file in cui si
					 * registrano i pesi elaborati .. */
  /*int     prob[] = {10,5};*//* ..prob. di accettazione GBP per
				 * struttura.. */

float soglia=0.0;
int prob[] = {100,80};
double          numgbp[] = {0.0, 0.0, 0.0};	/* .. numero GBP per
				 * struttura .. */

int             fl_ctot = 0;	/* 1  flag di update dei pesi */

double          p[NS], n[NS], o[NS], ptot[NS], ntot[NS], otot[NS];

/*
 * double newres[DIMCOD]; 
 *//* ...contiene il codice dell'ultimo residuo letto.. */

/*
 * double dummyy[DIMCOD]; 
 *//* ..vettore contenente solo zeri da associare al bor_ do della finestra
 * agli estremi della sequenza .. */

char            strut[NS] = "SC";
double          q7ave[NS];
double          q7brut[NS];

FILE           *fp_prot;	/* ..puntat. al file della lista delle proteine */
FILE           *fp_res;				 
FILE           *fp_strcod;	/* ...puntatore al file degli amminoacidi
				 * codificati.. */
/* FILE * fp_dout     ; *//* ...puntat. al file degli outputs desiderati ... */


char            protfile[35] = "trainbox.p_";	/* .nome del file lista delle
						 * proteine. */
char            strcod[15] = "strcod.dat";	/* ..nome del file dei
						 * residui da leggere */
char            filedout[15] = "filedout.dat";	/* ..nome del file degli
						 * outputs desiderati . */

char		fil_ab_out[35] = "fil-pes_ab.dat";




/* ...........................funzioni usate................................. */
void
caricamento(void);
void
creafile(char *);
/*
 * int inizializza(void); int iniz(void); void asscod(double  *,int,double
 * *); int assdoutcod(void); void newxin(double *); 
 */
int
train(void);
double
test(void);
int
testprec(void);
int
chiudifile(void);
double
q7(double, double, double, double);
int trema;
int conto(void);
char output[45];
/* 
 * =================================MAIN====================================== */
main(int argc, char *argv[])
 {
   FILE *p_scri;
   double          err = 0.0, olderr = 100.0;
   double          ntmp, utmp;
   double          ntot_aa = 0;
   double          mediaprec = 0.0;
   int             count, numprot, i,Nprot=0,idde;
   int             maxcount = MAXCOUNT;
   int           pio, j, r1 ,inno;
   int             punt;	/* segnala la fine del file rb  */
   double          r2;
   char            nomef[15];
   int  optemp[2],temp[DIMCOD];
   char            scrittura_nome[35];
   char            id[35];
   scrittura_nome[0] = '\0';
   strcat ( scrittura_nome,"scrittura" );
   printf ("%d\n",argc);
   //   return 0;
   switch (argc) {
	 //   case 3:
	 // fl_ctot = atoi(argv[2]);
   case 2:
	 maxcount = atoi(argv[1]);
   case 5:
	 maxcount = atoi(argv[1]);
	 strcpy (id, argv[2]);
	 if (strcat(protfile,id)== NULL){
	   printf("non posso strcat id a protfile\n");
	   return (-1);
	 }
	 if (strcat(scrittura_nome,id)== NULL){
	   printf("non posso strcat id a scrittura_nome.\n");
	   return (-1);
	 }
	 if (strcat(fil_ab_out,id)== NULL){
	   printf("non posso strcat id a fil_ab_out.\n");
	   return (-1);
	 }
	 
	 if (strcpy(G_weightfile,argv[3]) == NULL){
	   printf ("Could not copy weight file name.\n");
	   return (-1);
	 }
	 if (strcpy(G_Netname,argv[4]) == NULL){
	   printf ("Could not copy net definitions file name.\n");
	   return (-1);
	 }
	 break;
   }
   //   printf ("protfile=%s\tscrittura_nome=%s\tfil_ab_out=%s\tG_weightfile=%s\tG_netname=%s\n",protfile,scrittura_nome,fil_ab_out,G_weightfile,G_Netname);
   //  return(0);

	G_read_net();
	G_init_net();
	G_init_weights();
	G_writew();
/*	printf("%d,%f,%d\n", maxcount, (float) G_alpha, fl_ctot);*/
	/* .......test apertura file contenente il nome delle proteine... */
	
        if((p_scri = fopen(scrittura_nome,"wt")) == NULL){
                printf("non posso aprire scrittura");
                return(-1);
           }
		
	if ((fp_res = fopen(protfile, "rb")) == NULL) {
		printf("non posso aprire %s\n", protfile);
		return (-1);
	}
 	

Nprot = conto();
for (i = 0; i < Nout; i++) {	/* iniz. Q7 per media pesata */
		q7ave[i] = 0;
		q7brut[i] = 0;
	}

	G_readw();		/* ....Inizializzazione  PESI e SOGLIE
				 * (W(ij),BIAS(i).... */
       /*
          scrittura del file pesi in 
        */
	G_printw('A',fil_ab_out);
        

        count = 0;
	err = 0.0;
/*	printf("diff(ERROR)= %f\n", MODULO(olderr - err));*/
	while ((count < maxcount) && (MODULO(olderr - err) > PREC)) {
                for( j= 0; j< Nprot ; j ++){
                  	caricamento();
                        r1 = train();
			r2 = test();
			if ((r1 == -1) || (r2 == -1)) {
				printf("\n\nERRORE :in %s\n", nomef);
				return (-1);
			}
			if (fl_ctot == 2)
				G_updatew();
			err += r2;
		}
		if (fl_ctot == 1)
			G_updatew();
		G_writew();
		count++;
/*		printf("diff(ERROR)= %f\n", MODULO(olderr - err));*/
		olderr = err;
		err = 0.0;
		rewind(fp_res);
	}
/* precisioni */
	err = 0.0;
	rewind(fp_res);
	numprot = 0;
	for (i = 0; i < Nout; i++)
		ptot[i] = ntot[i] = otot[i] = 0;
	/*while (!(punt = feof(fp_res))) {*/
	for(j=0;j< Nprot ;j++){
	         numprot++;
                caricamento();
			r2 = test();
               if (r2 == -1) {
			printf("\n\n ERRORE :\n");
			return (-1);
		}
		err += r2;
		/*
 		pio = MAX((int)xout[0],(int)xout[1]) ; 
                */
		/* output su file */
		if(OUT_scrittura) 
		  fprintf(p_scri,"%i\t%f\t%f\t%f\t#\n",(j+1),xout[0],xout[1], G_od[0]);
	}
	fclose(fp_res);
       fprintf(p_scri,"parametri\nlearning rate %f\nmomentum %f\n",G_alpha,G_beta);
         fprintf(p_scri,"MAXCOUNT %i\n",maxcount);
	 fprintf(p_scri,"Sommatoria s.q.m = %f\nnumero di seg %i\n", err,numprot);
	mediaprec = 0;
	for (i = 0; i < Nout; i++) {
		mediaprec += ptot[i];
		ntot_aa += ntot[i];
	}
         fprintf(p_scri,"predizioni p[struct]\n");
	for (i = 0; i < Nout; i++)
		fprintf(p_scri,"p(%c) = %.2f | ", strut[i], ptot[i]);
	for (i = 0; i < Nout; i++)
		fprintf(p_scri,"o(%c) = %.2f | ", strut[i], otot[i]);
	fprintf(p_scri,"\n");
	if (numprot)
		fprintf(p_scri,"La precisione Media e' %f\n", mediaprec / ntot_aa);
	fprintf(p_scri," indice Q = pred[struct]/ntot[struct]\nQ7= c_ss\n");
        fprintf(p_scri," Predette corrette[struct]/ predette[struct]\n");
         for (i = 0; i < Nout; i++) {
		if (ntot[i])
			fprintf(p_scri,"Q(%c) = %.2f | ", strut[i], ptot[i] / ntot[i]);
		else
			fprintf(p_scri,"Q(%c) =  --  | ", strut[i]);
		ntmp = ntot_aa - ntot[i] - otot[i];
		utmp = ntot[i] - ptot[i];
		fprintf(p_scri,"Q7(%c) = %.2f | ", strut[i], q7(ptot[i], ntmp, utmp, otot[i]));
		fprintf(p_scri,"Q7ave(%c) = %.2f | ", strut[i], q7ave[i] / ntot_aa);
		fprintf(p_scri,"Q7/N(%c) = %.2f | ", strut[i], q7brut[i] / numprot);
		fprintf(p_scri,"Pc(%c) = %.2f \n", strut[i], ((ptot[i] + otot[i]) ? ptot[i] / (ptot[i] + otot[i]) : 1.0));
	}
        fprintf(p_scri,"N_res = totale esempi in struttura i \n");
	for (i = 0; i < Nout; i++)
		fprintf(p_scri,"[%c]:N_res = %.0f : N_gbp = %.0f\n", strut[i], ntot[i], numgbp[i]);
	
        close(p_scri);
	return (0);
}

/*
 * ================================END
 * MAIN==================================== 
 */


/*-----------------------------CREAFILE-------------------------------------*/

void
creafile(char *ps)
{
	char           *pc;

	if ((pc = strchr(ps, '.')) != NULL)
		*pc = '\0';
	strcpy(strcod, ps);
	strcat(strcod, ".res");
	strcpy(filedout, ps);
	strcat(filedout, ".od");
	return;
}
/*----------------------------END CREAFILE-----------------------------------*/

/*--------------------------------TRAIN--------------------------------------*/
int
train()
{
	int  k,   pio,     count=1,   i, j;
	/*
	 * long int count; 
	 *//* .contatore del nø di residui per la seuquenza.. */
	double          usqm;	/* ...ultimo scarto quadratico meidio... */
	double          ctot;	/* ...costo totale (somma scarti quad.
				 * medi)... */


	/* ..............Inizio ciclo di train.................. */

	ctot = 0.0;
	i = 0;
	while (!G_od[i])
		i++;
	if ((rand() % 100) < prob[i]) {
		usqm = G_stepf();
		ctot += usqm;
		G_gbp();
		if (!fl_ctot) {
			G_updatew();
		}
		numgbp[i]++;
	}
/*
for (i = Nout - 1; i >= 0; i--)
		printf("%f ", xout[i]);
	for (i = Nout - 1; i >= 0; i--)
		printf("%f ", G_od[i]);
	 printf("\n scarto quadratico medio nel while %f\n", usqm);
	*/
	return(count);
}
/*--------------------------------END
			    * TRAIN----------------------------------- 
			    */

/*---------------------------------TEST--------------------------------------*/
double
test()
{
	int             i, j, count = 1;
	double          usqm, q7tmp;	/* ...ultimo scarto quadratico
					 * meidio... */
	double          ctot, ris;
	double          ntmp, utmp;
	double          precisione = 0.0;



	/* ....Test sulla funzione di inizializzazione......... */
	/* ..............Inizio ciclo di Test.................. */
	for (i = 0; i < Nout; i++)
		o[i] = n[i] = p[i] = 0;
	ctot = 0.0;
	usqm = G_stepf();
	ctot += usqm;
	precisione += (double) testprec();

	/*
	 * .........Attivare se si vuole vedere l'output..... for(i =
	 * Nout-1;i >= 0;i--) printf("xout[%d]=%f..",i,xout[i]);
	 * printf("\n"); for(i = Nout-1;i >= 0;i--)
	 * printf("G_od[%d]=%f..",i,G_od[i]); printf("\n  scarto quadratico
	 * medio =%f\n",usqm);
	 * .................................................... 
	 */

	for (i = 0; i < Nout; i++) {
		ntot[i] += n[i];
		ptot[i] += p[i];
		otot[i] += o[i];
	
        }
       /* printf("indice c_ss\n");*/
	for (i = 0; i < Nout; i++) {
		ntmp = count - n[i] - o[i];
		utmp = n[i] - p[i];
		q7tmp = q7(p[i], ntmp, utmp, o[i]);
              /* printf("Q7(%c) = %.2f | ", strut[i], q7tmp);*/
		if (q7tmp <= 1) {
			q7ave[i] += q7tmp * count;
			q7brut[i] += q7tmp;
		}
	}
	/**/
	/*printf("\nPcorrette/Ptot (se  1.00 allora 0 predizioni\n");*/
/*	for (i = 0; i < Nout; i++) {
		if (p[i] + o[i])
			printf("Pc(%c)= %.2f | ", strut[i], p[i] / (p[i] + o[i]));
		else
			printf("Pc(%c)= 1.00 | ", strut[i]);
	}*/
	/**/
	for (i = 0; i < Nout; i++) {
		if (n[i])
			p[i] /= n[i];
		else
			p[i] -= 1;
	}

	precisione /= count;
	/**/
	/*printf("\tPRECISIONE : Q3=%.2f;", precisione);*/
	/*printf(" S=%.2f; C=%.2f;\n", p[0], p[1]);*/
	/**/
	return (ctot);
}
/*--------------------------------END TEST------------------------------------*/

/*--------------------------------TESTPREC------------------------------------*/
  int
        testprec(void)
        {
                int             i, ind;
         
                ind = 0;
                for (i = 1; i < Nout; i++)
                        if (xout[ind] < xout[i])
                                ind = i;
          if((fabs(xout[0]-xout[1])) > soglia ){
         
                 for (i = 0; i < Nout; i++)
                        n[i] += G_od[i];
                        
                if (G_od[ind]) {
                        p[ind] += 1.0;
                        return (1);
                        
                } else {
         
                        o[ind] += 1.0;
                        return (0);
                }
             }
        }
        


/*-----------------------------END testprec-----------------------------------*/



/*-----------------------------CARICAMENTO--------------------------------*/
/*
 * quelle non dichiarate sono variabili globali il file *pprot.res e' gia
 * stato aperto xin[] vettore in input ,G_od[]  uscita auspicata (1,0) per
 * ponte 
 */
void
caricamento(void)
{
        int           dodici=0,  id2, iddim, i, j, k;
       int ammino[DIMCOD],ode[2]; 
	char             moi[4], moid[1];
        double  control= 1.0;

 	for (i = 0; i < finestra; i++) {
                j = i * DIMC;
 		iddim = fread(ammino, sizeof(int), DIMC, fp_res);
		for (k = 0; k < DIMC; k++) {
			xin[j + k] = (float) ammino[k];
			xin[j+k]/=100.0;
		}
	}
/**/	for (i = 0; i < finestra; i++) {
		j = i * DIMC;
	for (k = 0; k < DIMC; k++) {
			printf("%.3f ",xin[j + k]);
		}
		printf("\n");
	} 
	id2 = fread(ode, sizeof(int), 2, fp_res);
      	G_od[0]=(float) ode[0];
	G_od[1]=(float) ode[1];
      /* printf("G_od[0] %f  G_od[1] %f \n",G_od[0],G_od[1]);
       breakpoint("leggi stuttura");
	*/
	return ;

}
/*--------------------------END CARICAMENTO-----------------------------------*/

/*------------------------------Q7------------------------------------------*/
double
q7(double ps, double ns, double us, double os)
{ 

	double          a, b;
	a = (ps * ns) - (os * us);
	b = (ns + us) * (ns + os) * (ps + us) * (ps + os);
	return (((b) ? (a / sqrt(b)) : 9.99));
}
/*---------------------------END Q7-----------------------------------------*/



/*---------------------------CHIUDIFILE------------------------------------------*/
int
chiudifile(void)
{
	fclose(fp_strcod);
/*	fclose(fp_dout);*/
	return (0);
}
/*--------------------------END CHIUDIFILE-------------------------------------*/

int conto(void)
{
	int ammino[DIMCOD], ode[2],  conto = 0, punt = 0;
	int prot=0, j,i,k,iddim, id2;
	for (i = 0; i < finestra ; i++)
    	{
    	  j = i * DIMC;
    	  iddim = fread (ammino, sizeof (int), DIMC, fp_res);
    	}
 	 id2 = fread (ode, sizeof (int), 2, fp_res);
      
	while (!(punt = feof (fp_res)))
 	   {
 	     for (i = 0; i < finestra ; i++)
 	       {
 	         j = i * DIMC;
 	         iddim = fread (&ammino[0], sizeof (int), DIMC, fp_res);
 	       }
	 	id2 = fread (ode, sizeof (int), 2, fp_res);
 		prot++; 
	   }
	printf("Nprot %i\nDIMCOD %i,finestra %i\n", prot, DIMC, finestra);
        rewind(fp_res);
return(prot);
}
