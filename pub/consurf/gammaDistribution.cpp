#include "gammaDistribution.h"
#include "errorMsg.h"
#include "logFile.h"
#include <cmath>

gammaDistribution::gammaDistribution(const gammaDistribution& other) : 
	alpha(other.alpha), 
	_bonderi(other._bonderi),
	_rates(other._rates),
	_ratesProb(other._ratesProb),
	_globalRate(other._globalRate) {
}

const int ITMAX = 100;
const MDOUBLE EPS = static_cast<MDOUBLE>(0.0000003);
const MDOUBLE FPMIN = static_cast<MDOUBLE>(1.0e-30);
const MDOUBLE ERR_FOR_GAMMA_CALC = static_cast<MDOUBLE>(0.00001);
const MDOUBLE MINIMUM_ALPHA_PARAM = static_cast<MDOUBLE>(0.05);


MDOUBLE gammp(MDOUBLE a, MDOUBLE x);
MDOUBLE gammln(MDOUBLE xx);

MDOUBLE search_for_z_in_dis_with_beta_1(MDOUBLE alpha, MDOUBLE ahoson);
MDOUBLE search_for_z_in_dis_with_any_beta(MDOUBLE alpha,MDOUBLE beta, MDOUBLE ahoson);
MDOUBLE the_avarage_r_in_category_between_a_and_b(MDOUBLE a, MDOUBLE b, MDOUBLE alpha, MDOUBLE beta, int k);


gammaDistribution::gammaDistribution(MDOUBLE alpha,int in_number_of_categories) :distribution(){
	_globalRate=1.0;
	setGammaParameters(in_number_of_categories,alpha);
}


void gammaDistribution::setAlpha(MDOUBLE in_alpha) {
	if (in_alpha == alpha) return;
	setGammaParameters( categories(), in_alpha);
}

void gammaDistribution::change_number_of_categories(int in_number_of_categories) {
	setGammaParameters( in_number_of_categories, alpha);
}

void gammaDistribution::setGammaParameters(int in_number_of_categories, MDOUBLE in_alpha) {
	if (in_alpha < MINIMUM_ALPHA_PARAM)	in_alpha = MINIMUM_ALPHA_PARAM;// when alpha is very small there are underflaw problems
	alpha = in_alpha;
	_rates.clear();
	_rates.resize(in_number_of_categories);
	_ratesProb.erase(_ratesProb.begin(),_ratesProb.end());
	_ratesProb.resize(in_number_of_categories,1.0/in_number_of_categories);
	_bonderi.clear();
	_bonderi.resize(in_number_of_categories+1);
	//cout<<"number of categories is: "<<categories()<<endl;
	//cout<<"alpha is: "<<alpha<<endl;
	if (in_number_of_categories==1) {
		_rates[0] = 1.0;
		return;
	}
	if (categories()>1) {	
		feel_mean();
		return ;
	}
	
}
int gammaDistribution::feel_mean() {
	feel_bonderi();
	int i;
	//for (i=0; i<=categories(); ++i) cout<<endl<<bonderi[i];
	//LOG(5,<<"\n====== the r categories are =====\n");
	for (i=0; i<categories(); ++i) {
		_rates[i]=the_avarage_r_in_category_between_a_and_b(_bonderi[i],_bonderi[i+1],alpha,alpha,categories());
		//LOG(5,<<meanG[i]<<endl);
	}
	//LOG(5,<<endl<<alpha<<endl);
	return 0;
}

int gammaDistribution::feel_bonderi() {
	int i;
	for (i=1; i<categories(); ++i)
	{
		_bonderi[i]=search_for_z_in_dis_with_any_beta(alpha,alpha,(MDOUBLE)i/categories());
	}
	_bonderi[0]=0;
	_bonderi[i]=VERYBIG;
	
	return 0;
}


MDOUBLE the_avarage_r_in_category_between_a_and_b(MDOUBLE left, MDOUBLE right, MDOUBLE alpha, MDOUBLE beta, int k)
{// and and b are the border of percentile k)
  MDOUBLE tmp;
  tmp= gammp(alpha+1,right*beta) - gammp(alpha+1,left*beta);
  tmp= (tmp*alpha/beta)*k;
  return tmp;
}

MDOUBLE search_for_z_in_dis_with_any_beta(MDOUBLE alpha,MDOUBLE beta, MDOUBLE ahoson)
{
	return (search_for_z_in_dis_with_beta_1(alpha,ahoson)/beta);
}

