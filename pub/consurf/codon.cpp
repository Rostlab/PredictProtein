#include "codon.h"
#include "nucleotide.h"

codon::codon() {}

int codon::fromChar(const string& s, const int pos) const {
	if (s.size() < pos+2) {
		errorMsg::reportError("trying to read a codon pass the end of the string");
	}

	nucleotide nuc;
	int p1,p2,p3;
	p1 = nuc.fromChar(s[pos]);
	p2 = nuc.fromChar(s[pos+1]);
	p3 = nuc.fromChar(s[pos+2]);

	int res =0;
	if ((p1 <0) || (p2 <0) || (p2 <0)) res = -1; // gap.
	else if ((p1 ==15) || (p2 ==15) || (p2 ==15)) res= 65; // unknown.
	else res = p1 * 16 + p2 *4 + p3;
	switch (res) {
		case 0: return 0; break; //AAA
		case 1: return 1; break; //AAC
		case 2: return 2; break; //AAG
		case 3: return 3; break; //AAT

		case 4: return 4; break; //ACA
		case 5: return 5; break; //ACC
		case 6: return 6; break; //ACG
		case 7: return 7; break; //ACT

		case 8: return 8; break;   //AGA
		case 9: return 9; break;   //AGC
		case 10: return 10; break; //AGG
		case 11: return 11; break; //AGT

		case 12: return 12; break; //ATA
		case 13: return 13; break; //ATC
		case 14: return 14; break; //ATG
		case 15: return 15; break; //ATT

		case 16: return 16; break; //CAA
		case 17: return 17; break; //CAC
		case 18: return 18; break; //CAG
		case 19: return 19; break; //CAT

		case 20: return 20; break; //CCA
		case 21: return 21; break; //CCC
		case 22: return 22; break; //CCG
		case 23: return 23; break; //CCT
	
		case 24: return 24; break; //CGA
		case 25: return 25; break; //CGC
		case 26: return 26; break; //CGG
		case 27: return 27; break; //CGT

		case 28: return 28; break; //CTA
		case 29: return 29; break; //CTC
		case 30: return 30; break; //CTG
		case 31: return 31; break; //CTT

		case 32: return 32; break; //GAA
		case 33: return 33; break; //GAC
		case 34: return 34; break; //GAG
		case 35: return 35; break; //GAT

		case 36: return 36; break; //GCA
		case 37: return 37; break; //GCC
		case 38: return 38; break; //GCG
		case 39: return 39; break; //GCT

		case 40: return 40; break; //GGA
		case 41: return 41; break; //GGC
		case 42: return 42; break; //GGG
		case 43: return 43; break; //GGT
	
		case 44: return 44; break; //GTA
		case 45: return 45; break; //GTC
		case 46: return 46; break; //GTG
		case 47: return 47; break; //GTT

		case 48: return 61; break; //TAA << FIRST STOP CODON
		case 49: return 48; break; //TAC
		case 50: return 62; break; //TAG << SECOND STOP CODON
		case 51: return 49; break; //TAT

		case 52: return 50; break; //TCA
		case 53: return 51; break; //TCC
		case 54: return 52; break; //TCG
		case 55: return 53; break; //TCT

		case 56: return 63; break; //TGA << THIRD STOP CODON
		case 57: return 54; break; //TGC
		case 58: return 55; break; //TGG
		case 59: return 56; break; //TGT

		case 60: return 57; break; //TTA 
		case 61: return 58; break; //TTC
		case 62: return 59; break; //TTG
		case 63: return 60; break; //TTT
	}
	errorMsg::reportError(" never be here, in codon.cpp");
	return -1;
}

