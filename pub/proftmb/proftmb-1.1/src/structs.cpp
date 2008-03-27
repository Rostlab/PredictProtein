#include "structs.h"

ostream& operator<<(ostream& out,names& n){
	out<<"iln="<<n.iln<<", ian="<<n.ian;
	out<<", ien="<<n.ien<<", sln="<<n.sln;
	out<<", san="<<n.san<<", cln="<<n.cln;
	out<<", betaQ="<<n.betaQ;
	return out;
}


ostream& operator<<(ostream& out,evaldat& ev){
	string twoclass;
	ev.posQ ? twoclass="positive" : twoclass="negative";
	out<<ev.cl<<'\t'<<twoclass<<'\t'<<ev.id
	   <<'\t'<<ev.length;
	return out;
}


ostream& operator<<(ostream& out,triplet& tr){
	out<<tr.cl<<'\t'<<tr.sco<<'\t'<<tr.cov;
	return out;
}


triplet::triplet(string c,double s,double co):
	cl(c),sco(s),cov(co){}
