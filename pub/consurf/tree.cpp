//#ifndef unix
//#pragma warning (disable:4786)
//#endif
#include <cassert>
#include <algorithm>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <ctime>
#include "tree.h"
#include "treeUtil.h"
#include "logFile.h"
#include "someUtil.h"

using namespace std;

//*******************************************************************************
// constructors
//*******************************************************************************
using namespace libtree_v1_0_0;
tree::tree() {
	_root=NULL;
}

//*******************************************************************************
// questions on the tree topology
//*******************************************************************************




void tree::getNeigboursOfNode(vector<nodeP> &vNeighbourVector, const nodeP inNodeP) const {
	vNeighbourVector.clear();
	vNeighbourVector = inNodeP->sons;
	if (iRoot() != inNodeP)	vNeighbourVector.push_back(inNodeP->father());
}

MDOUBLE tree::lengthBetweenNodes(const nodeP i, const nodeP j) const {
// between neighbours nodes
	if (i->father() == j) return i->dis2father();
	assert (j->father() ==i);
	return j->dis2father();
}  


tree::nodeP tree::getSonOfRootIfRootIsAleaf() const {
	assert (_root->sons.size() == 1);
	return _root->sons[0];
}


tree::nodeP tree::fromName(const string inName) const{ // get nodePTR from name
	vector<nodeP> v;
	getAllNodes(v,iRoot());
	for (int l=0 ; l < v.size(); l++ ) {
		if (v[l]->name() == inName) return v[l];
	}

	errorMsg::reportError("Error in function tree::fromName - name not found");// also quit the program
	return NULL;
}



void tree::getPathBetweenAnyTwoNodes(vector<nodeP> &path,const nodeP node1, const nodeP node2) const {

	path.clear();
	vector<nodeP> pathMatrix1;
	vector<nodeP> pathMatrix2;

	nodeP nodeup = node1;
	while (nodeup != _root)	{
		pathMatrix1.push_back(nodeup);
		nodeup = nodeup->father();
	}
	pathMatrix1.push_back(_root);

	nodeup = node2;
	while (nodeup != _root)	{
		pathMatrix2.push_back(nodeup);
		nodeup = nodeup->father();
	}
	pathMatrix2.push_back(_root);

	int tmp1 = pathMatrix1.size()-1;
	int tmp2 = pathMatrix2.size()-1;

	while ((tmp1>=0) && (tmp2>=0)) {
		if (pathMatrix1[tmp1] != pathMatrix2[tmp2]) break;
		tmp1--; tmp2--;
	}

	for (int y=0; y <= tmp1; ++y) path.push_back(pathMatrix1[y]);
	path.push_back(pathMatrix1[tmp1+1]); // pushing once, the TreeNode that was common to both.
	for (int j=tmp2; j >= 0; --j) {
		path.push_back(pathMatrix2[j]);
	}
	return;
}


MDOUBLE tree::findLengthBetweenAnyTwoNodes(const nodeP node1, const nodeP node2) const {
	vector<nodeP> pathMatrix;
	MDOUBLE sumOfDistances =0;
	getPathBetweenAnyTwoNodes(pathMatrix, node1, node2);
	for (int i=0; i < pathMatrix.size() ; i++) {
		if (pathMatrix[i]->father() != NULL) sumOfDistances += pathMatrix[i]->dis2father();
	}
	return sumOfDistances;
}

//*******************************************************************************
// change tree topoplogy parameters - should be applied carefully
//*******************************************************************************

void tree::rootAt(const nodeP p_iNewRoot) {
	if (_root == p_iNewRoot) return;
	vector<nodeP> pathMatrix;
	getPathBetweenAnyTwoNodes(pathMatrix,_root,p_iNewRoot);
	//pathMatrix size is always bigger than 2.

	for (int i=0; i < pathMatrix.size()-1 ; i++) {
		pathMatrix[i]->_father = pathMatrix[i+1];
		pathMatrix[i]->setDisToFather( pathMatrix[i+1]->dis2father() );
		vector<nodeP>::iterator vec_iter;
		vec_iter = remove(pathMatrix[i]->sons.begin(),pathMatrix[i]->sons.end(),pathMatrix[i+1]);
		pathMatrix[i]->sons.erase(vec_iter,pathMatrix[i]->sons.end()); // pg 1170, primer.
	
		pathMatrix[i+1]->sons.push_back(pathMatrix[i+1]->father());
		pathMatrix[i+1]->_father = NULL;
	}
	_root = p_iNewRoot;

}


