// version 1.00
// last modified 2 Nov 2002

#ifndef ___NUM_REC
#define ___NUM_REC

#include "errorMsg.h"
#include "definitions.h"
#include <cmath>
#include <iostream>
using namespace std;

#define SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))

//========================== function brent =========================================
template <typename regF>
MDOUBLE brent(MDOUBLE ax, MDOUBLE bx, MDOUBLE cx, regF f, MDOUBLE tol,
	MDOUBLE *xmin) {

	const int ITMAX  = 100;
	const MDOUBLE CGOLD = 0.3819660f;
	const MDOUBLE ZEPS = 1.0e-10f;

	int iter;
	MDOUBLE a,b,d=0.0,etemp,fu,fv,fw,fx,p,q,r,tol1,tol2,u,v,w,x,xm;
	MDOUBLE e=0.0;

	a=(ax < cx ? ax : cx);
	b=(ax > cx ? ax : cx);
	x=w=v=bx;
	fw=fv=fx=f(x);
	for (iter=1;iter<=ITMAX;iter++) {
		xm=0.5*(a+b);
		tol2=2.0*(tol1=tol*fabs(x)+ZEPS);
		if (fabs(x-xm) <= (tol2-0.5*(b-a))) {
			*xmin=x;
			return fx;
		}
		if (fabs(e) > tol1) {
			r=(x-w)*(fx-fv);
			q=(x-v)*(fx-fw);
			p=(x-v)*q-(x-w)*r;
			q=2.0*(q-r);
			if (q > 0.0) p = -p;
			q=fabs(q);
			etemp=e;
			e=d;
			if (fabs(p) >= fabs(0.5*q*etemp) || p <= q*(a-x) || p >= q*(b-x))
				d=CGOLD*(e=(x >= xm ? a-x : b-x));
			else {
				d=p/q;
				u=x+d;
				if (u-a < tol2 || b-u < tol2)
					d=SIGN(tol1,xm-x);
			}
		} else {
			d=CGOLD*(e=(x >= xm ? a-x : b-x));
		}
		u=(fabs(d) >= tol1 ? x+d : x+SIGN(tol1,d));
		fu=f(u);
		if (fu <= fx) {
			if (u >= x) a=x; else b=x;
			v=w;w=x;x=u;
			fv=fw;fw=fx; fx=fu;
		} else {
			if (u < x) a=u; else b=u;
			if (fu <= fw || w == x) {
				v=w;
				w=u;
				fv=fw;
				fw=fu;
			} else if (fu <= fv || v == x || v == w) {
				v=u;
				fv=fu;
			}
		}
	}
	errorMsg::reportError(" too many iterations in function, brent. "); // also quit the program
	return -1;
}

// ===================================== function dbrent ========================================

#define ITMAX 100
#define ZEPS 1.0e-10
#define MOV3(a,b,c, d,e,f) (a)=(d);(b)=(e);(c)=(f);

template <typename regF, typename dF>
MDOUBLE dbrent(MDOUBLE ax, MDOUBLE bx, MDOUBLE cx, regF f,
	dF df, MDOUBLE tol, MDOUBLE *xmin) {

	int iter,ok1,ok2;
	MDOUBLE a,b,d=0.0,d1,d2,du,dv,dw,dx,e=0.0;
	MDOUBLE fu,fv,fw,fx,olde,tol1,tol2,u,u1,u2,v,w,x,xm;

	a=(ax < cx ? ax : cx);
	b=(ax > cx ? ax : cx);
	x=w=v=bx;
	fw=fv=fx=f(x);
	dw=dv=dx=df(x);
	for (iter=1;iter<=ITMAX;iter++) {
		xm=0.5*(a+b);
		tol1=tol*fabs(x)+ZEPS;
		tol2=2.0*tol1;//cerr<<"tol1 = "<<tol1<<" tol 2 = "<<tol2<<endl;
		if (fabs(x-xm) <= (tol2-0.5*(b-a))) {
			*xmin=x;
			return fx;
		}
		if (fabs(e) > tol1) {
			d1=2.0*(b-a);
			d2=d1;
			if (dw != dx) d1=(w-x)*dx/(dx-dw);
			if (dv != dx) d2=(v-x)*dx/(dx-dv);
			u1=x+d1;
			u2=x+d2;
			ok1 = (a-u1)*(u1-b) > 0.0 && dx*d1 <= 0.0;
			ok2 = (a-u2)*(u2-b) > 0.0 && dx*d2 <= 0.0;
			olde=e;
			e=d;
			if (ok1 || ok2) {
				if (ok1 && ok2)
					d=(fabs(d1) < fabs(d2) ? d1 : d2);
				else if (ok1)
					d=d1;
				else
					d=d2;
				if (fabs(d) <= fabs(0.5*olde)) {
					u=x+d;
					if (u-a < tol2 || b-u < tol2)
						d=SIGN(tol1,xm-x);
				} else {
					d=0.5*(e=(dx >= 0.0 ? a-x : b-x));
				}
			} else {
				d=0.5*(e=(dx >= 0.0 ? a-x : b-x));
			}
		} else {
			d=0.5*(e=(dx >= 0.0 ? a-x : b-x));
		}
		if (fabs(d) >= tol1) {
			u=x+d;
			fu=f(u);
		} else {
			u=x+SIGN(tol1,d); //cerr<<"x = "<<x<<endl; cerr<<"tol1 = "<<tol1<<endl;cerr<<" d= "<<d<<endl;cerr<<" u= "<<u<<endl;
			if (u<ax) u=x; // MY LATEST ADDITION!
			fu=f(u);
			if (fu > fx) {
				*xmin=x;
				return fx;
			}
		}
		du=df(u);
		if (fu <= fx) {
			if (u >= x) a=x; else b=x;
			MOV3(v,fv,dv, w,fw,dw)
			MOV3(w,fw,dw, x,fx,dx)
			MOV3(x,fx,dx, u,fu,du)
		} else {
			if (u < x) a=u; else b=u;
			if (fu <= fw || w == x) {
				MOV3(v,fv,dv, w,fw,dw)
				MOV3(w,fw,dw, u,fu,du)
			} else if (fu < fv || v == x || v == w) {
				MOV3(v,fv,dv, u,fu,du)
			}
		}
	}
	errorMsg::reportError("Too many iterations in routine dbrent"); // also quit the program
	return 0.0;
}

//================================== function rtbis =========================================
template <typename regF>
MDOUBLE rtbis(regF func,MDOUBLE x1, MDOUBLE x2, MDOUBLE xacc) {
	const int max_number_of_iter = 40;
	
	MDOUBLE f = func(x1);
	MDOUBLE fmid = func(x2);
	if (f*fmid >=0.0) {
		errorMsg::reportError(" error in function rtbis, root must be bracketed for bisection in rtbis ");
		// also quit the program
	}

	MDOUBLE dx, rtb;
	if (f<0.0) {
		dx = x2-x1;
		rtb = x1;
	}
	else {
		dx = x1-x2;
		rtb = x2;
	}


	for (int j=1; j <= max_number_of_iter; ++j) {
		dx *= 0.5;
		MDOUBLE xmid = rtb+dx; 
		MDOUBLE fmid = func(xmid);
		if (fmid <= 0.0) rtb = xmid;
		if ((fabs(dx) < xacc) || (fmid == 0.0)) return rtb;
	}
	errorMsg::reportError("Error in function rtbis..."); // also quit the program...
	return -1.0;
}

// ================================ function brent new ======================================

int MyJacobi(VVdouble &Insym, VVdouble &RightEigenV, Vdouble &EigenValues);

#endif

