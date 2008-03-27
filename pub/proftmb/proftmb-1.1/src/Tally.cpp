#include "TrainSeq.h"
#include "Tools.h"
#include "Par.h"
#include <set>


void Par::Allocate(uint numA,uint numE) {
	uint i,ev,c;
	
	//allocate EmitAmino
	this->EmitAmino.resize(numE);
	for (i=0;i<numE;i++){
		this->EmitAmino[i].resize(NUMAMINO);
		for (c=0;c<NUMAMINO;c++)
			this->EmitAmino[i][c]=0.0;
	}

	//allocate EmitProf,P
	this->EmitProf.resize(numE);
	this->P.resize(numE);
	for (i=0;i<numE;i++){
		this->EmitProf[i].H.resize(NLProf);
		this->EmitProf[i].E.resize(NLProf);
		this->EmitProf[i].L.resize(NLProf);
		this->P[i].H.resize(NLProf);
		this->P[i].E.resize(NLProf);
		this->P[i].L.resize(NLProf);
		for (ev=0;ev<NLProf;ev++){
			this->EmitProf[i].H[ev]=0.0;
			this->EmitProf[i].E[ev]=0.0;
			this->EmitProf[i].L[ev]=0.0;
			this->P[i].H[ev]=0.0;
			this->P[i].E[ev]=0.0;
			this->P[i].L[ev]=0.0;
		}
	}
	
	//allocate A,C,Arch
	A.resize(numA);
	C.resize(numE);
	for (i=0;i<numE;i++) C[i].resize(NUMAMINO);

	Arch.resize(numA);
	ArchRev.resize(numA);
	ArchSize.resize(numA);
	Pi.resize(numA);
	Ep.resize(numA);
	for (i=0;i<numA;i++) A[i].resize(numA);

}


void Par::TallyA(vector<TrainSeq>& tsq,string& ex){
	//tallies ML counts for architecture.
	//uses LA to find all SAN's from SLN's
	//only tallies SAN->SAN transitions found
	//in the architecture

	vector<vector<double> >atally(NumA); //atally[src_ian][tar_ian]=ct
	vector<double>beg_tally(NumA);
	vector<double>end_tally(NumA);
	uint i,j,s,t,T,iln,ian,s_ian,t_ian,src_iln,tar_iln;

	for (i=0;i<NumA;i++) {
		beg_tally[i]=0.0;
		end_tally[i]=0.0;
		atally[i].resize(NumA); //square matrix
		for (j=0;j<NumA;j++) atally[i][j]=0.0; //really used as int
	}

	//count up all transitions between a src_iln and tar_iln
	for (s=0;s<tsq.size();s++){
		if (tsq[s].scl.SeqID==ex) continue; //exclude sequence
		T=tsq[s].scl.Seqlen;
		
		//count initial transition from begin state:
		iln=tsq[s].row[0].iln;
		for (ian=0;ian<NumA;ian++)
			if (LA[iln][ian]) beg_tally[ian]++;
		
		//continue
		for (t=1;t<T;t++){
			src_iln=tsq[s].row[t-1].iln;
			tar_iln=tsq[s].row[t].iln;
			UpdateA(atally,src_iln,tar_iln);
   			//UpdateA2(atally,src_iln,tar_iln);

		}
		
		//count transition to end state:
		iln=tsq[s].row[T-1].iln;
		for (ian=0;ian<NumA;ian++)
			if (LA[iln][ian]) end_tally[ian]++;
	}
	
	//normalize atally,beg_tally,end_tally
	Normalize(&beg_tally[0],beg_tally.size());
	Normalize(&end_tally[0],end_tally.size());
	for (ian=0;ian<NumA;ian++){
		BoolNormalize(&atally[ian][0],atally[ian].size());
		// 			cerr<<"TallyA: node "<<ian<<"("<<SANrev[ian]
		// 				<<") has no targets"<<endl;
	}
	//since CA only appears at the very end

	//assign to Arch,Pi,Ep
	for (s_ian=0;s_ian<NumA;s_ian++){
		Pi[s_ian]=beg_tally[s_ian];
		Ep[s_ian]=end_tally[s_ian];
		for (t_ian=0;t_ian<NumA;t_ian++)
			if (atally[s_ian][t_ian]!=0.0){
				Arch[s_ian].push_back(archpair(t_ian,atally[s_ian][t_ian]));
				//cout<<"atally["<<SANrev[s_ian]<<"]["<<
				//SANrev[t_ian]<<"]="<<atally[s_ian][t_ian]<<endl;
			}
	}
}


void Par::InitArchRev(){
	//for every Arch[ian_src][n]=<ian_trg,score>
	//create ArchRev[ian_trg][m]=<ian_src,n>

	uint ian_src,ian_trg,n;
	for (ian_src=0;ian_src<Arch.size();ian_src++)
		
		//iterate over Arch[ian_src][n] until we find the null target
		for (n=0;n<Arch[ian_src].size();n++){
			ian_trg=Arch[ian_src][n].node;
			ArchRev[ian_trg].push_back(revpair(ian_src,n));
			//cout<<"ArchRev["<<ian_trg<<"]<-"<<ian_src<<", "<<n<<endl;
		}
}


void Par::InitArchSize(){
	//initialize ArchSize[j]=<nsrc,ntar>
	uint i;
	for (i=0;i<NumA;i++){
		ArchSize[i].nsrc=ArchRev[i].size();
		ArchSize[i].ntar=Arch[i].size();
	}
}