void tree::create_names_to_internal_nodes() {
	vector<nodeP> htuVec;
	getAllHTUs(htuVec,_root);

	for (int i=0; i<htuVec.size(); ++i) {
//	  name = int2string(i+1);

	string name = int2string(i+1);

//	  char tmp[4];
//	  sprintf(tmp,"%.4d",i);
//	  htuVec[i]->setName((string)"N"+(string)tmp);
	  htuVec[i]->setName((string)"N"+name);
	}
}


void tree::getFromLeavesToRoot(vector<nodeP> &vNeighbourVector) const {
	getFromRootToLeaves(vNeighbourVector);
	reverse(vNeighbourVector.begin(),vNeighbourVector.end());
}


void tree::getFromRootToLeaves(vector<nodeP> &vec) const {
	getFromNodeToLeaves(vec,_root);
}


void tree::getFromNodeToLeaves(vector<nodeP> &vec, nodeP fromHereDown) const {
	vec.push_back(fromHereDown);
	for (int k=0; k < fromHereDown->sons.size(); k++) {
			getFromNodeToLeaves(vec,fromHereDown->sons[k]);
		}
		return;
}


void tree::getAllHTUs(vector<nodeP> &vec,nodeP fromHereDown ) const {
	vec.clear();
	getAllHTUsPrivate(vec,fromHereDown);
}


void tree::getAllHTUsPrivate(vector<nodeP> &vec,nodeP fromHereDown ) const {
	if (fromHereDown == NULL) return;
	if (isInternal(fromHereDown)) vec.push_back(fromHereDown);
	for (int k=0; k < fromHereDown->sons.size(); k++) {
		getAllHTUsPrivate(vec,fromHereDown->sons[k]);
	}
	return;
}


void tree::getAllNodes(vector<nodeP> &vec,nodeP fromHereDown ) const {
	vec.clear();
	getAllNodesPrivate(vec,fromHereDown);
}

void tree::getAllNodesBFS(vector<nodeP> &vec,nodeP fromHereDown ) const {
	vec.clear();
	getAllNodesPrivate(vec,fromHereDown);
}


void tree::getAllNodesPrivate(vector<nodeP> &vec,nodeP fromHereDown ) const {
	// BFS?
	if (fromHereDown == NULL) return;
	vec.push_back(fromHereDown);
	for (int k=0; k < fromHereDown->sons.size(); k++) {
		getAllNodesPrivate(vec,fromHereDown->sons[k]);
	}
	return;
}


void tree::getAllLeaves(vector<nodeP> &vec,nodeP fromHereDown ) const {
	vec.clear();
	getAllLeavesPrivate(vec,fromHereDown);
}


void tree::getAllLeavesPrivate(vector<nodeP> &vec,nodeP fromHereDown ) const {
	if (fromHereDown == NULL) return;
	if (isLeaf(fromHereDown)) vec.push_back(fromHereDown);
	for (int k=0; k < fromHereDown->sons.size(); k++) {
		getAllLeavesPrivate(vec,fromHereDown->sons[k]);
	}
	return;
}

/*
void tree::setLengthBetweenNodes(const nodeP i, const nodeP j, const MDOUBLE p_Length) {
	if (i->father() == j) i->setDisToFather ( p_Length);
	assert (j->father() == i);
	j->setDisToFather(p_Length);
}
*/

void  tree::multipleAllBranchesByFactor(MDOUBLE InFactor) {
	vector<nodeP> vec;
	getAllNodes(vec,_root );
	for (int i=0; i< vec.size(); ++i) {
		if (vec[i]->father() != NULL) vec[i]->setDisToFather(vec[i]->dis2father() * InFactor);
	}
	_root->setDisToFather(TREE_NULL);
}


