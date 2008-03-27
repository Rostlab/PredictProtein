#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

/* ckalloc - allocate space; check for success */
VoidPtr
ckalloc(amount)
	size_t	amount;
{
	register VoidPtr	p;

	if ((p = (VoidPtr)mem_malloc(amount)) != NULL)
		return p;
	if (amount == 0)
		return NULL;
	bfatal(ERR_MEM, "ckalloc: Ran out of memory (requested %lu bytes)",
		(unsigned long)amount);
}


/* ckalloc0 - allocate space and initialize to zero */
VoidPtr
ckalloc0(amount)
	register size_t	amount;
{
	register VoidPtr	p;

	p = ckalloc(amount);
	Nlm_MemSet(p, 0, amount);
	return p;
}

VoidPtr
ckrealloc(ptr, amount)
	VoidPtr	ptr;
	size_t	amount;
{
	VoidPtr	p;

	p = mem_realloc(ptr, amount);
	if (p != NULL)
		return p;
	if (amount == 0)
		return NULL;
	bfatal(ERR_MEM, "ckrealloc: Ran out of memory (requested %lu bytes)",
		(unsigned long)amount);
}
