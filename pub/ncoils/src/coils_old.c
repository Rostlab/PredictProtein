
/* Program COILS version 2.1 */
  /* written by J.Lupas, 22 JUN 1993 */
  /* edited on 15 JAN 1994 */
  /* revised and corrected 4 APR 1994 */
  /* incorporates the option to use either the old MTK chart or 
     the new MTIDK chart AND the choice of weighting positions 
     a & d more (2.5 times) */
  /* 4 output options:
        - probabilities for window sizes 14, 21 & 28 in columns,
        - probabilities for window sizes 14, 21 & 28 in rows,
        - scores only for a user-input window size, or
        - the probabilities above a user-input cutoff.
     Requests input and output files from user. */
  /* transferred to c++ by Larry Harvie, harvie@owl.WPI.EDU */
  /* adapted to C by Reinhard Schneider, SCHNEIDER@EMBL-Heidelberg.DE */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


  typedef FILE *text;
  typedef double chartstore[21][8];
  typedef char residuestore[10001];
  typedef double calcstore[4][10001];
  typedef int heptadstore[4][10001];

  int window;
  char inputfile[80],outputfile[80];
  text protein,pickup;
  chartstore chartvalue;   /* probability values */
  residuestore residue;    /* stores amino acid sequence */
  heptadstore heptnum;     /* stores heptad position number */
  calcstore calcnumb;      /* stores best scores */
  int res_total;       /* total no. of residues in protein */
  char junkline[9000];     /* reads opening protein info. */
  char nameprot[9000];
  int nomore;	   /* in case there's junk after last protein */
  short windows;
  double winheight;
  char option,chartchar,weightchar;
  double ad_weight;
  int hept_weight;
  calcstore tempcalc;
  heptadstore temphept;
  char fr14[10001],fr21[10001],fr28[10001];
  int pr14[10001],pr21[10001],pr28[10001];