void tree::createFlatLengthMatrix(const MDOUBLE newFlatDistance) {
	vector<nodeP> vec;
	getAllNodes(vec,_root );
	for (int i=0; i< vec.size(); ++i) {
		if (vec[i]->father() != NULL) vec[i]->setDisToFather(newFlatDistance);
	}
}

/*
void tree::set_length_to_father(nodeP iSon, MDOUBLE dLength) {
	iSon->setDisToFather(dLength);
}
*/

// helper function
class eqNameVLOCAL {
	public:
		explicit eqNameVLOCAL(const string& x) : _x(x) {}
		const string& _x;
		bool operator() (const tree::nodeP y){
			return _x==y->name();
		}
};

void tree::removeNodeFromSonListOfItsFather(nodeP sonNode) {
	// acording to the name of the sonNode
	// this function should ONLY be used when the node, sonNode, is to be recycled soon!
	// because this function does not change the number of leaves nor the number of nodes!
	// nor does it change the father of sonNode.
  vector<tree::nodeP>::iterator vec_iter;
  vec_iter = remove_if(sonNode->_father->sons.begin(),sonNode->_father->sons.end(),eqNameVLOCAL(sonNode->name()));
  sonNode->father()->sons.erase(vec_iter,sonNode->father()->sons.end()); // pg 1170, primer.
}

/*
void tree::remove_link_node(nodeP inNode) {
  nodeP fatherNode=inNode->father();
  if(fatherNode != NULL) {		// root
    bool found=false;
    int i;
    for (i=0;i<fatherNode->sons.size()&&!found;++i) {
      if (fatherNode->sons[i]==inNode) {
	found=true; 
	break;
      }
    }
    if (found) {
      if(inNode->sons.size()!=1) {
	cerr << "removing a link node\nWith more then one son and one father\nmakes program exit now\n";
	exit (-9);
      }
      fatherNode->sons[i]=inNode->sons[0];
      inNode->sons[0]->_father=fatherNode;
      inNode->sons[0]->setDisToFather(inNode->dis2father()+inNode->sons[0]->dis2father());
    } else {
      cerr << "the father of linknode\nDose not recognize his own son\n sadness fills the hart\n";
      exit (-10);
    }
  } else {			// root
    cerr << "The root of the tree\nlight With the borden of twins\nthis link must stay\n";
    exit(-10);
  }
}

*/
//*******************************************************************************
// Input-Output
//*******************************************************************************


void tree::output(string treeOutFile, TREEformats fmt, bool withHTU ) const{
	ofstream os(treeOutFile.c_str());
	output(os, fmt, withHTU);
	os.close();
}




void tree::output(ostream& os, TREEformats fmt, bool withHTU) const {
	if (_root == NULL) {LOG(1,<<" empty tree "); return; }
	if (fmt == PHYLIP) outputInPhylipTreeFormat(os, withHTU);
	else if (fmt == ANCESTOR) outputInAncestorTreeFormat(os,withHTU);
	else if (fmt == ANCESTORID) outputInAncestorIdTreeFormat(os,withHTU);
	os<<endl;		// Matan
}

const MDOUBLE tree::FLAT_LENGTH_VALUE = 0.3f;


const int tree::TREE_NULL = -1;
	


