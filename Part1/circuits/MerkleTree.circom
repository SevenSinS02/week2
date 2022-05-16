pragma circom 2.0.0;
//Reference: https://github.com/appliedzkp/maci/blob/40bfb8de23183e15af9c0ab069fda2da718cc4b6/circuits/circom/merkletree.circom
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    var leafNodesLength=2**n; //number of leaf nodes
    var leafHashesLength = leafNodesLength >> 1; //number of posiedon hash functions to hash leaf nodes
    var interLeafHashesLength = leafHashesLength - 1;// number of poseidon hash functions for the sub roots
    var hashesLength = leafNodesLength - 1; // number of posiedon hash functions needed

    component poseidon[leafNodesLength - 1]; //declare poseidon hash component

    for(var i=0;i<leafNodesLength;i++){
        poseidon[i] = Poseidon(2); //instantiate poseidon hash component
    }

    // for n-1 sub roots
    for(var i=0; i<leafHashesLength; i++){
        poseidon[i].inputs[0] <== leaves[2*i];
        poseidon[i].inputs[1] <== leaves[2*i+1];
    }

    //calculate the rest of the sub roots and the root
    for(var i=leafHashesLength, k=0; i<leafHashesLength + interLeafHashesLength ;i++){
        poseidon[i].inputs[0] <== poseidon[2*k].out;
        poseidon[i].inputs[1] <== poseidon[2*k+1].out;
        k++;
    }

    root <== poseidon[leafNodesLength - 1].out; // the merkle root
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component switchers[n];
    component hashers[n];

     for (var i = 0; i < n; i++) {
      switchers[i] = Switcher();
      hashers[i] = Poseidon(2);
    }

    for(var i=0;i<n;i++){
        path_index[i] ==> switchers[i].sel;
        path_elements[i] ==> switchers[i].R;
    }

    leaf ==> switchers[0].L;
    switchers[0].outL ==> hashers[0].inputs[0];
    switchers[0].outR ==> hashers[0].inputs[1];

    for(var i=1; i<n; i++){
        hashers[i-1].out ==> switchers[i].L;
        switchers[i].outL ==> hashers[i].inputs[0];
        switchers[i].outR ==> hashers[i].inputs[1];
    }
     root <== hashers[n - 1].out;

}