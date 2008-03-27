#ifndef ___PHYLIP_FORMAT
#define ___PHYLIP_FORMAT

#include "sequenceContainer1G.h"

class phylipFormat {
public:
	static sequenceContainer1G read(istream &infile, const alphabet* alph);
	static void write(ostream &out, const sequenceContainer1G& sd,
		const int numOfPositionInLine = 50,
		const int spaceEvery = 10);
};

#endif

/* EXAMPLE OF PHYLIP FORMAT:

6   128
Langur     KIFERCELAR TLKKLGLDGY KGVSLANWVC LAKWESGYNT EATNYNPGDE
Baboon     KIFERCELAR TLKRLGLDGY RGISLANWVC LAKWESDYNT QATNYNPGDQ
Human      KVFERCELAR TLKRLGMDGY RGISLANWMC LAKWESGYNT RATNYNAGDR
Rat        KTYERCEFAR TLKRNGMSGY YGVSLADWVC LAQHESNYNT QARNYDPGDQ
Cow        KVFERCELAR TLKKLGLDGY KGVSLANWLC LTKWESSYNT KATNYNPSSE
Horse      KVFSKCELAH KLKAQEMDGF GGYSLANWVC MAEYESNFNT RAFNGKNANG

           STDYGIFQIN SRYWCNNGKP GAVDACHISC SALLQNNIAD AVACAKRVVS
           STDYGIFQIN SHYWCNDGKP GAVNACHISC NALLQDNITD AVACAKRVVS
           STDYGIFQIN SRYWCNDGKP GAVNACHLSC SALLQDNIAD AVACAKRVVR
           STDYGIFQIN SRYWCNDGKP RAKNACGIPC SALLQDDITQ AIQCAKRVVR
           STDYGIFQIN SKWWCNDGKP NAVDGCHVSC SELMENDIAK AVACAKKIVS
           SSDYGLFQLN NKWWCKDNKR SSSNACNIMC SKLLDENIDD DISCAKRVVR

           DQGIRAWVAW RNHCQNKDVS QYVKGCGV
           DQGIRAWVAW RNHCQNRDVS QYVQGCGV
           DQGIRAWVAW RNRCQNRDVR QYVQGCGV
           DQGIRAWVAW QRHCKNRDLS GYIRNCGV
           EQGITAWVAW KSHCRDHDVS SYVEGCTL
           DKGMSAWKAW VKHCKDKDLS EYLASCNL


*/