void tree::outputInAncestorTreeFormat(
			ostream& treeOutStream, bool distances) const{
	time_t ltime;
	int i,k,spaces;
	vector<nodeP> vec;
	int maxNameLen = 0;

	getAllLeaves(vec,_root);
	for (int w=0; w<vec.size();++w) {
		if (maxNameLen<vec[w]->name().size()) maxNameLen = vec[w]->name().size();
	}
	maxNameLen++; // this is just the longest name of taxa plus one



	time( &ltime );
	treeOutStream<<"# created on "<< ctime( &ltime ) ;

	treeOutStream<<"name";
	spaces = maxNameLen-4;
	for (k=0;k<spaces;++k) treeOutStream<<" ";

	treeOutStream<<"father";
	spaces = 7-6;
	for (k=0;k<spaces;++k) treeOutStream<<" ";

	if (distances) {
		treeOutStream<<"disance to father";
		treeOutStream<<"    ";
	}
	
	treeOutStream<<" sons";
	spaces = maxNameLen-4;
	for (k=0;k<spaces;++k) treeOutStream<<" ";

	treeOutStream<<endl;
	

	for (i=0; i<vec.size();++i) {
		treeOutStream<<vec[i]->name();
		spaces = maxNameLen-vec[i]->name().size();
		for (k=0;k<spaces;++k) treeOutStream<<" ";

		if (vec[i] != _root) {
			treeOutStream<<vec[i]->father()->name();
			spaces = 7-vec[i]->father()->name().size();
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}
		else {
			treeOutStream<<"root!";
			spaces = 7-5;
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}

		if ((vec[i] != _root) && distances) {
			treeOutStream<<vec[i]->dis2father();
		}
		//else treeOutStream<<"    ";

		for (int j=0; j < vec[i]->sons.size(); j++) {
			treeOutStream<<" "<<vec[i]->sons[j]->name();
		}
		treeOutStream<<endl;
	}

	vec.clear();
	getAllHTUs(vec,_root );

	for (i=0; i<vec.size();++i) {
		treeOutStream<<vec[i]->name();
		spaces = maxNameLen-vec[i]->name().size();
		for (k=0;k<spaces;++k) treeOutStream<<" ";

		if (vec[i] != _root) {
			treeOutStream<<vec[i]->father()->name();
			spaces = 7-vec[i]->father()->name().size();
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}
		else {
			treeOutStream<<"root!";
			spaces = maxNameLen-5;
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}
		
		if (vec[i] != _root && distances) treeOutStream<<vec[i]->dis2father();
		
		for (int j=0; j < vec[i]->sons.size(); j++) {
			treeOutStream<<" "<<vec[i]->sons[j]->name();
		}
		treeOutStream<<endl;
	}
}


void tree::outputInPhylipTreeFormat(ostream& os, bool withHTU ) const {
  //  os.setf(ios::fixed,ios::floatfield); // matan
	// special case of a tree with 1 or 2 taxa.
	if (iLeaves() == 1) {
		os<<"("<<_root->name()<<")"<<endl;
		return;
	}
	else if (iLeaves() == 2) {
		os<<"("<<_root->name()<<":0.0,";

		os<<_root->sons[0]->name()<<":" <<setiosflags(ios::fixed) <<_root->sons[0]->dis2father()<<")"<<endl;
		return;
	}
	// ========================================
	os<<"(";
	// going over all the son
	int i;
	for (i=0; i<_root->sons.size()-1; ++i)
	{
		print_from(_root->sons[i],os, withHTU);
		os<<",";
	}
	
	print_from(_root->sons[i],os, withHTU);
	os<<")";
	char c=59;// 59 is dot-line
	os<<c;
}


int tree::print_from(nodeP from_node, ostream& os, bool withHTU ) const {
	int i;
	if (isLeaf(from_node)) os<<from_node->name();
	else {
		os<<"(";
		for (i=0; i<from_node->sons.size()-1; ++i) {
			print_from(from_node->sons[i],os,withHTU);
			os<<",";
		}
		print_from(from_node->sons[i],os,withHTU);
		os<<")";
		if (withHTU==true) os<<from_node->name();
	}
	os<<":"<<setiosflags(ios::fixed) <<from_node->dis2father();
	return 0;
}

tree::tree(const string& p_sIntreeFileName, vector<char>& isFixed) {
	ifstream in(p_sIntreeFileName.c_str());
	if (in == NULL) {
		errorMsg::reportError("Error - unable to locate tree file.",1); // also quit the program
	}
	if (readPhylipTreeTopology(in,isFixed)) {
		create_names_to_internal_nodes();
		return;
	}
	in.close();
	errorMsg::reportError("Unable to read phylip tree file",1);// also quit the program
}
	