string codon::fromInt(const int in_id)  const{
	switch (in_id) {
		case 0: return "AAA"; break; 
		case 1: return "AAC"; break; 
		case 2: return "AAG"; break; 
		case 3: return "AAT"; break; 

		case 4: return "ACA"; break; 
		case 5: return "ACC"; break; 
		case 6: return "ACG"; break; 
		case 7: return "ACT"; break; 

		case 8:  return "AGA"; break;
		case 9:  return "AGC"; break;
		case 10: return "AGG"; break;
		case 11: return "AGT"; break;

		case 12: return "ATA"; break;
		case 13: return "ATC"; break;
		case 14: return "ATG"; break;
		case 15: return "ATT"; break;

		case 16: return "CAA"; break;
		case 17: return "CAC"; break;
		case 18: return "CAG"; break;
		case 19: return "CAT"; break;

		case 20: return "CCA"; break;
		case 21: return "CCC"; break;
		case 22: return "CCG"; break;
		case 23: return "CCT"; break;
	
		case 24: return "CGA"; break;
		case 25: return "CGC"; break;
		case 26: return "CGG"; break;
		case 27: return "CGT"; break;

		case 28: return "CTA"; break; 
		case 29: return "CTC"; break; 
		case 30: return "CTG"; break; 
		case 31: return "CTT"; break; 
						 
		case 32: return "GAA"; break; 
		case 33: return "GAC"; break; 
		case 34: return "GAG"; break; 
		case 35: return "GAT"; break; 
						 
		case 36: return "GCA"; break; 
		case 37: return "GCC"; break; 
		case 38: return "GCG"; break; 
		case 39: return "GCT"; break; 
						 
		case 40: return "GGA"; break; 
		case 41: return "GGC"; break; 
		case 42: return "GGG"; break; 
		case 43: return "GGT"; break; 
						 
		case 44: return "GTA"; break; 
		case 45: return "GTC"; break; 
		case 46: return "GTG"; break; 
		case 47: return "GTT"; break; 

		case 61: return "TAA"; break; // << FIRST STOP CODON
		case 48: return "TAC"; break; //
		case 62: return "TAG"; break; // << SECOND STOP CODON
		case 49: return "TAT"; break; //

		case 50: return "TCA"; break; //
		case 51: return "TCC"; break; //
		case 52: return "TCG"; break; //
		case 53: return "TCT"; break; //
						 
		case 63: return "TGA"; break; // << THIRD STOP CODON
		case 54: return "TGC"; break; //
		case 55: return "TGG"; break; //
		case 56: return "TGT"; break; //
				 
		case 57: return "TTA"; break; // 
		case 58: return "TTC"; break; //
		case 59: return "TTG"; break; //
		case 60: return "TTT"; break; //
		default: return "???";
	}
}

