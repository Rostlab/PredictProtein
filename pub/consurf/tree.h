#ifndef ___TREE
#define ___TREE

#include "definitions.h"
#include "readTree.h"
#include "errorMsg.h"



//***********************************************************************************
// tree is the representation of the topology only. It assume no model of evolution 
//***********************************************************************************


namespace libtree_v1_0_0 {

class tree {
public:
	static const MDOUBLE FLAT_LENGTH_VALUE;// = 0.3;
	static const int TREE_NULL;// = -1;


//---------------------------- TREE NODE ----------------------
public:
	class TreeNode {
	public:
//		explicit TreeNode() :_father(NULL),_id(TREE_NULL),_name( (string)"" ),_dis2father(TREE_NULL){}
		explicit TreeNode(const int id) :_father(NULL),_id(id),_name( (string)"" ),_dis2father(TREE_NULL){}
		const int id() const {return _id;}
		const string name() const {return _name;}
		const MDOUBLE dis2father() const {return _dis2father;}
		TreeNode* father() {return _father;}
		void setName(const string &inS) {_name = inS;}
		void setID(const int inID) {_id = inID;}
		void setDisToFather(const MDOUBLE dis) {_dis2father = dis;}
		bool isRoot() {return (_father==NULL);}
		vector<TreeNode*> sons; //TODO - CHANGE TO ITERATOR, AND MOVE TO PRIVATE.
		void setFather(TreeNode* tn){_father=tn;}
	private:
		TreeNode* _father;
		int _id;
		string _name;
		MDOUBLE _dis2father;
		friend class tree;
	};
//------------------------------------------------------------


public:
  typedef enum { PHYLIP, ANCESTOR, ANCESTORID } TREEformats;
	typedef TreeNode* nodeP;

//**********************************************************************************
//					Private members
//**********************************************************************************

protected:
	TreeNode *_root;
	int _leaves;
	int _nodes;
	
public:
//*******************************************************************************
// constructors
//*******************************************************************************
	tree();
	tree(const string& p_sIntreeFileName); 
	tree(const vector<char>& tree_contents);
	tree(istream &in);


	tree(const string& p_sIntreeFileName,vector<char>& isFixed); 
	tree(const vector<char>& tree_contents,vector<char>& isFixed);
	tree(istream &in,vector<char>& isFixed);


	tree(const tree &otherTree);
	tree& operator=(const tree &otherTree);
	void clear();
	virtual ~tree() {clear();};

	
//*******************************************************************************
// questions on the tree topology
//*******************************************************************************

	nodeP iRoot() const {return _root;};
	inline int iLeaves() const;
	inline int iNodes() const;
	inline int iInternals() const;
	nodeP fromName(const string inName) const; // get nodePTR from name
	bool WithBranchLength() const;
	void getNeigboursOfNode(vector<nodeP> &vNeighbourVector, const nodeP nodeNumber) const;
	MDOUBLE lengthBetweenNodes(nodeP i, nodeP j) const; // between neighbours nodes
	nodeP getSonOfRootIfRootIsAleaf() const;
	MDOUBLE findLengthBetweenAnyTwoNodes(const nodeP node1,const nodeP node2) const;
	void getPathBetweenAnyTwoNodes(vector<nodeP> &path,const nodeP node1, const nodeP node2) const;

	void getFromLeavesToRoot(vector<nodeP> &vNeighbourVector) const;
	void getFromRootToLeaves(vector<nodeP> &vec) const;
	void getFromNodeToLeaves(vector<nodeP> &vec, nodeP fromHereDown) const;

