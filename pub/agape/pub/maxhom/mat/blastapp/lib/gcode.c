#include <ncbi.h>
#include "blastapp.h"
#include "aabet.h"
#include "ntbet.h"
#include "gcode.h"

int LIBCALL
display_gcodes(fp)
	FILE	*fp;
{
	register int    i;
 
	if (fp == NULL)
		return 0;
	fprintf(fp, "The available genetic codes are:\n");
	for (i=0; i<DIM(gcodes); ++i)
		fprintf(fp, "  %d. %s\n", gcodes[i].id, gcodes[i].name);
	fprintf(fp, "Specify a particular code by its number (%d is the default)\n",
		DEFAULT_C);
	return ferror(fp);
}

GenCodePtr
find_gcode(id)
	int	id;
{
	int	i;

	for (i = 0; i < DIM(gcodes); ++i)
		if (gcodes[i].id == id)
			return &gcodes[i];

	return NULL;
}
/* -----------------------   initialize a genetic code   -------------------*/
void
init_gcode(gp, xltab, rcxltab)
    GenCodePtr  gp;
    register unsigned char   xltab[64], rcxltab[64];
{
    register char   *code;
    register int    i, j, k, tot;
    /* gctrans -- used to translate from the binary alphabet used in ntbet.h
    into a binary alphabet appropriate for the GenCode strings */
    static unsigned char    gctrans[] = { '\003', '\001', '\000', '\002' };

    code = gp->code;

    for (i=0; i<4; ++i) {
        for (j=0; j<4; ++j) {
            for (k=0; k<4; ++k, ++code) {
                tot = gctrans[i]*4*4 + gctrans[j]*4 + gctrans[k];
                xltab[tot] = aa_atob[*code];
                tot = (3-gctrans[i])*4*4 + (3-gctrans[j])*4 + (3-gctrans[k]);
                rcxltab[tot] = aa_atob[*code];
            }
        }
    }    

	return;
}



/*
codon2aa

Translate 3 binary-encoded nucleotides (n1, n2, and n3) into a binary
amino acid in the specified genetic code.
*/
BLAST_Letter
codon2aa( UcharPtr gcode, BLAST_Letter n1, BLAST_Letter n2, BLAST_Letter n3)
{
	BLAST_Letter	aa;
	BLAST_Letter	b1, b2, b3;
	int	i1, i2, i3;

    if (n1 < 4 && n2 < 4 && n3 < 4)
        return (BLAST_Letter)gcode[n1*4*4 + n2*4 + n3];

    if (n1 >= NUCID_MAX || n2 >= NUCID_MAX || n3 >= NUCID_MAX)
        return aa_atob[UNKNOWN_AA_CHR];

	b1 = nt_bdegen[n1].list[0];
	b2 = nt_bdegen[n2].list[0];
	b3 = nt_bdegen[n3].list[0];
	aa = gcode[b1*4*4 + b2*4 + b3];

	for (i1=0; i1 < nt_bdegen[n1].ndegen; ++i1) {
		b1 = nt_bdegen[n1].list[i1]*4*4;
		for (i2=0; i2 < nt_bdegen[n2].ndegen; ++i2) {
			b2 = b1 + nt_bdegen[n2].list[i2]*4;
			for (i3=0; i3 < nt_bdegen[n3].ndegen; ++i3) {
				b3 = nt_bdegen[n3].list[i3];
				if (gcode[b2 + b3] != aa)
					return aa_atob[UNKNOWN_AA_CHR];
			}
		}    
	}
	return aa;
	/*NOTREACHED*/
}
