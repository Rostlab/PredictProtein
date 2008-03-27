#include <iostream>
#include <iomanip>
#include "Output.h"
#include "Tools.h"

void PrintResults(ostream& of,double Q2,double Qbetapred,
				  double Qbetaobs,double MCC,
				  double sov_all,double sov_beta,
				  double trn,double tst){
	of.setf(ios::showpoint);
	of<<"Q2="<<setprecision(3)<<100*Q2
	  <<"  Qbetapred="<<setprecision(3)<<100*Qbetapred
	  <<"  Qbetaobs="<<setprecision(3)<<100*Qbetaobs
	  <<"  MCC="<<setprecision(3)<<100*MCC
	  <<"  Sov(A)="<<setprecision(3)<<100*sov_all
	  <<"  Sov(E)="<<setprecision(3)<<100*sov_beta
	  <<"  Train="<<setprecision(8)<<setw(9)<<trn
	  <<"  Test="<<setprecision(8)<<setw(9)<<tst
	  <<endl;
		  
	of.unsetf(ios::showpoint);
	of.flush();
}


void PrintKaleida(const char* fname,map<string,
				  vector<pair<double,double> > >&dat,
				  char* fir,char* sec){
	//KaleidaGraph format, tab separated with space placeholders
	//takes dat, prints out a vertical rdb using the key of
	//each map as the label of each column, and the remainder
	//of the column as the entries in the array
	//char dos_endl='\n';
	cout<<"Printing "<<fname<<endl;
	ofstream of(fname);
	multimap<uint,string,greater<uint> > key_ord=SortMapRev(dat);
	multimap<uint,string,greater<uint> >::iterator kit;
	bool hasmore=true,found=false;
	int rownum=0;
	int kctr;
	string classdesc;

	//Print Column Titles
	assert(dat.size()>=1);
	kit=key_ord.begin();
	for (kctr=0;kctr<(int)dat.size()-1;kctr++){
		of<<kit->second<<' '<<fir<<'\t'
		  <<kit->second<<' '<<sec<<'\t';
		kit++;
	}
	of<<kit->second<<' '<<fir<<'\t'
	  <<kit->second<<' '<<sec<<endl;

	//Print each Row, inserting blanks where necessary
	//That the last line be blank is unavoidable
	while (hasmore){
		found=false;

		kit=key_ord.begin();
		for (kctr=0;kctr<(int)key_ord.size()-1;kctr++){
			classdesc=kit->second;
			if (rownum<(int)dat[classdesc].size()){
				of<<dat[classdesc][rownum].first<<'\t'
				  <<dat[classdesc][rownum].second<<'\t';
				found=true;
			}

			kit++;
		}
		classdesc=kit->second;

		if (rownum<(int)dat[classdesc].size()){
			of<<dat[classdesc][rownum].first<<'\t'
			  <<dat[classdesc][rownum].second<<endl;
			found=true;
		}
		else of<<endl;
		
		if (! found) hasmore=false;
		rownum++;
	}
	of.close();
}


void PrintKaleida(const char* fname,vector<pair<string,vector<double> > >&dat){
	//KaleidaGraph format, tab separated with space placeholders
	//takes dat, prints out a vertical rdb using the key of
	//each map as the label of each column, and the remainder
	//of the column as the entries in the array
	//char dos_endl='\n';
	cout<<"Printing "<<fname<<endl;
	ofstream of(fname);
	bool hasmore=true,found=false;
	int row=0,col;
	int numcols=(int)dat.size();
	const char dos_newline[]="\r\n";

	//Print Column Titles
	for (col=0;col<numcols-1;col++) of<<dat[col].first<<'\t';
	of<<dat[numcols-1].first<<dos_newline;

	//make a catalog of sizes of each column
	vector<int>colsizes(numcols);
	for (col=0;col<numcols;col++) colsizes[col]=dat[col].second.size();

	//Print each Row, inserting blanks where necessary (last line will be blank)
	while (hasmore){
		found=false;
		for (col=0;col<numcols-1;col++){
			if (row<colsizes[col]) {
				found=true;
				of<<dat[col].second[row]<<'\t';
			}
			else of<<" \t";
		}

		//print last column entry
		if (row<colsizes[numcols-1]) {
			found=true;
			of<<dat[numcols-1].second[row]<<dos_newline;
		}
		else of<<' '<<dos_newline;

		//determine whether to continue
		if (! found) hasmore=false;
		row++;
	}
	of.close();
}



