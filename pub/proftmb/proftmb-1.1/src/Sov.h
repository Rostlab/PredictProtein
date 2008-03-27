//The Sov function.

struct parameters {
	int     input; // ???
	int     order; // ???
	int     q3_what; 
	int     sov_what; //0->SOV(all), 1->SOV(H), 2->SOV(E), 3->SOV(C)
	int     sov_method; //0->(1994 JMB algorithm), 1->(1999 Proteins algorithm
	float   sov_delta;
	float   sov_delta_s;
	int     sov_out;
	char    fname[80];
	parameters::parameters():input(0),order(0),sov_what(0),sov_method(1),
		 sov_delta(1.0),sov_delta_s(0.5),sov_out(0){}
	//these defaults do 
};

float sov(int,char*,char*,parameters*);