	void getAllHTUs(vector<nodeP> &vec,nodeP fromHereDown) const ;
	void getAllNodes(vector<nodeP> &vec,nodeP fromHereDown) const ;
	void getAllNodesBFS(vector<nodeP> &vec,nodeP fromHereDown) const ;
	void getAllLeaves(vector<nodeP> &vec,nodeP fromHereDown) const;

//*******************************************************************************
// change tree topoplogy parameters - should be applied carefully
//*******************************************************************************
	void rootAt(const nodeP newRoot);   //sets newRoot as the root. updates the iterator order lists.
//	void setLengthBetweenNodes(const nodeP i, const nodeP j, const MDOUBLE p_Length); //neighbour nodes only
	void multipleAllBranchesByFactor(const MDOUBLE InFactor);
	void create_names_to_internal_nodes();
//	void set_length_to_father(const nodeP iSon, const MDOUBLE dLength);	

	void removeNodeFromSonListOfItsFather(nodeP sonNode);
	// acording to the name of the sonNode
	// this function should ONLY be used when the node, sonNode, is to be recycled soon!
	// because this function does not change the number of leaves nor the number of nodes!
	// nor does it change the father of sonNode.






//	void remove_link_node(nodeP inNode);

//	void cut_tree_in_two(nodeP node2split,tree &small1,tree &small2) const;
//	void cut_tree_in_two_leaving_interMediate_node(nodeP node2split,tree &small1,tree &small2) const;
//	nodeP makeNodeBetweenTwoNodes(nodeP nodePTR1,nodeP nodePTR2, string &interName);
	void shrinkNode(nodeP nodePTR); // consider to move to treeUtil.
	void removeLeaf(nodeP nodePTR); // consider to move to treeUtil.
	void getAllBranch(vector<nodeP> &nodesUP, vector<nodeP> & nodesDown);
	void createRootNode();
	nodeP createNode(nodeP fatherNode, const int id);

// **********************************************************
//  initialization
// **********************************************************
	void createFlatLengthMatrix(const MDOUBLE newFlatDistance=FLAT_LENGTH_VALUE);   
//	void fillNodesID(); // give each TreeNode a uniq id.  

//*******************************************************************************
// Input-Output
//*******************************************************************************
	void output(string treeOutFile, TREEformats fmt= PHYLIP,bool withHTU=false) const;
	void output(ostream& os, TREEformats fmt= PHYLIP,bool withHTU=false) const;

private:
	void outputInAncestorTreeFormat(ostream& treeOutStream, bool withDist = false) const;
	void outputInPhylipTreeFormat(ostream& treeOutStream,bool withHTU=false) const;
	void outputInAncestorIdTreeFormat(ostream& treeOutStream, bool withDist = false) const;
	int print_from(nodeP from_node, ostream& os, bool withHTU) const;
//	void cut_tree_in_two_special(nodeP node2split,tree &small1,tree &small2);
	void getAllHTUsPrivate(vector<nodeP> &vec,nodeP fromHereDown) const ;
	void getAllNodesPrivate(vector<nodeP> &vec,nodeP fromHereDown) const ;
	void getAllLeavesPrivate(vector<nodeP> &vec,nodeP fromHereDown) const;

	bool readPhylipTreeTopology(istream& in,vector<char>& isFixed); //same as the constructor with file name
	bool readPhylipTreeTopology(const vector<char>& tree_contents,vector<char>& isFixed);
	bool readPhylipTreeTopology(istream& in); //same as the constructor with file name
	bool readPhylipTreeTopology(const vector<char>& tree_contents);

public: // it is used by treeUtil
	nodeP recursiveBuildTree( tree::nodeP father_nodePTR,const tree::nodeP other_nodePTR);
private:
	nodeP readPart(vector<char>::const_iterator& p_itCurrent,
		int& nextFreeID,vector<char> & isFixed);
	int print_from(nodeP from_node, ostream& os, bool withHTU);

public:// used by tree util.
	void updateNumberofNodesANDleaves();

};

inline int tree::iLeaves() const {return _leaves;}
inline int tree::iNodes() const {return _nodes;}
inline int tree::iInternals() const {return iNodes()-iLeaves();}

ostream &operator<<(ostream &out, const tree &tr);
}//end of namespace

#endif 

