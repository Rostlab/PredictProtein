#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#include "blastapp.h"

/*
	query_ack -- acknowledge the query sequence
*/
void
query_ack(sp, strands)
	BLAST_StrPtr	sp;
	int		strands; /* 0 => protein, 1=>top, 2=>bottom, 3=>both */
{
	FILE	*fp;
	BSRV_Query	query;
	CharPtr	title;
	long	qlen;

	title = sp->name;
	qlen = sp->len;

	if ((fp = b_out.fp) != NULL) {
		CharPtr	cp;
		int		idlen, titlelen;

		titlelen = strlen(title);
		cp = str_chr(title, ' ');
		if (cp != NULL)
			idlen = cp - title;
		else
			idlen = titlelen;
		putc('\n', fp);
		wrap(fp, "Query=  ", title, titlelen, 79, idlen+1);
		fprintf(fp, "        (%s letters", Ltostr(qlen,1));
		if (sp->offset != 0)
			fprintf(fp, ", %s offset", Ltostr(sp->offset,1));
		fprintf(fp, ")\n");
		if (qusage[0] != qusage[1]) {
			fprintf(fp, "\n  Translating ");
			switch (strands) {
			case 0:
				break;
			case 1:
				fprintf(fp, "top strand of query sequence in 3 reading frames\n");
				break;
			case 2:
				fprintf(fp, "bottom strand of query sequence in 3 reading frames\n");
				break;
			case 3:
				fprintf(fp, "both strands of query sequence in all 6 reading frames\n");
				break;
			default:
				break;
			}
		}
	}
#ifdef BLASTASN
	MemSet((VoidPtr)&query, 0, sizeof query);
	query.sp = sp;
	Bio_QueryAsnWrite(&b_out, &query, 0);
#endif

	return;
}
