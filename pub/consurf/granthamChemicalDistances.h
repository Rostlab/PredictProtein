/******************************************************************************
*                                                                             *
* This file is part of SEMPHY - Structural EM for PHYlogenetic reconstruction *
* This is unpublished proprietary source code it's authors                    *
*                                                                             *
* The contents of these coded instructions, statements and computer           *
* programs may not be disclosed to third parties, copied or duplicated in     *
* any form, in whole or in part, without the prior written permission of      *
* the authors.                                                                *
*                                                                             *
* (C) COPYRIGHT Nir Friedman, Matan Ninio,  Itsik Pe'er and Tal Pupko, 2001   *
* All Rights Reserved                                                         *
*                                                                             *
* for information please contact semphy@cs.huji.ac.il                         *
*                                                                             *
******************************************************************************/
#ifndef ___GRANTHAM_CHEMICAL_DISTANCES
#define ___GRANTHAM_CHEMICAL_DISTANCES

#include "definitions.h"

class granthamChemicalDistances {
public:
	explicit granthamChemicalDistances();
	MDOUBLE getGranthamDistance(const int aa1,const int aa2) const ;
	MDOUBLE getGranthamPolarityDistance(const int aa1,const int aa2) const;
	MDOUBLE getGranthamPolarity(const int aa1) const;
	virtual ~granthamChemicalDistances() {}

	MDOUBLE getHughesChargeDistance(const int aa1,const int aa2) const;// page 520
	MDOUBLE getHughesPolarityDistance(const int aa1,const int aa2) const;// page 520
	MDOUBLE getHughesHydrophobicityDistance(const int aa1,const int aa2) const;// page 520


private:

	// private members:
	MDOUBLE GranChemDist[20][20];
	MDOUBLE GranPolarityTable[20];

};


#endif