short mod(short x,short y)
{
   double x1=(double) x,y1=(double) y;

        return (short) floor(fmod(x,y));
}
void  Init_newchart()
  /* store the probability values for each of the 20
     amino acids to occur in each of the heptad positions */
{
chartvalue[1][1]=2.998; chartvalue[1][2]=0.269; chartvalue[1][3]=0.367;
chartvalue[1][4]=3.852; chartvalue[1][5]=0.510; chartvalue[1][6]=0.514;
chartvalue[1][7]=0.562;
chartvalue[2][1]=2.408; chartvalue[2][2]=0.261; chartvalue[2][3]=0.345;
chartvalue[2][4]=0.931; chartvalue[2][5]=0.402; chartvalue[2][6]=0.440;
chartvalue[2][7]=0.289;
chartvalue[3][1]=1.525; chartvalue[3][2]=0.479; chartvalue[3][3]=0.350;
chartvalue[3][4]=0.887; chartvalue[3][5]=0.286; chartvalue[3][6]=0.350;
chartvalue[3][7]=0.362;
chartvalue[4][1]=2.161; chartvalue[4][2]=0.605; chartvalue[4][3]=0.442;
chartvalue[4][4]=1.441; chartvalue[4][5]=0.607; chartvalue[4][6]=0.457;
chartvalue[4][7]=0.570;
chartvalue[5][1]=0.490; chartvalue[5][2]=0.075; chartvalue[5][3]=0.391;
chartvalue[5][4]=0.639; chartvalue[5][5]=0.125; chartvalue[5][6]=0.081;
chartvalue[5][7]=0.038;
chartvalue[6][1]=1.319; chartvalue[6][2]=0.064; chartvalue[6][3]=0.081;
chartvalue[6][4]=1.526; chartvalue[6][5]=0.204; chartvalue[6][6]=0.118;
chartvalue[6][7]=0.096;
chartvalue[7][1]=0.084; chartvalue[7][2]=0.215; chartvalue[7][3]=0.432;
chartvalue[7][4]=0.111; chartvalue[7][5]=0.153; chartvalue[7][6]=0.367;
chartvalue[7][7]=0.125;
chartvalue[8][1]=1.283; chartvalue[8][2]=1.364; chartvalue[8][3]=1.077;
chartvalue[8][4]=2.219; chartvalue[8][5]=0.490; chartvalue[8][6]=1.265;
chartvalue[8][7]=0.903;
chartvalue[9][1]=1.233; chartvalue[9][2]=2.194; chartvalue[9][3]=1.817;
chartvalue[9][4]=0.611; chartvalue[9][5]=2.095; chartvalue[9][6]=1.686;
chartvalue[9][7]=2.027;
chartvalue[10][1]=1.014; chartvalue[10][2]=1.476; 
chartvalue[10][3]=1.771;
chartvalue[10][4]=0.114; chartvalue[10][5]=1.667; 
chartvalue[10][6]=2.006;
chartvalue[10][7]=1.844;
chartvalue[11][1]=0.590; chartvalue[11][2]=0.646; 
chartvalue[11][3]=0.584;
chartvalue[11][4]=0.842; chartvalue[11][5]=0.307; 
chartvalue[11][6]=0.611;
chartvalue[11][7]=0.396;
chartvalue[12][1]=0.281; chartvalue[12][2]=3.351; 
chartvalue[12][3]=2.998;
chartvalue[12][4]=0.789; chartvalue[12][5]=4.868; 
chartvalue[12][6]=2.735;
chartvalue[12][7]=3.812;
chartvalue[13][1]=0.068; chartvalue[13][2]=2.103; 
chartvalue[13][3]=1.646;
chartvalue[13][4]=0.182; chartvalue[13][5]=0.664; 
chartvalue[13][6]=1.581;
chartvalue[13][7]=1.401;
chartvalue[14][1]=0.311; chartvalue[14][2]=2.290; 
chartvalue[14][3]=2.330;
chartvalue[14][4]=0.811; chartvalue[14][5]=2.596; 
chartvalue[14][6]=2.155;
chartvalue[14][7]=2.585;
chartvalue[15][1]=1.231; chartvalue[15][2]=1.683; 
chartvalue[15][3]=2.157;
chartvalue[15][4]=0.197; chartvalue[15][5]=1.653; 
chartvalue[15][6]=2.430;
chartvalue[15][7]=2.065;
chartvalue[16][1]=0.332; chartvalue[16][2]=0.753; 
chartvalue[16][3]=0.930;
chartvalue[16][4]=0.424; chartvalue[16][5]=0.734; 
chartvalue[16][6]=0.801;
chartvalue[16][7]=0.518;
chartvalue[17][1]=0.197; chartvalue[17][2]=0.543; 
chartvalue[17][3]=0.647;
chartvalue[17][4]=0.680; chartvalue[17][5]=0.905; 
chartvalue[17][6]=0.643;
chartvalue[17][7]=0.808;
chartvalue[18][1]=0.918; chartvalue[18][2]=0.002; 
chartvalue[18][3]=0.385;
chartvalue[18][4]=0.440; chartvalue[18][5]=0.138; 
chartvalue[18][6]=0.432;
chartvalue[18][7]=0.079;
chartvalue[19][1]=0.066; chartvalue[19][2]=0.064; 
chartvalue[19][3]=0.065;
chartvalue[19][4]=0.747; chartvalue[19][5]=0.006; 
chartvalue[19][6]=0.115;
chartvalue[19][7]=0.014;
chartvalue[20][1]=0.004; chartvalue[20][2]=0.108; 
chartvalue[20][3]=0.018;
chartvalue[20][4]=0.006; chartvalue[20][5]=0.010; 
chartvalue[20][6]=0.004;
chartvalue[20][7]=0.007;
}
void  Init_oldchart()
{
  chartvalue[1][1]=3.167; chartvalue[1][2]=0.297;
chartvalue[1][3]=0.398;
  chartvalue[1][4]=3.902; chartvalue[1][5]=0.585;
chartvalue[1][6]=0.501;
  chartvalue[1][7]=0.483;
  chartvalue[2][1]=2.597; chartvalue[2][2]=0.098;
chartvalue[2][3]=0.345;
  chartvalue[2][4]=0.894; chartvalue[2][5]=0.514;
chartvalue[2][6]=0.471;
  chartvalue[2][7]=0.431;
  chartvalue[3][1]=1.665; chartvalue[3][2]=0.403;
chartvalue[3][3]=0.386;
  chartvalue[3][4]=0.949; chartvalue[3][5]=0.211;
chartvalue[3][6]=0.342;
  chartvalue[3][7]=0.360;
  chartvalue[4][1]=2.240; chartvalue[4][2]=0.37; 
chartvalue[4][3]=0.480;
  chartvalue[4][4]=1.409; chartvalue[4][5]=0.541;
chartvalue[4][6]=0.772;
  chartvalue[4][7]=0.663;
  chartvalue[5][1]=0.531; chartvalue[5][2]=0.076;
chartvalue[5][3]=0.403;
  chartvalue[5][4]=0.662; chartvalue[5][5]=0.189;
chartvalue[5][6]=0.106;
  chartvalue[5][7]=0.013;
  chartvalue[6][1]=1.417; chartvalue[6][2]=0.090;
chartvalue[6][3]=0.122;
  chartvalue[6][4]=1.659; chartvalue[6][5]=0.19;  chartvalue[6][6]=0.13;
  chartvalue[6][7]=0.1550;
  chartvalue[7][1]=0.045; chartvalue[7][2]=0.275;
chartvalue[7][3]=0.578;
  chartvalue[7][4]=0.216; chartvalue[7][5]=0.211;
chartvalue[7][6]=0.426;
  chartvalue[7][7]=0.156;
  chartvalue[8][1]=1.297; chartvalue[8][2]=1.551;
chartvalue[8][3]=1.084;
  chartvalue[8][4]=2.612; chartvalue[8][5]=0.377;
chartvalue[8][6]=1.248;
  chartvalue[8][7]=0.877;
  chartvalue[9][1]=1.375; chartvalue[9][2]=2.639;
chartvalue[9][3]=1.763;
  chartvalue[9][4]=0.191; chartvalue[9][5]=1.815;
chartvalue[9][6]=1.961;
  chartvalue[9][7]=2.795;
  chartvalue[10][1]=0.659; chartvalue[10][2]=1.163; 
chartvalue[10][3]=1.210;
  chartvalue[10][4]=0.031; chartvalue[10][5]=1.358; 
chartvalue[10][6]=1.937;
  chartvalue[10][7]=1.798;
  chartvalue[11][1]=0.347; chartvalue[11][2]=0.275; 
chartvalue[11][3]=0.679;
  chartvalue[11][4]=0.395; chartvalue[11][5]=0.294; 
chartvalue[11][6]=0.579;
  chartvalue[11][7]=0.213;
  chartvalue[12][1]=0.262; chartvalue[12][2]=3.496; 
chartvalue[12][3]=3.108;
  chartvalue[12][4]=0.998; chartvalue[12][5]=5.685; 
chartvalue[12][6]=2.494;
  chartvalue[12][7]=3.048;
  chartvalue[13][1]=0.03;  chartvalue[13][2]=2.352; 
chartvalue[13][3]=2.268;
  chartvalue[13][4]=0.237; chartvalue[13][5]=0.663; 
chartvalue[13][6]=1.62;
  chartvalue[13][7]=1.448;
  chartvalue[14][1]=0.179; chartvalue[14][2]=2.114; 
chartvalue[14][3]=1.778;
  chartvalue[14][4]=0.631; chartvalue[14][5]=2.55;  
chartvalue[14][6]=1.578;
  chartvalue[14][7]=2.526;
  chartvalue[15][1]=0.835; chartvalue[15][2]=1.475; 
chartvalue[15][3]=1.534;
  chartvalue[15][4]=0.039; chartvalue[15][5]=1.722; 
chartvalue[15][6]=2.456;
  chartvalue[15][7]=2.280;
  chartvalue[16][1]=0.382; chartvalue[16][2]=0.583; 
chartvalue[16][3]=1.052;
  chartvalue[16][4]=0.419; chartvalue[16][5]=0.525; 
chartvalue[16][6]=0.916;
  chartvalue[16][7]=0.628;
  chartvalue[17][1]=0.169; chartvalue[17][2]=0.702; 
chartvalue[17][3]=0.955;
  chartvalue[17][4]=0.654; chartvalue[17][5]=0.791; 
chartvalue[17][6]=0.843;
  chartvalue[17][7]=0.647;
  chartvalue[18][1]=0.824; chartvalue[18][2]=0.022; 
chartvalue[18][3]=0.308;
  chartvalue[18][4]=0.152; chartvalue[18][5]=0.180; 
chartvalue[18][6]=0.156;
  chartvalue[18][7]=0.044;
  chartvalue[19][1]=0.24;  chartvalue[19][2]=0;     
chartvalue[19][3]=0.00;
  chartvalue[19][4]=0.456; chartvalue[19][5]=0.019; 
chartvalue[19][6]=0.00;
  chartvalue[19][7]=0.00;
  chartvalue[20][1]=0.00;  chartvalue[20][2]=0.008; chartvalue[20][3]=0;
  chartvalue[20][4]=0.013; chartvalue[20][5]=0.0;   chartvalue[20][6]=0;
  chartvalue[20][7]=0;
}


