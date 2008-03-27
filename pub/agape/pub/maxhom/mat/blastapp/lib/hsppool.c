#include <ncbi.h>
#include <gishlib.h>
#include <blastapp.h>

HSPPoolPtr
HSPPoolNew()
{
	return (HSPPoolPtr) PoolNew(1000, sizeof(HSP), offsetof(HSP,next), NULL);
}

void
HSPPoolDestruct(poolp)
	HSPPoolPtr	poolp;
{
	PoolDestruct((PoolBlkPtr)poolp);
}


HSPPtr
HSPPoolGet(poolp)
	HSPPoolPtr	poolp;
{
	return PoolGet((PoolBlkPtr)poolp);
}

/* HSPPoolReturn -- put hp back on the list of available HSP storage */
void
HSPPoolReturn(poolp, hp)
	register HSPPoolPtr	poolp;
	register HSPPtr	hp;
{
	PoolPut((PoolBlkPtr)poolp, (VoidPtr)hp);
}

/* HSPPoolReturnList -- put an entire HSP list back into the free pool */
void
HSPPoolReturnList(poolp, hp)
	register HSPPoolPtr	poolp;
	register HSPPtr	hp;
{
	PoolPutLink((PoolBlkPtr)poolp, (VoidPtr)hp);
}
