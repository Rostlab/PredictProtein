#ifndef ___CLUSTAL_FORMAT
#define ___CLUSTAL_FORMAT

#include "sequenceContainer1G.h"
#include "sequenceFormat.h"

class clustalFormat{
public:
	static sequenceContainer1G read(istream &infile, const alphabet* alph);
	static void write(ostream &out, const sequenceContainer1G& sd);
};

#endif

/* EXAMPLE OF THE FORMAT:
CLUSTAL V


Langur           KIFERCELARTLKKLGLDGYKGVSLANWVCLAKWESGYNTEATNYNPGDESTDYGIFQIN
Baboon           KIFERCELARTLKRLGLDGYRGISLANWVCLAKWESDYNTQATNYNPGDQSTDYGIFQIN
Human            KVFERCELARTLKRLGMDGYRGISLANWMCLAKWESGYNTRATNYNAGDRSTDYGIFQIN
Rat              KTYERCEFARTLKRNGMSGYYGVSLADWVCLAQHESNYNTQARNYDPGDQSTDYGIFQIN
Cow              KVFERCELARTLKKLGLDGYKGVSLANWLCLTKWESSYNTKATNYNPSSESTDYGIFQIN
Horse            KVFSKCELAHKLKAQEMDGFGGYSLANWVCMAEYESNFNTRAFNGKNANGSSDYGLFQLN


Langur           SRYWCNNGKPGAVDACHISCSALLQNNIADAVACAKRVVSDQGIRAWVAWRNHCQNKDVS
Baboon           SHYWCNDGKPGAVNACHISCNALLQDNITDAVACAKRVVSDQGIRAWVAWRNHCQNRDVS
Human            SRYWCNDGKPGAVNACHLSCSALLQDNIADAVACAKRVVRDQGIRAWVAWRNRCQNRDVR
Rat              SRYWCNDGKPRAKNACGIPCSALLQDDITQAIQCAKRVVRDQGIRAWVAWQRHCKNRDLS
Cow              SKWWCNDGKPNAVDGCHVSCSELMENDIAKAVACAKKIVSEQGITAWVAWKSHCRDHDVS
Horse            NKWWCKDNKRSSSNACNIMCSKLLDENIDDDISCAKRVVRDKGMSAWKAWVKHCKDKDLS


Langur           QYVKGCGV
Baboon           QYVQGCGV
Human            QYVQGCGV
Rat              GYIRNCGV
Cow              SYVEGCTL
Horse            EYLASCNL


*/