tree::tree(const string& p_sIntreeFileName) {
	ifstream in(p_sIntreeFileName.c_str());
	if (in == NULL) {
		errorMsg::reportError("Error - unable to locate tree file.",1); // also quit the program
	}
	if (readPhylipTreeTopology(in)) {
		create_names_to_internal_nodes();
		return;
	}
	in.close();
	errorMsg::reportError("Unable to read phylip tree file",1);// also quit the program
}

tree::tree(istream &in) {
	if (readPhylipTreeTopology(in)) {
		create_names_to_internal_nodes();
		return;
	}
	errorMsg::reportError("Unable to read phylip tree file",1);// also quit the program
}

tree::tree(istream &in,vector<char>& isFixed) {
	if (readPhylipTreeTopology(in,isFixed)) {
		create_names_to_internal_nodes();
		return;
	}
	errorMsg::reportError("Unable to read phylip tree file",1);// also quit the program
}

bool tree::readPhylipTreeTopology(istream &in) {
	const vector<char> tree_contents = PutTreeFileIntoVector(in);
	return readPhylipTreeTopology(tree_contents);
}

bool tree::readPhylipTreeTopology(istream &in,vector<char>& isFixed) {
	const vector<char> tree_contents = PutTreeFileIntoVector(in);
	return readPhylipTreeTopology(tree_contents,isFixed);
}

tree::tree(const vector<char>& tree_contents) {
	readPhylipTreeTopology(tree_contents);
	create_names_to_internal_nodes();
//	fillNodesID();
	return;
}

tree::tree(const vector<char>& tree_contents,vector<char>& isFixed) {
	readPhylipTreeTopology(tree_contents,isFixed);
	create_names_to_internal_nodes();
//	fillNodesID();
	return;
}

bool tree::readPhylipTreeTopology(const vector<char>& tree_contents) {
	vector<char> isFixed;
	return readPhylipTreeTopology(tree_contents,isFixed);
}

bool tree::readPhylipTreeTopology(const vector<char>& tree_contents,vector<char>& isFixed) {


	int nextFreeID =0; // to give id's for nodes.
	_leaves = GetNumberOfLeaves(tree_contents);
	_root = new TreeNode(nextFreeID);
	++nextFreeID;
	_nodes = GetNumberOfInternalNodes(tree_contents) + _leaves;

	isFixed.resize(_nodes,0); // 0 = not fixed, 1 = fixed.
	nodeP conection2part=NULL;
	vector<char>::const_iterator itCurrent = tree_contents.begin();

	if (verifyChar(itCurrent,OPENING_BRACE)||verifyChar(itCurrent,OPENING_BRACE2)){
		do {
				itCurrent++;
				conection2part = readPart(itCurrent,nextFreeID,isFixed);
				// readPart returns a pointer for him self
				_root->sons.push_back(conection2part);
				conection2part->_father = _root;

		}  while (verifyChar(itCurrent, COMMA));
	}	
	if (!(verifyChar(itCurrent, CLOSING_BRACE)||verifyChar(itCurrent, CLOSING_BRACE2))) {
		errorMsg::reportError("Error reading tree file.",1); // also quit
	}

	// this part is for the cases where all the edges are fixed. In such case - this part changes
	// all the branches to not fixed.
	int z=0;
	bool allFixed = true;
	for (z=1; z< isFixed.size(); ++z) {
		if (isFixed[z] == 0) {
			allFixed = false;
			break;
		}
	}
	if (allFixed) {
		for (z=1; z< isFixed.size(); ++z) {
			isFixed[z] = 0;
		}
	}


	return true;
}