void  Get_info()
{
  char junk;

  printf("COILS version 2.1\n");
  printf("ENTER INPUT FILE:  ");
  fflush(stdout);
  scanf("%s",inputfile);
  printf("-->%s\n",inputfile);
  protein=fopen(inputfile,"r");  /* modify for reading */
  if (protein==NULL) {
     perror("problem");
     printf("'%s' can not be found.  Try again after verifying the file name.\n",inputfile);
     exit(0);
  } /* endif */

  printf("ENTER OUTPUT FILE:  ");
  scanf("%s",outputfile);
  pickup=fopen(outputfile,"w");
  if (pickup==NULL) {
     printf("The system could not open the output file\n");
     printf(".  Check the free space on disk\n");
     exit(0);
  } /* endif */
  printf("Two scoring matrices are available:\n");
  printf("   1 - MTK\n");
  printf("   2 - MTIDK\n");
  printf("Which matix? (1|2) <enter>? ");
  chartchar='\0';
  while ((chartchar!='1') && (chartchar!='2') && (chartchar!=(char) 13))
     scanf("%c",&chartchar);
  printf("Do you want a weight of 2.5 for positions a & d? (Y|N) <enter>? ");
  weightchar='\0';
  while ((weightchar!='n') && (weightchar!='y') && (weightchar!='Y') && 
(weightchar!='N')  && (weightchar!=(char) 13))
     scanf("%c",&weightchar);

  fprintf(pickup,"COILS version 2.1\n");
  if (chartchar=='2')
  {
    fprintf(pickup,"using MTIDK matrix.\n");
    Init_newchart();
  } else {
    fprintf(pickup,"using MTK matrix.\n");
    Init_oldchart();
  }
  if ((weightchar=='y') || (weightchar=='Y'))
  {
    fprintf(pickup,"weights: a,d=2.5 and b,c,e,f,g=1.0\n");
    hept_weight=10;
    ad_weight=2.5;
  } else {
    fprintf(pickup,"no weights\n");
    hept_weight=7;
    ad_weight=1.0;
  }
  fprintf(pickup,"Input file is %s\n",inputfile);
}
void  Select_option()
{
    printf("OUTPUT OPTIONS:\n");
    printf("   p - probabilities in columns\n");
    printf("   a - probabilities in rows, abbreviated to the first digit\n");
    printf("   b - scores (size of the scanning window defined by the user)\n");
    printf("   c - only probabilities above a user-defined cutoff\n");
    printf("ENTER OPTION: ");
  while ((option!='a') && (option!='b') && (option!='c') && (option!='A') 
&& (option!='B') && (option!='C') && (option!='p') && (option!='P')) {
     scanf("%c",&option);
  } /* endwhile */
    printf("\n");
  if ((option=='b') || (option=='B'))
  {
    printf("ENTER WINDOW SIZE:  ");
    scanf("%d",&window);
 } /* end */
  else window=14;
}


