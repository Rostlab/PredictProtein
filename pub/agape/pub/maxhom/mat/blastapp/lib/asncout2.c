#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN2
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN2

AsnTypePtr LIBCALL
Bio_RequestFindType(choice)
	BSRV_Request	choice;
{
	AsnTypePtr	atp;

	switch (choice) {
	default:
		atp = NULL;
		break;
	case Request_hello:
		atp = BLAST0_REQUEST_hello;
		break;
	case Request_motd:
		atp = BLAST0_REQUEST_motd;
		break;
	case Request_session_get:
		atp = BLAST0_REQUEST_session_get;
		break;
	case Request_session_set:
		atp = BLAST0_REQUEST_session_set;
		break;
	case Request_prog_info:
		atp = BLAST0_REQUEST_prog_info;
		break;
	case Request_db_info:
		atp = BLAST0_REQUEST_db_info;
		break;
	case Request_search:
		atp = BLAST0_REQUEST_search;
		break;
	case Request_goodbye:
		atp = BLAST0_REQUEST_goodbye;
		break;
	}

	return atp;
}

AsnTypePtr LIBCALL
RequestEnter(aip, choice)
	AsnIoPtr	aip;
	BSRV_Request	choice;
{
	AsnTypePtr	atp;

	atp = Bio_RequestFindType(choice);
	if (atp == NULL)
		return NULL;
	if (AsnWriteChoice(aip, BLAST0_REQUEST, choice, NULL) != 0)
		return atp;
	return NULL;
}

int LIBCALL
RequestExit(aip, choice)
	AsnIoPtr	aip;
	BSRV_Request	choice;
{
	if (aip == NULL)
		return -1;
	AsnPrintNewLine(aip);
	AsnIoFlush(aip);
	return 0;
}

int LIBCALL
RequestHelloAsnWrite(aip, hello)
	AsnIoPtr	aip;
	CharPtr	hello;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = -1;

	if (aip == NULL)
		return retval;

	atp = RequestEnter(aip, Request_hello);
	if (atp == NULL)
		return retval;

	if (hello == NULL)
		hello = "";
	av.ptrvalue = hello;
	if (AsnWrite(aip, atp, &av) == 0)
		goto Error;

	if (RequestExit(aip, Request_hello) < 0)
		goto Error;
	retval = 0;

Error:
	return retval;
}

int LIBCALL
RequestSearchAsnWrite(aip, program, database, qp, options)
	AsnIoPtr	aip;
	CharPtr	program;
	CharPtr	database;
	BSRV_QueryPtr	qp;
	ValNodePtr	options;
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = -1;

	if (aip == NULL || program == NULL || database == NULL || qp == NULL)
		return -1;

	if ((atp = RequestEnter(aip, Request_search)) == NULL)
		goto Error;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.ptrvalue = program;
	if (AsnWrite(aip, BLAST0_SEARCH_program, &av) == 0)
		goto Error;

	av.ptrvalue = database;
	if (AsnWrite(aip, BLAST0_SEARCH_database, &av) == 0)
		goto Error;

	if (QueryAsnWrite(aip, BLAST0_SEARCH_query, qp, 1) != 0)
		goto Error;

	if (options != NULL) {
		if (AsnOpenStruct(aip, BLAST0_SEARCH_options, NULL) == 0)
			goto Error;
		while (options != NULL) {
			av.ptrvalue = options->data.ptrvalue;
			if (av.ptrvalue != NULL) {
				if (AsnWrite(aip, BLAST0_SEARCH_options_E, &av) == 0)
					goto Error;
			}
			options = options->next;
		}
		if (AsnCloseStruct(aip, BLAST0_SEARCH_options, NULL) == 0)
			goto Error;
	}

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	RequestExit(aip, Request_search);
	retval = 0;

Error:
	return retval;
}

#endif /* BLASTASN2 */