tree::nodeP tree::readPart(	vector<char>::const_iterator& p_itCurrent,
						   int& nextFreeID,
						   vector<char> & isFixed) {
	if ( IsAtomicPart(p_itCurrent) )	{
		// read the name, i.e. - the content from the file
		nodeP newLeaf = new TreeNode(nextFreeID);
		isFixed[nextFreeID] = 1; // all edges to the leaves are fixed...
		++nextFreeID;

		// puting the name
		string tmpname;
		tmpname.erase();

		while (
			((*p_itCurrent)!=')') && 
			((*p_itCurrent)!='(') && 
			((*p_itCurrent)!=':') &&
			((*p_itCurrent)!=',') &&
			((*p_itCurrent)!='}') &&
			((*p_itCurrent)!='{')) {
			tmpname +=(*p_itCurrent);
			++p_itCurrent;
		} // NEW
	
		
		
		
		newLeaf->setName(tmpname);	

		// if a number(==distance) exists on the right-hand, update the distance table
		if ( DistanceExists(p_itCurrent) ) 
			newLeaf->setDisToFather(getDistance(p_itCurrent));
		return newLeaf;
		
	}
	else // this is a complex part
	{
		nodeP newHTU = new TreeNode(nextFreeID);
		++nextFreeID;
		nodeP conection2part=NULL;

		do {
			++p_itCurrent;
			conection2part = readPart(p_itCurrent,nextFreeID,isFixed);
			conection2part->_father = newHTU;
			newHTU->sons.push_back(conection2part);
		} while (verifyChar(p_itCurrent, COMMA));
		if (verifyChar(p_itCurrent, CLOSING_BRACE)) {
			isFixed[newHTU->id()] = 1;
		} else if (verifyChar(p_itCurrent, CLOSING_BRACE2)) {
			isFixed[newHTU->id()] = 0;
		} else {
			errorMsg::reportError("Error reading tree file (2)");
		}
		++p_itCurrent;
		
		// if a number(==distance) exists on the right-hand, update the distance table
		if ( DistanceExists(p_itCurrent) )
			newHTU->setDisToFather(getDistance(p_itCurrent));
		return newHTU;
 
	}
}



tree::tree(const tree &otherTree) {
	_root = NULL;
	if (otherTree._root == NULL) return; // if tree to copy is empty.
	createRootNode();
	_root->setName(otherTree._root->name());
	for (int i=0; i <otherTree._root->sons.size(); ++i) {
		recursiveBuildTree( _root, otherTree.iRoot()->sons[i]);
	}
}


tree& tree::operator=(const tree &otherTree) {
	if (otherTree._root == NULL) return *this; // if tree to copy is empty.
	createRootNode();
	_root->setName(otherTree._root->name());
	for (int i=0; i <otherTree._root->sons.size(); ++i) {
		recursiveBuildTree( _root, otherTree.iRoot()->sons[i]);
	}
	return *this;
}


tree::nodeP tree::recursiveBuildTree( tree::nodeP father_nodePTR,const tree::nodeP other_nodePTR) {
// copy the information from other_nodePTR to a new node, and set the father to father_nodePTR

//	if (other_nodePTR == NULL) return NULL; // if tree to copy is empty.
//	tree::nodeP thisObjectPTR = new tree::TreeNode(other_nodePTR->id());
	tree::nodeP thisObjectPTR = createNode(father_nodePTR,other_nodePTR->id());
	thisObjectPTR->setName(other_nodePTR->name());
	thisObjectPTR->setDisToFather(other_nodePTR->dis2father());
//	thisObjectPTR->_father = father_nodePTR;
//	if (father_nodePTR) {
//		father_nodePTR->sons.push_back(thisObjectPTR);
	
	for (int k=0 ; k < other_nodePTR->sons.size() ; ++k) {
			recursiveBuildTree(thisObjectPTR,other_nodePTR->sons[k]);
	}
	return thisObjectPTR;
}

void tree::clear() {

	vector<nodeP> vec;
	getAllNodes(vec,_root);

	for (int k=0; k < vec.size(); k++) {
		delete(vec[k]);
	}

	_nodes = 0;
	_leaves =0;
	_root = NULL;
}




void tree::updateNumberofNodesANDleaves() {
	vector<nodeP> vec;
	getAllLeaves(vec,iRoot());
	_leaves = vec.size();
	vec.clear();
	getAllNodes(vec,iRoot());
	_nodes = vec.size();
}


