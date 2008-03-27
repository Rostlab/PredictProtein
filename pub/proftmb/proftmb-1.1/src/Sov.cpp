#include "Sov.h"
#include <cmath>
#include <cstdio>

//This code adapted from Zemla sov.c (/home/bigelow/cpp/apps/sov.c)
//It appears to implement both algorithms in (JMB 1994) and (Proteins 1999)




/*-----------------------------------------------------------
  /
  /    sov - evaluate SSp by the Segment OVerlap quantity (SOV)
  /                Input: secondary structure segments
  /
  /------------------------------------------------------------*/
float sov(int n_aa, char* sss1, char* sss2, parameters* pdata)
{
	int i, k, length1, length2, beg_s1, end_s1, beg_s2, end_s2;
	int j1, j2, k1, k2, minov, maxov, d=0, d1, d2, n, multiple;
	char s1, s2, sse[3];
	float out; 
	double s, x;

	sse[0]='#';
	sse[1]='#';
	sse[2]='#';

	if(pdata->sov_what==0) {
		sse[0]='H';
		sse[1]='E';
		sse[2]='C';
	}
	if(pdata->sov_what==1) {
		sse[0]='H';
		sse[1]='H';
		sse[2]='H';
	}
	if(pdata->sov_what==2) {
		sse[0]='E';
		sse[1]='E';
		sse[2]='E';
	}
	if(pdata->sov_what==3) {
		sse[0]='C';
		sse[1]='C';
		sse[2]='C';
	}
	n=0;
	for(i=0;i<n_aa;i++) {
		s1=sss1[i];
		if(s1==sse[0] || s1==sse[1] || s1==sse[2]) {
			n++;
		}
	}
	out=0.0;
	s=0.0;
	length1=0;
	length2=0;
	i=0;
	while(i<n_aa) {
		beg_s1=i;
		s1=sss1[i];
		while(sss1[i]==s1 && i<n_aa) {
			i++;
		}
		end_s1=i-1;
		length1=end_s1-beg_s1+1;
		multiple=0;
		k=0;
		while(k<n_aa) {
			beg_s2=k;
			s2=sss2[k];
			while(sss2[k]==s2 && k<n_aa) {
				k++;
			}
			end_s2=k-1;
			length2=end_s2-beg_s2+1;
			if(s1==sse[0] || s1==sse[1] || s1==sse[2]) {
				if(s1==s2 && end_s2>=beg_s1 && beg_s2<=end_s1) {
					if(multiple>0 && pdata->sov_method==1) {
						n=n+length1;
					}
					multiple++;
					if(beg_s1>beg_s2) {
						j1=beg_s1;
						j2=beg_s2;
					}
					else {
						j1=beg_s2;
						j2=beg_s1;
					}
					if(end_s1<end_s2) {
						k1=end_s1;
						k2=end_s2;
					}
					else {
						k1=end_s2;
						k2=end_s1;
					}
					minov=k1-j1+1;
					maxov=k2-j2+1;
					d1=(int)floor(length1*pdata->sov_delta_s);
					d2=(int)floor(length2*pdata->sov_delta_s);
					if(d1>d2) d=d2;
					if(d1<=d2 || pdata->sov_method==0) d=d1;
					if(d>minov) {
						d=minov;
					}
					if(d>maxov-minov) {
						d=maxov-minov;
					}
					x=pdata->sov_delta*d;
					x=(minov+x)*length1;
					if(maxov>0) {
						s=s+x/maxov;
					}
					else {
						printf("\n ERROR! minov = %-4d maxov = %-4d length = %-4d d = %-4d   %4d %4d  %4d %4d",
							   minov,maxov,length1,d,beg_s1+1,end_s1+1,beg_s2+1,end_s2+1);
					}
					if(pdata->sov_out==2) {
						printf("\n TEST: minov = %-4d maxov = %-4d length = %-4d d = %-4d   %4d %4d  %4d %4d",
							   minov,maxov,length1,d,beg_s1+1,end_s1+1,beg_s2+1,end_s2+1);
					}
				}
			}
		}
	}
	if(pdata->sov_out==2) {
		printf("\n TEST: Number of considered residues = %d",n);
	}
	if(n>0) {
		out=s/n;
	}
	else {
		out=1.0;
	}
	return out;
}