int checkforend()
{
  int junklen;
  char *last4;
  int checkforend=0;

  junkline[strlen(junkline)-1]='\0';
  junklen=strlen(junkline);
  if (junklen > 0)
  {
    if (junkline[0] == '>')
       checkforend=1;
    strcpy(nameprot,junkline);
  }
  if (junklen > 3)
  {
    last4=(char *) &(junkline[junklen-4]);
    if (strcmp(last4,"  ..")==0)
    {
      checkforend=1;
      strcpy(nameprot,junkline);
    }
  }
  return checkforend;
}
void  Skip_opening_info()
  /* Skip opening lines of protein to get to amino acid sequence */
{
  int endingfound;

   endingfound=checkforend();
   while (!endingfound)
    {
      if (!feof(protein))
      {
        fgets(junkline,9999,protein);
        endingfound=checkforend();
     } else {
        strcpy(nameprot," ");
	fclose(protein);
	protein=fopen(inputfile,"r");
        endingfound=1;
     } /* endif */
   } /* endwhile */
}
void  Store_residues()
  /* stores only the amino acids of the sequence, skipping numbers, 
blanks,
     and carriage returns and ending with '/' || '*' */
{
  char tempstore;
  int validaa;

  res_total=0;
  tempstore=fgetc(protein);
  while ((tempstore != '/') && (tempstore != '*') && (!feof(protein)))
  {
     switch (tempstore & 95) {
      case 'L':
      case 'I':
      case 'V':
      case 'M':
      case 'F':
      case 'Y':
      case 'G':
      case 'A':
      case 'K':
      case 'P':
      case 'R':
      case 'H':
      case 'E':
      case 'D':
      case 'Q':
      case 'N':
      case 'S':
      case 'T':
      case 'C':
      case 'W':
         validaa=1;
        break;
     default:
        validaa=0;
       break;
     } /* endswitch */

    if (validaa)
    {
      res_total=res_total+1;
      residue[res_total]=tempstore;
    } /* endif */
    tempstore=fgetc(protein);
  } /* endwhile */
  if (tempstore == '/') fgets(junkline,9999,protein); /* read other '/' 
at end */
}