void tree::removeLeaf(nodeP nodePTR) {
	if (!isLeaf(nodePTR)) {errorMsg::reportError("Error in function removeLeaf - Unable to remove a node, which is not a leaf ");
	}
	
	if (iNodes() ==1) {
		delete iRoot();
		_root = NULL;
	}
	if (nodePTR->isRoot()) {
		nodeP sonOfRoot = getSonOfRootIfRootIsAleaf();
		rootAt(sonOfRoot);
	}


	// leaf is not the root:

		vector<nodeP>::iterator vec_iter;
		nodeP fatheOfLeafToRemove = nodePTR->father();
		vec_iter = remove(fatheOfLeafToRemove->sons.begin(),fatheOfLeafToRemove->sons.end(),nodePTR);
		fatheOfLeafToRemove->sons.erase(vec_iter,fatheOfLeafToRemove->sons.end()); // pg 1170, primer.

		delete nodePTR;

		int tmpSons = fatheOfLeafToRemove->sons.size();
		if ( tmpSons == 1) shrinkNode(fatheOfLeafToRemove);
		else if ((_root == fatheOfLeafToRemove) && (tmpSons == 2)) {
			nodeP tmp = _root;
			rootAt(_root->sons[0]);
			shrinkNode(tmp);
		}
		updateNumberofNodesANDleaves();
		if (isLeaf(_root) && _root->sons.size() >0 ) rootAt(_root->sons[0]);
		return;
}


void tree::getAllBranch(vector<nodeP> &nodesUp, vector<nodeP> & nodesDown){
	vector<nodeP> localVec;
	getAllNodes(localVec, _root);
	for (int i=0 ; i < localVec.size() ; i++) {
		if (localVec[i]->father() != NULL) {
			nodesUp.push_back(localVec[i]->father());
			nodesDown.push_back(localVec[i]);
		}
	}
	return;
}





void tree::shrinkNode(nodeP nodePTR) {
	// the idea is the if we have tree like that node1---node2---node3
	// we can eliminate node2 (which is nodePTR)

	if (nodePTR->sons.size() != 1) {
		vector<string> err;
		err.push_back("you requested to eliminate a node with more than 1 sons.");
		err.push_back(" error in function shrink node");
		errorMsg::reportError(err); // also quit the program.
	}

	nodeP fatherNode = nodePTR->father();
	nodeP sonNode = nodePTR->sons[0];

	// taking care of the son node:
	sonNode->_father = fatherNode;
	sonNode->setDisToFather(sonNode->dis2father() + nodePTR->dis2father());

	// takind car of father node
	vector<nodeP>::iterator vec_iter;
	vec_iter = remove(fatherNode->sons.begin(),fatherNode->sons.end(),nodePTR);
	fatherNode->sons.erase(vec_iter,fatherNode->sons.end()); // pg 1170, primer.
	fatherNode->sons.push_back(sonNode);

	// delete the nodePTR
	delete nodePTR;
}


void tree::createRootNode() {
	// the idea is to start from an empty tree, and to start a new node
	clear();
	_root = new TreeNode(0);
	_leaves=1;
	_nodes=1;
}


tree::nodeP tree::createNode(nodeP fatherNode, const int id) {
//	nodeP tmp = new TreeNode(_nodes);
	nodeP tmp = new TreeNode(id);
	_nodes++;
	if (fatherNode->sons.size() > 0) {
		++_leaves; // if it is 0, we remove one leaf and add one leaf, so no change.
	}
	tmp->_father=fatherNode;
	fatherNode->sons.push_back(tmp);
//	updateNumberofNodesANDleaves();
	return tmp;
}

bool tree::WithBranchLength() const{
	if (_root->sons.empty()) return false;
	else if (_root->sons[0]->dis2father() != TREE_NULL) return true;
	return false;
}
 
ostream &operator<<(ostream &out, const tree &tr){
	tr.output(out,tree::ANCESTOR);
	return out;
}