void PrintGnuplot(const char* fname, map<string,vector<pair<double,double> > >&dat,
				  char* fir,char* sec,char* dstyle){
	//Prints Gnuplot formatted inline script+data
	//run as $gnuplot <filename>
	ofstream of(fname);
	string classdesc;
	multimap<uint,string,greater<uint> > key_ord=SortMapRev(dat);
	multimap<uint,string,greater<uint> >::iterator kit;
	int i,kctr;
	of<<"set xlabel \""<<fir<<"\""<<endl
	  <<"set ylabel \""<<sec<<"\""<<endl
	  <<"set data style "<<dstyle<<endl;
		//<<"set xrange [] reverse"<<endl;
	of<<"plot ";
	kit=key_ord.begin();

	for (kctr=0;kctr<(int)key_ord.size()-1;kctr++){
		classdesc=kit->second;
		of<<"'-' title \""<<classdesc<<"\", \\\n";
		kit++;
	}
	of<<"'-' title \""<<kit->second<<"\""<<endl;

	for (kit=key_ord.begin();kit!=key_ord.end();kit++){
		classdesc=kit->second;
		for (i=0;i<(int)dat[classdesc].size();i++)
			of<<dat[classdesc][i].first
			  <<'\t'<<dat[classdesc][i].second<<endl;
		of<<'e'<<endl;
	}
	of.close();
	cout<<"Printed "<<fname<<endl;
}


void PrintGnuplot(const char* fname, 
				  vector<pair<string,vector<double> > >&dat,
				  const char* dstyle){
	//assume data are organized such that every two consecutive
	//categories are the x- and y- coordinates of datapoints

	ofstream of(fname);

	int datum,categ;
	of<<"set data style "<<dstyle<<endl;
		//<<"set xrange [] reverse"<<endl;
	of<<"plot ";

	//check that the size is even
	if (dat.size() & 1)
		Error ("PrintGnuplot: data has odd size ",dat.size());

	int numranges=(int)dat.size()/2;
	int xind,yind;
	for (categ=0;categ<numranges-1;categ++){
		xind=categ*2;
		yind=xind+1;
		of<<"'-' title \""<<dat[yind].first<<"\", \\\n";
	}
	of<<"'-' title \""<<dat[dat.size()-1].first<<"\" \\\n";

	for (categ=0;categ<numranges;categ++){
		xind=categ*2;
		yind=xind+1;
		for (datum=0;datum<(int)dat[xind].second.size();datum++)
			of<<dat[xind].second[datum]<<'\t'
			  <<dat[yind].second[datum]<<endl;
		of<<'e'<<endl;
	}
	of.close();
	cout<<"Printed "<<fname<<endl;
}


void PrintTable(vector<vector<int> >&table,vector<string>&labels,ofstream& of){
	//prints a tab-separated table of numbers,
	//assumes table[n][n] and labels[n]
	uint size=table.size(),row,col;
	of<<'\t';
	for (col=0;col<size-1;col++) of<<labels[col]<<'\t';
	of<<labels[size-1]<<endl;
	for (row=0;row<size;row++) {
		of<<labels[row]<<'\t';
		for (col=0;col<size-1;col++)
			of<<table[row][col]<<'\t';
		of<<table[row][col]<<endl;
	}
}


void PrintTable(map<string,map<int,int> >&table,char *ofile){
	//prints a tab-separated table of numbers,
	//in the order already sorted
	ofstream of(ofile);
	if (!of) Error("PrintTable: Couldn't open ",ofile);
	map<string,map<int,int> >::iterator rit; //row iterator
	map<int,int>::iterator cit; //col iterator
	of<<"Bits Score\t";
	
	rit=table.begin();
	for (cit=rit->second.begin();cit!=rit->second.end();cit++)
		of<<cit->first<<'\t';
	of<<endl;
	for (rit=table.begin();rit!=table.end();rit++){
		of<<rit->first<<'\t';
		for (cit=rit->second.begin();cit!=rit->second.end();cit++)
			of<<cit->second<<'\t';
		of<<endl;
	}
	of.close();
}


multimap<uint,string> SortMap(map<string,vector<pair<double,double> > >&dat){
	multimap<uint,string> key_order;
	map<string,vector<pair<double,double> > >::iterator dit;
	for (dit=dat.begin();dit!=dat.end();dit++)
		key_order.insert(make_pair(dit->second.size(),dit->first));
	return key_order;
}


multimap<uint,string,greater<uint> > SortMapRev(map<string,vector<pair<double,double> > >&dat){
	multimap<uint,string,greater<uint> > key_order;
	map<string,vector<pair<double,double> > >::iterator dit;
	for (dit=dat.begin();dit!=dat.end();dit++)
		key_order.insert(make_pair(dit->second.size(),dit->first));
	return key_order;
}