int Getx(char res)
{
   int X;

  switch (res & (char) 95) {
  case 'L':
     X=1;     break;
  case 'I':
     X=2;     break;
  case 'V':
     X=3;     break;
  case 'M':
     X=4;     break;
  case 'F':
     X=5;     break;
  case 'Y':
     X=6;     break;
  case 'G':
     X=7;     break;
  case 'A':
     X=8;     break;
  case 'K':
     X=9;     break;
  case 'R':
     X=10;     break;
  case 'H':
     X=11;     break;
  case 'E':
     X=12;     break;
  case 'D':
     X=13;     break;
  case 'Q':
     X=14;     break;
  case 'N':
     X=15;     break;
  case 'S':
     X=16;     break;
  case 'T':
     X=17;     break;
  case 'C':
     X=18;     break;
  case 'W':
     X=19;     break;
  case 'P':
     X=20;     break;
  default:
     X=-1;    break;
  } /* endswitch */
  return X;
}
void Calculate(int startwindow,int endindex)
  /* calculates best scores for each window frame */
{
  int X,x,y,extras,heptad_pos,window_pos,res_pos;
  double root_inverse,scores,misc;
  int hept,index,window;
  double weight;
  int root;

  printf("Calculating...\n");
  index=1;
  window=startwindow;
  while (index<=endindex)
  {
   printf(".");
   fflush(stdout);
   res_pos=0;
   root=(window / 7) * hept_weight;
   do {
    res_pos=res_pos+1;
    tempcalc[index][res_pos]=0;
    for (heptad_pos=0; heptad_pos<=6; heptad_pos++)  /* go through each 
residue in each heptad pos */
    {
      scores=1.0;
      hept=1;
      for (window_pos=0;window_pos<=window-1;window_pos++)  /* get
values 
at all 21 positions */
      {
        switch (residue[window_pos + res_pos] & 95){
          case 'L':
             x=1;     break;
          case 'I':
             x=2;     break;
          case 'V':
             x=3;     break;
          case 'M':
             x=4;     break;
          case 'F':
             x=5;     break;
          case 'Y':
             x=6;     break;
          case 'G':
             x=7;     break;
          case 'A':
             x=8;     break;
          case 'K':
             x=9;     break;
          case 'R':
             x=10;     break;
          case 'H':
             x=11;     break;
          case 'E':
             x=12;     break;
          case 'D':
             x=13;     break;
          case 'Q':
             x=14;     break;
          case 'N':
             x=15;     break;
          case 'S':
             x=16;     break;
          case 'T':
             x=17;     break;
          case 'C':
             x=18;     break;
          case 'W':
             x=19;     break;
          case 'P':
             x=20;     break;
          default:
             x=-1;    break;
       } /* endswitch */
        y=(int) fmod((double)(window_pos + res_pos + heptad_pos),7.0);
	if (y==0) y=7;
        if (window_pos==0) hept=y;
        if (y==0) y=7;
	if ((y==1) || (y==4)) weight=ad_weight;
	else weight=1.0;
	root_inverse=1.0/(double) root;
	misc=pow(chartvalue[x][y],weight);
        scores=scores*(pow(misc,root_inverse));
      } /* end of window_pos loop */
      if (scores>tempcalc[index][res_pos])
      {
        tempcalc[index][res_pos]=scores;
        temphept[index][res_pos]=(int) fmod((double) (hept-1),7.0);
      }
    }  /* end of heptad_pos loop*/
   } while (res_pos+window != res_total+1);
   for (extras=1; extras<=window-1;extras++)
   {
    tempcalc[index][res_pos+extras]=tempcalc[index][res_pos];
    temphept[index][res_pos+extras]=(int) fmod((double) 
(temphept[index][res_pos]+extras),7.0);
   }
   window=window+7;
   index=index+1;
  }  /* for window sizes 14, 21 & 28 */
  /*maximize loop*/
  index=1;
  window=startwindow;
  while (index<=endindex)
  {
   res_pos=0;
   do {
    res_pos=res_pos+1;
    calcnumb[index][res_pos]=tempcalc[index][res_pos];
    heptnum[index][res_pos]=temphept[index][res_pos];
    window_pos=0;
    do {
      window_pos=window_pos+1;
      if (res_pos-window_pos<1) window_pos=window-1;
      else
       if (tempcalc[index][res_pos-window_pos]>calcnumb[index][res_pos])
       {
         calcnumb[index][res_pos]=tempcalc[index][res_pos-window_pos];
         heptnum[index][res_pos]=(int) 
fmod((temphept[index][res_pos-window_pos]+window_pos),7.0);
       } /* endif */
    } while (window_pos!=window-1); /* enddo */
   } while (res_pos!=res_total); /* enddo */
   index=index+1;
   window=window+7;
  }
  printf("\n");
}
double Calcprob(double x,double meancc,double stddevcc,double 
meangl,double stddevgl,double ratio_gl_cc)
{
  double prob1,prob2,prob3,prob4;

  prob1=(0.5) * pow(((x-meancc) / stddevcc),2.0);
  prob2=(0.5) * pow(((x-meangl) / stddevgl),2.0);
  prob3=stddevgl * exp(-prob1);
  prob4=ratio_gl_cc * stddevcc * exp(-prob2);
  return (prob3) / (prob3+prob4);
}
char frame(int heptnum)
{
   switch (heptnum) {
   case 0:
      return 'a';      break;
   case 1:
      return 'b';      break;
   case 2:
      return 'c';      break;
   case 3:
      return 'd';      break;
   case 4:
      return 'e';      break;
   case 5:
      return 'f';      break;
   case 6:
      return 'g';     break;
   } /* endswitch */
   return 'x';
}
int i_trunc(double n)
{
        return (int) floor(n);
}
void  Column_probs(double peakmin)
{
  int res_pos;
  char fr14,fr21,fr28;
  double prob14,prob21,prob28,old14,old21,old28,xx=1,lastxx=1;
  int prevres,color=8,c14=9,c21=15,c28=12;
   char t1[]="14",t2[]="21",t3[]="28";

  fprintf(pickup,"%s\n",nameprot);
  fprintf(pickup,"  Residue       Window=14             Window=21        Window=28\n");
  fprintf(pickup,"             Score  Probability     Score Probability  Score  Probability\n");
  prevres=1;
  for (res_pos=1;res_pos<=res_total;res_pos++)
  {
    fr14=frame(heptnum[1][res_pos]);
    fr21=frame(heptnum[2][res_pos]);
    fr28=frame(heptnum[3][res_pos]);
    if (chartchar=='2')
    {
     if ((weightchar=='y') || (weightchar=='Y'))
     {
      prob28=Calcprob(calcnumb[3][res_pos],1.74,0.20,0.86,0.18,30);
      prob21=Calcprob(calcnumb[2][res_pos],1.79,0.24,0.92,0.22,25);
      prob14=Calcprob(calcnumb[1][res_pos],1.89,0.30,1.04,0.27,20);
     } else {
      prob28=Calcprob(calcnumb[3][res_pos],1.69,0.18,0.80,0.18,30);
      prob21=Calcprob(calcnumb[2][res_pos],1.74,0.23,0.86,0.21,25);
      prob14=Calcprob(calcnumb[1][res_pos],1.82,0.28,0.95,0.26,20);
    } /* end */
   } /* end */
    else
    {
     if ((weightchar=='y') || (weightchar=='Y'))
     {
      if (calcnumb[3][res_pos] > 0.0)
        prob28=Calcprob(calcnumb[3][res_pos],1.70,0.24,0.79,0.23,30);
      else {
        prob28=0.0;
        fr28='x';
      } /* endif */
      if (calcnumb[2][res_pos] > 0.0)
        prob21=Calcprob(calcnumb[2][res_pos],1.76,0.28,0.86,0.26,25);
      else { prob21=0.0; fr21='x'; }
      if (calcnumb[1][res_pos] > 0.0)
        prob14=Calcprob(calcnumb[1][res_pos],1.88,0.34,1.00,0.33,20);
      else { prob14=0.0; fr14='x'; }
    } /* end */
     else
     {
      if (calcnumb[3][res_pos] > 0.0)
       
prob28=Calcprob(calcnumb[3][res_pos],1.628,0.243,0.770,0.202,30);
      else { prob28=0.0; fr28='x'; }
      if (calcnumb[2][res_pos] > 0.0)
       
prob21=Calcprob(calcnumb[2][res_pos],1.683,0.285,0.828,0.236,25);
      else { prob21=0.0; fr21='x'; }
      if (calcnumb[1][res_pos] > 0.0)
       
prob14=Calcprob(calcnumb[1][res_pos],1.782,0.328,0.936,0.289,20);
      else { prob14=0.0; fr14='x'; }
    } /* end */
    }
    if ((prob14>=peakmin) || (prob21>=peakmin) || (prob28>=peakmin))
    {
      if (res_pos-1!=prevres) fprintf(pickup,"...\n");
      prevres=res_pos;
      fprintf(pickup,"%5d %c",res_pos,residue[res_pos]);
      fprintf(pickup,"     %c %5.3lf    %5.3lf",fr14,calcnumb[1][res_pos],prob14);
      fprintf(pickup,"       %c %5.3lf    %5.3lf",fr21,calcnumb[2][res_pos],prob21);
      fprintf(pickup,"       %c %5.3lf    %5.3lf",fr28,calcnumb[3][res_pos],prob28);
      fprintf(pickup,"\n");
    }
  }
}
void  Row_probs()
{
  int res_pos,maxline,startpos;

  fprintf(pickup,"%s\n",nameprot);
  for (res_pos=1;res_pos<=res_total;res_pos++)
  {
    fr14[res_pos]=frame(heptnum[1][res_pos]);
    fr21[res_pos]=frame(heptnum[2][res_pos]);
    fr28[res_pos]=frame(heptnum[3][res_pos]);
    if (chartchar=='2')
    {
     if ((weightchar=='y') || (weightchar=='Y'))
     {
      
pr14[res_pos]=i_trunc(Calcprob(calcnumb[1][res_pos],1.89,0.30,1.04,0.27,20)*10.0);
      
pr21[res_pos]=i_trunc(Calcprob(calcnumb[2][res_pos],1.79,0.24,0.92,0.22,25)*10.0);
      
pr28[res_pos]=i_trunc(Calcprob(calcnumb[3][res_pos],1.74,0.20,0.86,0.18,30)*10.0);
    } /* end */
     else
     {
      
pr14[res_pos]=i_trunc(Calcprob(calcnumb[1][res_pos],1.82,0.28,0.95,0.26,20)*10.0);
      
pr21[res_pos]=i_trunc(Calcprob(calcnumb[2][res_pos],1.74,0.23,0.86,0.21,25)*10.0);
      
pr28[res_pos]=i_trunc(Calcprob(calcnumb[3][res_pos],1.69,0.18,0.80,0.18,30)*10.0);
    } /* end */
   } /* end */
    else
    {
     if ((weightchar=='y') || (weightchar=='Y'))
     {
      if (calcnumb[3][res_pos] > 0)
       
pr28[res_pos]=i_trunc(Calcprob(calcnumb[3][res_pos],1.70,0.24,0.79,0.23,30)*10.0);
      else { pr28[res_pos]=0; fr28[res_pos]='x'; }
      if (calcnumb[2][res_pos] > 0)
       
pr21[res_pos]=i_trunc(Calcprob(calcnumb[2][res_pos],1.76,0.28,0.86,0.26,25)*10.0);
      else { pr21[res_pos]=0; fr21[res_pos]='x'; }
      if (calcnumb[1][res_pos] > 0)
       
pr14[res_pos]=i_trunc(Calcprob(calcnumb[1][res_pos],1.88,0.34,1.00,0.33,20)*10.0);
      else { pr14[res_pos]=0; fr14[res_pos]='x'; }
    } /* end */
     else
     {
      if (calcnumb[3][res_pos] > 0)
       
pr28[res_pos]=i_trunc(Calcprob(calcnumb[3][res_pos],1.628,0.243,0.770,0.202,30)*10.0);
      else { pr28[res_pos]=0; fr28[res_pos]='x'; }
      if (calcnumb[2][res_pos] > 0)
       
pr21[res_pos]=i_trunc(Calcprob(calcnumb[2][res_pos],1.683,0.285,0.828,0.236,25)*10.0);
      else { pr21[res_pos]=0; fr21[res_pos]='x'; }
      if (calcnumb[1][res_pos] > 0)
       
pr14[res_pos]=i_trunc(Calcprob(calcnumb[1][res_pos],1.782,0.328,0.936,0.289,20)*10.0);
      else { pr14[res_pos]=0; fr14[res_pos]='x'; }
    } /* end */
    }
    if (pr14[res_pos]>9) pr14[res_pos]=9;
    if (pr21[res_pos]>9) pr21[res_pos]=9;
    if (pr28[res_pos]>9) pr28[res_pos]=9;
  }
  maxline=60;
  startpos=1;
  while (startpos+maxline-1 <= res_total)
  {
    fprintf(pickup,"%d\n",startpos);
    fprintf(pickup,"    .    |    .    |    .    |    .    |    .   |    .    |\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%c",residue[res_pos]);
    fprintf(pickup,"\n\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%d",pr14[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%d",pr21[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%d",pr28[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%c",fr14[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%c",fr21[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=startpos+maxline-1;res_pos++)
      fprintf(pickup,"%c",fr28[res_pos]);
    fprintf(pickup,"\n");
    fprintf(pickup,"\n");
    startpos=startpos+60;
  }
  /* finish up! */
  if (startpos<=res_total)
  {
    fprintf(pickup,"%d\n",startpos);
    fprintf(pickup,"    .    |    .    |    .    |    .    |    .   |    .    |\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%c",residue[res_pos]);
    fprintf(pickup,"\n");
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%d",pr14[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%d",pr21[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%d",pr28[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%c",fr14[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%c",fr21[res_pos]);
    fprintf(pickup,"\n");
    for (res_pos=startpos;res_pos<=res_total;res_pos++)
      fprintf(pickup,"%c",fr28[res_pos]);
    fprintf(pickup,"\n");
    fprintf(pickup,"\n");
  }
}


void  Scores_only()
{
  int res_pos;
  char fr;

  fprintf(pickup,"%s\n",nameprot);
  fprintf(pickup,"       Residue  Frame  Score\n");
  for (res_pos=1;res_pos<=res_total;res_pos++)
  {
    if (calcnumb[1][res_pos] > 0.0)
    {
      fr=frame(heptnum[1][res_pos]);
      fprintf(pickup,"    %6d %c      %c    %2.6lf\n",res_pos,residue[res_pos],fr,
          calcnumb[1][res_pos]);
   } else
      fprintf(pickup,"    %6d %c      x    %2.6lf\n",res_pos,residue[res_pos],
          calcnumb[1][res_pos]);
  }
}

void  Calc_print()
{
  double peakmin=0.0;
  int num_wind;

  if (res_total >= window)
  {
    num_wind=3;
    if ((option=='a') || (option=='A'))
    {
      Calculate(window,num_wind);
      Row_probs();
   } else
    if ((option=='b') || (option=='B'))
    {
      num_wind=1;
      Calculate(window,num_wind);
      Scores_only();
   } /* end */
    else
    {
      if ((option=='c') || (option=='C'))
      {
        printf("ENTER MINIMUM PROBABILITY (as .##):  ");
        scanf("%lf",&peakmin);
      }
      Calculate(window,num_wind);
      Column_probs(peakmin);
    }
 } else
    fprintf(pickup,"Protein too short. Length=%d\n",res_total);
}

main(int argc, char *argv[], char *envp[])
{    /* Main Program */
  Get_info();
  Select_option();
  fgets(junkline,9999,protein);

  do {
    Skip_opening_info();
    if (!nomore)
    {
      Store_residues();
      Calc_print();
      if (!feof(protein)) fgets(junkline,9999,protein);
    }
  } while (!feof(protein)); /* enddo */
  fclose(protein);
  fclose(pickup);
}