/*
void tree::fillNodesID() {
	vector<nodeP> vec;
	getAllNodes(vec,_root );
	for (int i=0; i< vec.size(); ++i) {
		vec[i]->setID( i);
	}
}
*/



/*
void tree::cut_tree_in_two_leaving_interMediate_node(nodeP node2split,tree &small1,tree &small2) const {
	tree tmpCopyOfThisTree = (*this);
	nodeP node2splitOnNewTree = tmpCopyOfThisTree.fromName(node2split->name());
	string interNode = "interNode";
	assert(node2split->father() != NULL);
	nodeP tmp = tmpCopyOfThisTree.makeNodeBetweenTwoNodes(node2splitOnNewTree->father(),node2splitOnNewTree, interNode);
	tmpCopyOfThisTree.rootAt(tmp);
	tmpCopyOfThisTree.cut_tree_in_two_special(tmp, small1,small2);
	nodeP toDel1 = small1.fromName(interNode);
};
*/


void tree::outputInAncestorIdTreeFormat(
			ostream& treeOutStream, bool distances) const{
	time_t ltime;
	int i,k,spaces;
	vector<nodeP> vec;
	int maxNameLen = 0;

	getAllLeaves(vec,_root);
	for (int w=0; w<vec.size();++w) {
		if (maxNameLen<vec[w]->name().size()) maxNameLen = vec[w]->name().size();
	}
	maxNameLen++; // this is just the longest name of taxa plus one
	maxNameLen+=5;		// MN


	time( &ltime );
	treeOutStream<<"# created on "<< ctime( &ltime ) ;

	treeOutStream<<"name";
	spaces = maxNameLen-4;
	for (k=0;k<spaces;++k) treeOutStream<<" ";

	treeOutStream<<"father";
	spaces = 7-6;
	for (k=0;k<spaces;++k) treeOutStream<<" ";

	if (distances) {
		treeOutStream<<"disance to father";
		treeOutStream<<"    ";
	}
	
	treeOutStream<<" sons";
	spaces = maxNameLen-4;
	for (k=0;k<spaces;++k) treeOutStream<<" ";

	treeOutStream<<endl;
	

	for (i=0; i<vec.size();++i) {
	  treeOutStream<<vec[i]->name()<<"("<<vec[i]->id()<<")";
	  int len=3; if (vec[i]->id()>=10) len++;if (vec[i]->id()>=100) len++;
	  spaces = maxNameLen-vec[i]->name().size()-len;
		for (k=0;k<spaces;++k) treeOutStream<<" ";

		if (vec[i] != _root) {
			treeOutStream<<vec[i]->father()->name();
			spaces = 7-vec[i]->father()->name().size();
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}
		else {
			treeOutStream<<"root!";
			spaces = 7-5;
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}

		if ((vec[i] != _root) && distances) {
			treeOutStream<<vec[i]->dis2father();
		}
		//else treeOutStream<<"    ";

		for (int j=0; j < vec[i]->sons.size(); j++) {
			treeOutStream<<" "<<vec[i]->sons[j]->name();
		}
		treeOutStream<<endl;
	}

	vec.clear();
	getAllHTUs(vec,_root );

	for (i=0; i<vec.size();++i) {
		treeOutStream<<vec[i]->name()<<"("<<vec[i]->id()<<")";
		int len=3; if (vec[i]->id()>=10) len++;if (vec[i]->id()>=100) len++;
		spaces = maxNameLen-vec[i]->name().size()-len;
		for (k=0;k<spaces;++k) treeOutStream<<" ";

		if (vec[i] != _root) {
			treeOutStream<<vec[i]->father()->name();
			spaces = 7-vec[i]->father()->name().size();
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}
		else {
			treeOutStream<<"root!";
			spaces = maxNameLen-5;
			for (k=0;k<spaces;++k) treeOutStream<<" ";
		}
		
		if (vec[i] != _root && distances) treeOutStream<<vec[i]->dis2father();
		
		for (int j=0; j < vec[i]->sons.size(); j++) {
			treeOutStream<<" "<<vec[i]->sons[j]->name();
		}
		treeOutStream<<endl;
	}
}

