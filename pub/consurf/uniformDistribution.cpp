#include "uniformDistribution.h"


uniformDistribution::uniformDistribution(const int numOfCategories, MDOUBLE lowerBound, MDOUBLE upperBound) :distribution()
{
	m_globalRate=1.0;
	setUniformParameters(numOfCategories, lowerBound, upperBound);
}


uniformDistribution::uniformDistribution(const uniformDistribution& other) : 
	m_rates(other.m_rates),
	m_ratesProb(other.m_ratesProb),
	m_globalRate(other.m_globalRate),
	m_epsilon(other.m_epsilon),
	m_upperBound(other.m_upperBound),
	m_lowerBound(other.m_lowerBound)
{
}



void uniformDistribution::setUniformParameters(const int number_of_categories, MDOUBLE lowerBound, MDOUBLE upperBound)
{
	m_upperBound = upperBound;
	m_lowerBound = lowerBound;
	
	m_epsilon = ((upperBound - lowerBound) / (number_of_categories+0.0));
	m_rates.clear();
	m_rates.resize(number_of_categories);
	m_ratesProb.erase(m_ratesProb.begin(),m_ratesProb.end());
	m_ratesProb.resize(number_of_categories, 1.0/number_of_categories);
	
	for (int i = 0; i < number_of_categories; ++i) 
	{
		m_rates[i] = m_lowerBound + (m_epsilon * (i + 0.5));
	}
}

//returns the ith border between categories
//getBorder(0) = m_lowerBound, getBorder(categories()) = m_upperBound
MDOUBLE uniformDistribution::getBorder(int i) const {
	return (i == categories()) ?  m_upperBound : (m_rates[i] - (m_epsilon/2));
}

const MDOUBLE uniformDistribution::getCumulativeProb(const MDOUBLE x) const
{
	if (x<m_lowerBound)
		return 0;
	else if (x>= m_upperBound)
		return 1;
	else
		return ((x-m_lowerBound) / (m_upperBound - m_lowerBound));
}