MDOUBLE search_for_z_in_dis_with_beta_1(MDOUBLE alpha, MDOUBLE ahoson)
{
	if ( ahoson>1 || ahoson<0 ) errorMsg::reportError("Error in function search_for_z_in_dis_with_beta_1");
	MDOUBLE left=0;
	MDOUBLE right=99999.0;
	MDOUBLE tmp=5000.0;
	MDOUBLE results=0.0;

	for (int i=0;i<100000000 ; i++)
	{
		results=gammp(alpha,tmp);
		if (results>ahoson)
		{
			right=tmp;
		}
		else left=tmp;
		tmp=(right+left)/2;
		if (fabs(ahoson-results)<ERR_FOR_GAMMA_CALC) return tmp;
	}
	cout << "ERROR in search_for_z_in_dis_with_beta_1() Alpha is: "<< alpha <<endl;
	errorMsg::reportError("Error in function search_for_z_in_dis_with_beta_1 - first bonderi is 0");// also quit the program
	return 0;
}


MDOUBLE gammp(MDOUBLE a, MDOUBLE x);
MDOUBLE gammln(MDOUBLE xx);

void gser(MDOUBLE *gamser, MDOUBLE a, MDOUBLE x, MDOUBLE *gln)
{
	MDOUBLE gammln(MDOUBLE xx);
	
	int n;
	MDOUBLE sum,del,ap;

	*gln=gammln(a);
	if (x <= 0.0) {
		if (x < 0.0) LOG(1,<<"x less than 0 in routine gser");
		*gamser=0.0;
		return;
	} else {
		ap=a;
		del=sum=1.0/a;
		for (n=1;n<=ITMAX;n++) {
			++ap;
			del *= x/ap;
			sum += del;
			if (fabs(del) < fabs(sum)*EPS) {
				*gamser=sum*exp(-x+a*log(x)-(*gln));
				return;
			}
		}
		LOG(1,<<"a too large, ITMAX too small in routine gser");
		return;
	}
}

void gcf(MDOUBLE *gammcf, MDOUBLE a, MDOUBLE x, MDOUBLE *gln)
{
	MDOUBLE gammln(MDOUBLE xx);
	int i;
	MDOUBLE an,b,c,d,del,h;

	*gln=gammln(a);
	b=x+1.0-a;
	c=1.0/FPMIN;
	d=1.0/b;
	h=d;
	for (i=1;i<=ITMAX;i++) {
		an = -i*(i-a);
		b += 2.0;
		d=an*d+b;
		if (fabs(d) < FPMIN) d=FPMIN;
		c=b+an/c;
		if (fabs(c) < FPMIN) c=FPMIN;
		d=1.0/d;
		del=d*c;
		h *= del;
		if (fabs(del-1.0) < EPS) break;
	}
	if (i > ITMAX) LOG(1,<<"a too large, ITMAX too small in gcf");
	*gammcf=exp(-x+a*log(x)-(*gln))*h;
}

#undef ITMAX
#undef EPS
#undef FPMIN


MDOUBLE gammln(MDOUBLE xx)
{
	MDOUBLE x,y,tmp,ser;
	static MDOUBLE cof[6]={
		static_cast<MDOUBLE>(76.18009172947146),
		static_cast<MDOUBLE>(-86.50532032941677),
		static_cast<MDOUBLE>(24.01409824083091),
		static_cast<MDOUBLE>(-1.231739572450155),
		static_cast<MDOUBLE>(0.1208650973866179e-2),
		static_cast<MDOUBLE>(-0.5395239384953e-5)
	};
	int j;

	y=x=xx;
	tmp=x+5.5;
	tmp -= (x+0.5)*log(tmp);
	ser=1.000000000190015f;
	for (j=0;j<=5;j++) ser += cof[j]/++y;
	return -tmp+log(2.5066282746310005*ser/x);
}


MDOUBLE gammp(MDOUBLE a, MDOUBLE x)
{
	void gcf(MDOUBLE *gammcf, MDOUBLE a, MDOUBLE x, MDOUBLE *gln);
	void gser(MDOUBLE *gamser, MDOUBLE a, MDOUBLE x, MDOUBLE *gln);
	MDOUBLE gamser,gammcf,gln;

	if (x < 0.0 || a <= 0.0) LOG(1,<<"Invalid arguments in routine gammp");
	if (x < (a+1.0)) {
		gser(&gamser,a,x,&gln);
		return gamser;
	} else {
		gcf(&gammcf,a,x,&gln);
		return 1.0-gammcf;
	}
}

const MDOUBLE gammaDistribution::getCumulativeProb(const MDOUBLE x) const
{
	//since r~gamma(alpha, beta) then beta*r~ gamma(alpha,1)=gammp
	//here we assume alpha=beta
	return gammp(alpha, x*alpha);
}