void Par::UpdateA(vector<vector<double> >& atally,
				  uint s_iln,uint t_iln){
	//updates the ML count of transitions for
	//all src_ian's and tar_ian's corresponding
	//to s_iln and t_iln which are consistent
	//with the pre-specified architecture as stored
	//in Connect[src_ian] (map<string,set<string> >)
	
	uint s_ian,t_ian;
	for (s_ian=0;s_ian<NumA;s_ian++) {
		if (!LA[s_iln][s_ian]) continue;
		for (t_ian=0;t_ian<NumA;t_ian++){
			if (!LA[t_iln][t_ian]) continue; //this stuff is expensive
			if (Connect[s_ian].find(t_ian)==
				Connect[s_ian].end()) {
				continue;
			}
			atally[s_ian][t_ian]++;
		}
	}	
}


void Par::UpdateA2(vector<vector<double> >& atally,
				  uint s_iln,uint t_iln){
	//updates the ML count of transitions for
	//all s_ian's and t_ian's corresponding
	//to s_iln and t_iln using the 'forward connecting'
	//rule, namely that t_ian must be greater than
	//s_ian
	
	uint s_ian,t_ian;
	for (s_ian=0;s_ian<NumA;s_ian++) {
		if (!LA[s_iln][s_ian]) continue;
		for (t_ian=0;t_ian<NumA;t_ian++){
			if (!LA[t_iln][t_ian]) continue; //this stuff is expensive
			if (s_iln==t_iln && s_ian>t_ian) continue;
			//forward or self connections of
			//iso-labeled arch nodes
			atally[s_ian][t_ian]++;
		}
	}	
}


void Par::TallyE(vector<TrainSeq>& tsq,string& ex){
	//need a way to check if ien was seen or not.
	//todo: a way to individually train params on other data

	set<int>seen_ien;
	vector<vector<double> >etally(NumE); //etally[ien][c]=ct
	uint s,t,c,ian,iln,ien,D=tsq.size();

	//allocate and initialize etally and ptally to zero
	for (ien=0;ien<NumE;ien++) {
		etally[ien].resize(NUMAMINO); //NumE x NUMAMINO matrix
		for (c=0;c<NUMAMINO;c++) etally[ien][c]=0.0; //really used as int
	}
	
	//tally profile for each ien,c and prof counts
	for (s=0;s<D;s++){
		if (tsq[s].scl.SeqID==ex) continue; //exclude sequence
		for (t=0;t<tsq[s].scl.Seqlen;t++){
			iln=tsq[s].row[t].iln;
			seen_ien.clear();
			for (ian=0;ian<NumA;ian++){
				if (!LA[iln][ian]) continue;
				ien=A2E[ian];
				
				//here we have a convoluted
				//way to check which iens correspond
				//to the iln labelling
				if (seen_ien.find(ien)==seen_ien.end()){
					seen_ien.insert(ien);
					for (c=0;c<NUMAMINO;c++) //train on profile?
						etally[ien][c]+=tsq[s].Profile[t][c];
				}
			}
		}
	}

	for (ien=0;ien<NumE;ien++){
		
		//etally[ien] can be the zero vector in the case when
		//the sequence excluded from the tally is solely
		//responsible for the ien.  this is very unlikely
		//if NumE is small (few emission states)
		
		//normalize and load into EmitAmino[ien][c]
		BoolNormalize(&etally[ien][0],etally[ien].size());
		//cerr<<"TallyE: no counts for "<<SENrev[ien]<<endl;

		for (c=0;c<NUMAMINO;c++)
			this->EmitAmino[ien][c]=etally[ien][c];
		
	}
}


void Par::TallyP(vector<TrainSeq>& tsq,string& ex){
	//need a way to check if ien was seen or not.
	//todo: a way to individually train params on other data

	set<int>seen_ien;
	vector<vector<vector<double> > >ptally(NumE); //ptally[ien][th][ev]
	uint s,t,th,ev,ian,iln,ien,D=tsq.size();

	//allocate and initialize etally and ptally to zero
	for (ien=0;ien<NumE;ien++) {
		ptally[ien].resize(3); //HARDCODED

		for (th=0;th<3;th++) {
			ptally[ien][th].resize(NLProf);
			for (ev=0;ev<NLProf;ev++)
				ptally[ien][th][ev]=0.0;
		}
	}
	
	//tally profile for each ien,c and prof counts
	for (s=0;s<D;s++){
		if (tsq[s].scl.SeqID==ex) continue; //exclude sequence
		for (t=0;t<tsq[s].scl.Seqlen;t++){
			iln=tsq[s].row[t].iln;
			seen_ien.clear();
			for (ian=0;ian<NumA;ian++){
				if (!LA[iln][ian]) continue;
				ien=A2E[ian];

				//here we have a convoluted
				//way to check which iens correspond
				//to the iln labelling
				if (seen_ien.find(ien)==seen_ien.end()){
					seen_ien.insert(ien);
					ptally[ien][0][tsq[s].row[t].lH]++;
					ptally[ien][1][tsq[s].row[t].lE]++;
					ptally[ien][2][tsq[s].row[t].lL]++;
				}
			}
		}
	}

	//normalize prof and load into EmitProf
	for (ien=0;ien<NumE;ien++){
		for (th=0;th<3;th++)
			BoolNormalize(&ptally[ien][th][0],ptally[ien][th].size());
		
		for (ev=0;ev<NLProf;ev++){
			EmitProf[ien].H[ev]=ptally[ien][0][ev];
			EmitProf[ien].E[ev]=ptally[ien][1][ev];
			EmitProf[ien].L[ev]=ptally[ien][2][ev];
		}
	}
}