codonUtility::diffType codonUtility::codonDiff(const int c1, const int c2){
	if (c1==c2) return codonUtility::same;
	switch (c1) {
		case 0: {
			switch (c2) {
				case 2: case 8: case 32: return codonUtility::transition;break;
				case 1: case 3: case 4: case 12: case 16: case 61: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 1: {
			switch (c2) {
				case 3: case 9: case 33: return codonUtility::transition;break;
				case 0: case 2: case 5: case 13: case 17: case 48: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 2: {
			switch (c2) {
				case 0: case 10: case 34: return codonUtility::transition;break;
				case 1: case 3: case 6: case 14: case 18: case 62: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 3: {
			switch (c2) {
				case 1: case 11: case 35: return codonUtility::transition;break;
				case 0: case 2: case 7: case 15: case 19: case 49: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 4: {
			switch (c2) {
				case 6: case 12: case 36: return codonUtility::transition;break;
				case 0: case 5: case 7: case 8: case 20: case 50: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 5: {
			switch (c2) {
				case 7: case 13: case 37: return codonUtility::transition;break;
				case 1: case 4: case 6: case 9: case 21: case 51: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 6: {
			switch (c2) {
				case 4: case 14: case 38: return codonUtility::transition;break;
				case 2: case 5: case 7: case 10: case 22: case 52: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 7: {
			switch (c2) {
				case 5: case 15: case 39: return codonUtility::transition;break;
				case 3: case 4: case 6: case 11: case 23: case 53: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 8: {
			switch (c2) {
				case 0: case 10: case 40: return codonUtility::transition;break;
				case 4: case 9: case 11: case 12: case 24: case 63: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 9: {
			switch (c2) {
				case 1: case 11: case 41: return codonUtility::transition;break;
				case 5: case 8: case 10: case 13: case 25: case 54: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 10: {
			switch (c2) {
				case 2: case 8: case 42: return codonUtility::transition;break;
				case 6: case 9: case 11: case 14: case 26: case 55: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 11: {
			switch (c2) {
				case 3: case 9: case 43: return codonUtility::transition;break;
				case 7: case 8: case 10: case 15: case 27: case 56: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 12: {
			switch (c2) {
				case 4: case 14: case 44: return codonUtility::transition;break;
				case 0: case 8: case 13: case 15: case 28: case 57: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 13: {
			switch (c2) {
				case 5: case 15: case 45: return codonUtility::transition;break;
				case 1: case 9: case 12: case 14: case 29: case 58: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 14: {
			switch (c2) {
				case 6: case 12: case 46: return codonUtility::transition;break;
				case 2: case 10: case 13: case 15: case 30: case 59: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 15: {
			switch (c2) {
				case 7: case 13: case 47: return codonUtility::transition;break;
				case 3: case 11: case 12: case 14: case 31: case 60: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 16: {
			switch (c2) {
				case 18: case 24: case 61: return codonUtility::transition;break;
				case 0: case 17: case 19: case 20: case 28: case 32: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 17: {
			switch (c2) {
				case 19: case 25: case 48: return codonUtility::transition;break;
				case 1: case 16: case 18: case 21: case 29: case 33: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 18: {
			switch (c2) {
				case 16: case 26: case 62: return codonUtility::transition;break;
				case 2: case 17: case 19: case 22: case 30: case 34: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 19: {
			switch (c2) {
				case 17: case 27: case 49: return codonUtility::transition;break;
				case 3: case 16: case 18: case 23: case 31: case 35: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 20: {
			switch (c2) {
				case 22: case 28: case 50: return codonUtility::transition;break;
				case 4: case 16: case 21: case 23: case 24: case 36: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 21: {
			switch (c2) {
				case 23: case 29: case 51: return codonUtility::transition;break;
				case 5: case 17: case 20: case 22: case 25: case 37: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 22: {
			switch (c2) {
				case 20: case 30: case 52: return codonUtility::transition;break;
				case 6: case 18: case 21: case 23: case 26: case 38: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 23: {
			switch (c2) {
				case 21: case 31: case 53: return codonUtility::transition;break;
				case 7: case 19: case 20: case 22: case 27: case 39: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 24: {
			switch (c2) {
				case 16: case 26: case 63: return codonUtility::transition;break;
				case 8: case 20: case 25: case 27: case 28: case 40: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 25: {
			switch (c2) {
				case 17: case 27: case 54: return codonUtility::transition;break;
				case 9: case 21: case 24: case 26: case 29: case 41: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 26: {
			switch (c2) {
				case 18: case 24: case 55: return codonUtility::transition;break;
				case 10: case 22: case 25: case 27: case 30: case 42: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 27: {
			switch (c2) {
				case 19: case 25: case 56: return codonUtility::transition;break;
				case 11: case 23: case 24: case 26: case 31: case 43: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 28: {
			switch (c2) {
				case 20: case 30: case 57: return codonUtility::transition;break;
				case 12: case 16: case 24: case 29: case 31: case 44: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 29: {
			switch (c2) {
				case 21: case 31: case 58: return codonUtility::transition;break;
				case 13: case 17: case 25: case 28: case 30: case 45: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 30: {
			switch (c2) {
				case 22: case 28: case 59: return codonUtility::transition;break;
				case 14: case 18: case 26: case 29: case 31: case 46: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 31: {
			switch (c2) {
				case 23: case 29: case 60: return codonUtility::transition;break;
				case 15: case 19: case 27: case 28: case 30: case 47: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 32: {
			switch (c2) {
				case 0: case 34: case 40: return codonUtility::transition;break;
				case 16: case 33: case 35: case 36: case 44: case 61: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 33: {
			switch (c2) {
				case 1: case 35: case 41: return codonUtility::transition;break;
				case 17: case 32: case 34: case 37: case 45: case 48: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 34: {
			switch (c2) {
				case 2: case 32: case 42: return codonUtility::transition;break;
				case 18: case 33: case 35: case 38: case 46: case 62: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 35: {
			switch (c2) {
				case 3: case 33: case 43: return codonUtility::transition;break;
				case 19: case 32: case 34: case 39: case 47: case 49: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 36: {
			switch (c2) {
				case 4: case 38: case 44: return codonUtility::transition;break;
				case 20: case 32: case 37: case 39: case 40: case 50: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 37: {
			switch (c2) {
				case 5: case 39: case 45: return codonUtility::transition;break;
				case 21: case 33: case 36: case 38: case 41: case 51: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 38: {
			switch (c2) {
				case 6: case 36: case 46: return codonUtility::transition;break;
				case 22: case 34: case 37: case 39: case 42: case 52: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 39: {
			switch (c2) {
				case 7: case 37: case 47: return codonUtility::transition;break;
				case 23: case 35: case 36: case 38: case 43: case 53: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 40: {
			switch (c2) {
				case 8: case 32: case 42: return codonUtility::transition;break;
				case 24: case 36: case 41: case 43: case 44: case 63: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 41: {
			switch (c2) {
				case 9: case 33: case 43: return codonUtility::transition;break;
				case 25: case 37: case 40: case 42: case 45: case 54: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 42: {
			switch (c2) {
				case 10: case 34: case 40: return codonUtility::transition;break;
				case 26: case 38: case 41: case 43: case 46: case 55: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 43: {
			switch (c2) {
				case 11: case 35: case 41: return codonUtility::transition;break;
				case 27: case 39: case 40: case 42: case 47: case 56: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 44: {
			switch (c2) {
				case 12: case 36: case 46: return codonUtility::transition;break;
				case 28: case 32: case 40: case 45: case 47: case 57: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 45: {
			switch (c2) {
				case 13: case 37: case 47: return codonUtility::transition;break;
				case 29: case 33: case 41: case 44: case 46: case 58: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 46: {
			switch (c2) {
				case 14: case 38: case 44: return codonUtility::transition;break;
				case 30: case 34: case 42: case 45: case 47: case 59: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 47: {
			switch (c2) {
				case 15: case 39: case 45: return codonUtility::transition;break;
				case 31: case 35: case 43: case 44: case 46: case 60: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 48: {
			switch (c2) {
				case 17: case 49: case 54: return codonUtility::transition;break;
				case 1: case 33: case 51: case 58: case 61: case 62: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 49: {
			switch (c2) {
				case 19: case 48: case 56: return codonUtility::transition;break;
				case 3: case 35: case 53: case 60: case 61: case 62: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 50: {
			switch (c2) {
				case 20: case 52: case 57: return codonUtility::transition;break;
				case 4: case 36: case 51: case 53: case 61: case 63: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 51: {
			switch (c2) {
				case 21: case 53: case 58: return codonUtility::transition;break;
				case 5: case 37: case 48: case 50: case 52: case 54: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 52: {
			switch (c2) {
				case 22: case 50: case 59: return codonUtility::transition;break;
				case 6: case 38: case 51: case 53: case 55: case 62: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 53: {
			switch (c2) {
				case 23: case 51: case 60: return codonUtility::transition;break;
				case 7: case 39: case 49: case 50: case 52: case 56: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 54: {
			switch (c2) {
				case 25: case 48: case 56: return codonUtility::transition;break;
				case 9: case 41: case 51: case 55: case 58: case 63: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 55: {
			switch (c2) {
				case 26: case 62: case 63: return codonUtility::transition;break;
				case 10: case 42: case 52: case 54: case 56: case 59: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 56: {
			switch (c2) {
				case 27: case 49: case 54: return codonUtility::transition;break;
				case 11: case 43: case 53: case 55: case 60: case 63: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 57: {
			switch (c2) {
				case 28: case 50: case 59: return codonUtility::transition;break;
				case 12: case 44: case 58: case 60: case 61: case 63: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 58: {
			switch (c2) {
				case 29: case 51: case 60: return codonUtility::transition;break;
				case 13: case 45: case 48: case 54: case 57: case 59: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 59: {
			switch (c2) {
				case 30: case 52: case 57: return codonUtility::transition;break;
				case 14: case 46: case 55: case 58: case 60: case 62: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 60: {
			switch (c2) {
				case 31: case 53: case 58: return codonUtility::transition;break;
				case 15: case 47: case 49: case 56: case 57: case 59: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 61: {
			switch (c2) {
				case 16: case 62: case 63: return codonUtility::transition;break;
				case 0: case 32: case 48: case 49: case 50: case 57: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 62: {
			switch (c2) {
				case 18: case 55: case 61: return codonUtility::transition;break;
				case 2: case 34: case 48: case 49: case 52: case 59: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
		case 63: {
			switch (c2) {
				case 24: case 55: case 61: return codonUtility::transition;break;
				case 8: case 40: case 50: case 54: case 56: case 57: return codonUtility::transversion;break;
				default: return codonUtility::different;break;
			}
		}
	}
	errorMsg::reportError("never be here, codon.cpp");
	return codonUtility::different;
}

// =============== the code that generated the above code ======================
/*
#include <fstream>
#include <iostream>
#include <string>
#include <iomanip>
#include <algorithm>
using namespace std;

#include "codon.h"
#include "nucleotide.h"

int rel(const string& codon1, const string& codon2) {
	if (codon1 == codon2) return 0; // SAME
	bool Tr = false;
	bool Tv = false;
	bool difFound = false;
	char lc1 = tolower(codon1[0]);
	char lc2 = tolower(codon2[0]);
	if (lc1 != lc2) {
		difFound = true;
		if ((lc1 == 'a') && (lc2 == 'g')) Tr = true;
		else if ((lc1 == 'c') && (lc2 == 't')) Tr = true;
		else if ((lc1 == 'g') && (lc2 == 'a')) Tr = true;
		else if ((lc1 == 't') && (lc2 == 'c')) Tr = true;
		else Tv = true;
	}

	lc1 = tolower(codon1[1]);
	lc2 = tolower(codon2[1]);
	if (lc1 != lc2) {
		if (difFound == true) {return -1;} // DIFF
		else difFound = true;
		if ((lc1 == 'a') && (lc2 == 'g')) Tr = true;
		else if ((lc1 == 'c') && (lc2 == 't')) Tr = true;
		else if ((lc1 == 'g') && (lc2 == 'a')) Tr = true;
		else if ((lc1 == 't') && (lc2 == 'c')) Tr = true;
		else Tv = true;
	}

	lc1 = tolower(codon1[2]);
	lc2 = tolower(codon2[2]);
	if (lc1 != lc2) {
		if (difFound == true) {return -1;} // DIFF
		else difFound = true;
		if ((lc1 == 'a') && (lc2 == 'g')) Tr = true;
		else if ((lc1 == 'c') && (lc2 == 't')) Tr = true;
		else if ((lc1 == 'g') && (lc2 == 'a')) Tr = true;
		else if ((lc1 == 't') && (lc2 == 'c')) Tr = true;
		else Tv = true;
	}
	if (Tv == true) return 1; //Tv
	else if (Tr == true) return 2; //Tr
	else {errorMsg::reportError("karamba - mistake in the code");}
	return 0;
}

int main() {
	ofstream out("tmp.cpp");
	vector<string> v(64);
	codon c1;
	for (int i=0; i < v.size(); ++i) {
		v[i] = c1.fromInt(i);
	}
	out<<
	"codonUtility::diffType codonDiff(const int c1, const int c2){"<<endl;
	out<<
		"\tif (c1==c2) return codonUtility::same;"<<endl;
	out<<
	"\tswitch (c1) {"<<endl;
	for (int c1=0; c1 < v.size();++c1) {
		out<<
			"\t\tcase "<<c1<<": {"<<endl;
		out<<"\t\t\tswitch (c2) {\n";
		// FINDING TRANSITIONS
		out<<"\t\t\t\t";
		for (int c2=0; c2<v.size(); ++c2) {
            if (rel(v[c1],v[c2])==2) {// transition
				out<<"case "<<c2<<": ";
			}
		}
		out<<"return codonUtility::transition;";
		out<<"break;\n";
		// FINDING TRANSversion
		out<<"\t\t\t\t";
		for (int c2=0; c2<v.size(); ++c2) {
            if (rel(v[c1],v[c2])==1) {// transversion
				out<<"case "<<c2<<": ";
			}
		}
		out<<"return codonUtility::transversion;";
		out<<"break;\n";
		// other
		out<<"\t\t\t\t";
		out<<"default: return codonUtility::different;";
		out<<"break;\n";


		out<<"\t\t\t}\n";
		out<<"\t\t}\n";
	}
	out<<"\t}\n";
	out<<"}\n";
	return 0;
}
*/
//=========================== end of code that generated the above code.

int codonUtility::aaOf (const int c1){
	switch (c1) {
		case 0: case 2: return 11; break;//Lys
		case 1: case 3: return 2; break;//Asn
		case 4: case 5: case 6: case 7: return 16; break;//Thr
		case 8: case 10: case 24: case 25: case 26: case 27: return 1; break;//Arg
		case 9: case 11: case 50: case 51: case 52: case 53: return 15; break;//Ser
		case 12: case 13: case 15:return 9; break;//Ile
		case 14: return 12; break;//Met
		case 16: case 18: return 5; break;//Gln
		case 17: case 19: return 8; break;//His
		case 20: case 21: case 22: case 23: return 14; break;//Pro
		case 28: case 29: case 30: case 31: case 57: case 59: return 10; break;//Leu
		case 32: case 34: return 6; break;//Glu
		case 33: case 35: return 3; break;//Asp
		case 36: case 37: case 38: case 39:return 0 ; break;//Ala
		case 40: case 41: case 42: case 43:return 7; break;//Gly
		case 44: case 45: case 46: case 47:return 19; break;//Val
		case 48: case 49: return 18; break;//Tyr
		case 54: case 56: return 4; break;//Cys
		case 55: return 17; break;//Trp
		case 58: case 60: return 13; break;//Phe
	}
	errorMsg::reportError(" NEVER BE HERE. CODON.CPP ");
	return 0;
}
		 
		



