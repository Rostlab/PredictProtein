#include "HMMOutput.h"

void PrintScore(ostream& of,Seq& S){
	of<<S.scl.SeqID<<'\t'<<S.scl.Seqlen<<'\t'
	  <<S.scl.P_log<<endl;
}

void PrintID(Seq& S) {cout<<S.scl.SeqID<<endl;}

void PrintPaths(ostream& of,Seq& S){
	uint t;
	of<<S.scl.Seqlen<<" label\t";
	for (t=0;t<S.scl.Seqlen;t++) of<<S.row[t].cln[0];
	of<<endl<<S.scl.Seqlen<<" pred\t";
	for (t=0;t<S.scl.Seqlen;t++) of<<S.row[t].cpn[0];
	of<<endl;
}	


void PrintLabel(ostream& of,Seq& S){
	uint t;
	of<<S.scl.SeqID<<" label\t";
	
	for (t=0;t<S.scl.Seqlen;t++)
		of<<Par::StatesEval[Par::ReduxEval[S.row[t].act_ian]][0];

	of<<endl;
}	


void PrintPred2(ostream& of,Seq& S){
	uint t;

	of<<S.scl.SeqID<<" pred\t";
	for (t=0;t<S.scl.Seqlen;t++)
		of<<Par::StatesEval[Par::ReduxEval[S.row[t].pred_ian]][0];
	
	of<<endl;
}	


void PrintRdb(ostream& of,Seq& S,bool withSeqQ){
	uint t;
	of<<S.scl.SeqID<<'\t'<<S.scl.Score<<'\t';
	if (withSeqQ){
		for (t=0;t<S.scl.Seqlen;t++)
			of<<Par::StatesEval[Par::ReduxEval[S.row[t].pred_ian]][0];
	}
	of<<'\t'<<S.scl.AASeq<<endl;
}

void PrintPretty(ostream& of,Seq& S,bool withSeqQ){
	//of<<"Protein ID     : "<<S.scl.SeqID<<endl;
	of<<"Score (Z-value):\t"<<S.scl.Score<<endl
	  <<endl;
	int ctr,chunksize=50,min=0;
	int max;
	bool finishedQ=false;
	
	if (withSeqQ){
		while (! finishedQ){
			if ((min+chunksize)<(int)S.scl.Seqlen) max=min+chunksize;
			else {
				max=S.scl.Seqlen;
				finishedQ=true;
			}
			of<<"Sequence       :\t";
			for (ctr=min;ctr<max;ctr++) of<<S.scl.AASeq[ctr];
			of<<endl;
			of<<"Prediction     :\t";
			for (ctr=min;ctr<max;ctr++) 
				of<<Par::StatesEval[Par::ReduxEval[S.row[ctr].pred_ian]][0];
			of<<endl<<endl;
			min=max;
		}
	}
	else {
		while (! finishedQ){
			if ((min+chunksize)<(int)S.scl.Seqlen) max=min+chunksize;
			else {
				max=S.scl.Seqlen;
				finishedQ=true;
			}
			of<<"Sequence       :\t";
			for (ctr=min;ctr<max;ctr++)
				of<<S.scl.AASeq[ctr];
			of<<endl;
			min=max;
		}
		of<<"Prediction     :\t"
		  <<"---Below-threshold protein.  No prediction provided---"
		  <<endl;
	}
	of<<endl;
}

void PrintPred(ostream& of,Seq& S){
	uint t;
	of<<S.scl.SeqID<<" pred\t";
	for (t=0;t<S.scl.Seqlen;t++) of<<S.row[t].cpn[0];
	of<<endl;
}	
	

void PrintArch(ostream& of,Par& M){
	uint s_ian,ind,ntar;
	string san;
	for (s_ian=0;s_ian<Par::NumA;s_ian++){
		ntar=M.ArchSize[s_ian].ntar;
		if (ntar>0){
			san=Par::SANrev[s_ian];
			of<<san<<'\t';
			for (ind=0;ind<ntar-1;ind++){
				san=Par::SANrev[M.Arch[s_ian][ind].node];
				of<<san<<'\t';
			}
			san=Par::SANrev[M.Arch[s_ian][ntar-1].node];
			of<<san<<endl;
		}
	}
	of.unsetf(ios::showpoint | ios::left);
	of.flush();
}


