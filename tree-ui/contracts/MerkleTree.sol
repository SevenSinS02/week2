//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256 public constant LEVELS = 3;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        uint256 totalNodes = 2 * (2**LEVELS) - 1;
        for (uint256 i = 0; i < totalNodes; i++) {
            hashes.push(0);
        }
        _calculateRoot();
    }

    //internal function to calculate merkle root
    function _calculateRoot() internal {
        uint256 totalLeaves = 2**LEVELS;
        uint256 left;
        uint256 right;
        uint256 j;

        //traverse the tree and calculate the hashes of the leaves and subroot and get merkle root
        for (uint256 i = totalLeaves; i < 15; i++) {
            left = hashes[2 * j];
            right = hashes[2 * j + 1];
            hashes[i] = PoseidonT3.poseidon([left, right]);
            j++;
        }

        root = hashes[hashes.length - 1]; //merkle root
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        uint256 currentIndex = index;
        //check if empty leaf nodes are available
        require(currentIndex != uint256(2)**3, "Merkle tree is full");
        //add hashedLeaf to current available leaf node
        hashes[currentIndex] = hashedLeaf;
        _calculateRoot();
        //increment the index to point to next available leaf node
        index = currentIndex + 1;
        //return index of added leaf node
        return currentIndex;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        require(input[0] == root, "Incorrect Merkle root");
        return verifyProof(a, b, c, input);
    }
}