void PrintTrans(ostream& of,Par& M){
	//Prints the parameters of model M:
	//Pi, Ep, EmitAmino, and Arch
	int ian,ian_src,cur_tar,n;
	of<<"pi\t";
	for (ian=0;ian<(int)Par::NumA-1;ian++) of<<M.Pi[ian]<<'\t';
	of<<M.Pi[Par::NumA-1]<<endl;
	for (ian_src=0;ian_src<(int)Par::NumA;ian_src++){
		of<<"from"<<ian_src<<'\t';
		n=0;
		for (cur_tar=0;cur_tar<(int)Par::NumA;cur_tar++){
			if (n<(int)M.ArchSize[ian_src].ntar &&
				cur_tar==(int)M.Arch[ian_src][n].node){
				of<<M.Arch[ian_src][n].score<<'\t';
				n++;
			}
			else of<<0.0<<'\t';
		}
		of<<endl;
	}
	of<<"ep\t";
	for (ian=0;ian<(int)Par::NumA-1;ian++) of<<M.Ep[ian]<<'\t';
	of<<M.Ep[Par::NumA-1]<<endl;
}


void PrintEmit(ostream& of,Par& M){
	int ian,ien,c;
	of<<"Symbols\t";
	for (c=0;c<(int)Par::NUMAMINO-1;c++) of<<Par::AminoMapRev[c]<<'\t';
	of<<Par::AminoMapRev[Par::NUMAMINO-1]<<endl;
	for (ian=0;ian<(int)Par::NumA;ian++){
		ien=Par::A2E[ian];
		of<<Par::SANrev[ian]<<'\t';
		for (c=0;c<(int)Par::NUMAMINO-1;c++)
			of<<M.EmitAmino[ien][c]<<'\t';
		of<<M.EmitAmino[ien][Par::NUMAMINO-1]<<endl;
	}
}


void PrintEmitLogOdds(ostream& of,Par& M,float minbits){
	int ian,ien,c;
	float bits;
	of<<"Bits\t";
	for (c=0;c<(int)Par::NUMAMINO-1;c++) of<<Par::AminoMapRev[c]<<'\t';
	of<<Par::AminoMapRev[Par::NUMAMINO-1]<<endl;
	for (ian=0;ian<(int)Par::NumA;ian++){
		ien=Par::A2E[ian];
		of<<Par::SANrev[ian]<<'\t';
		for (c=0;c<(int)Par::NUMAMINO-1;c++){
			if (M.EmitAmino[ien][c]==0.0) bits=minbits;
			else bits=log(M.EmitAmino[ien][c]/Par::AAComp[c])/log(2);
			if (bits<0.0) bits=0;
			of<<bits<<'\t';
		}
		if (M.EmitAmino[ien][Par::NUMAMINO-1]==0.0) bits=minbits;
		else bits=log(M.EmitAmino[ien][Par::NUMAMINO-1]/
					  Par::AAComp[Par::NUMAMINO-1])/log(2);
		if (bits<0.0) bits=0;
		of<<bits<<endl;
	}
}


void DisplayArch(ostream& of,Par& M,uint ct,char* pfx){
	uint s_ian,ind,ntar;
	string san;
	of.setf(ios::showpoint | ios::left);
	for (s_ian=0;s_ian<Par::NumA;s_ian++){
		ntar=M.ArchSize[s_ian].ntar;
		if (ntar>0){
			san=Par::SANrev[s_ian];
			san+='\0';
			of.width(15);
			of<<pfx<<' '<<ct<<' ';
			of.width(5);
			of<<san.data()<<' ';
			for (ind=0;ind<ntar-1;ind++){
				san=Par::SANrev[M.Arch[s_ian][ind].node];
				san+='\0';
				of<<san.data()<<' ';
				of.precision(3);
				of<<M.Arch[s_ian][ind].score<<' ';
			}
			san=Par::SANrev[M.Arch[s_ian][ntar-1].node];
			san+='\0';
			of<<san.data()<<' ';
			of.precision(3);
			of<<M.Arch[s_ian][ntar-1].score<<endl;
		}
	}
	of.unsetf(ios::showpoint | ios::left);
	of.flush();
}


void PrintEmit(ostream& of,Par& M,uint ct,char* pfx){
	uint ien,c;
	string sen;
	of.setf(ios::showpoint | ios::left);
	for (ien=0;ien<Par::NumE;ien++){
		sen=Par::SENrev[ien];
		sen+='\0';
		of.width(20);
		of<<pfx<<" "<<ct<<" ";
		of.width(20);
		of<<sen.data();
		for (c=0;c<Par::NUMAMINO-1;c++){
			of.width(12);
			if (M.EmitAmino[ien][c]==0) of<<"-";
			else {
				of.precision(3);
				of<<M.EmitAmino[ien][c];
			}
		}
		of.width(12);
		of.precision(3);
		if (M.EmitAmino[ien][Par::NUMAMINO-1]==0.0) of<<'-'<<endl;
		else of<<M.EmitAmino[ien][Par::NUMAMINO-1]<<endl;
	}
	of.flush();
	of.unsetf(ios::showpoint | ios::left);
}


