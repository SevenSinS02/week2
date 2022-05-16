import "./App.css";
import { useState } from "react";
import { ethers } from "ethers";
import MerkleTree from "./artifacts/contracts/MerkleTree.sol/MerkleTree.json";
import { groth16 } from "snarkjs";
import verificationKey from "./verification_key.json";
// Update with the contract address logged out to the CLI when it was deployed
//change it after running deploy.js
const merkleTreeAddress = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";

//simple, rather than over ride CRA's configs
//could probably use a a wasm loader with webpack
let wasmFile = `${process.env.PUBLIC_URL}/circuit.wasm`;
let zkeyFile = `${process.env.PUBLIC_URL}/circuit_final.zkey`;

function App() {
  // store greeting in local state
  const [hashedLeaf, setHashedLeaf] = useState(null);
  const [leaf, setLeaf] = useState(null);
  const [pathElements, setPathElements] = useState([]);
  const [pathIndex, setPathIndex] = useState([]);
  const [proof, setProof] = useState("");
  const [isValid, setIsValid] = useState(false);
  const [isAdded, setIsAdded] = useState(false);

  // request access to the user's MetaMask account
  async function requestAccount() {
    await window.ethereum.request({ method: "eth_requestAccounts" });
  }

  //genereate proof
  async function generateAndVerifyProof() {
    if (typeof window.ethereum !== "undefined") {
      if (!leaf || pathElements.length === 0 || pathIndex.length === 0) {
        return;
      }
      try {
        const { proof, publicSignals } = await groth16.fullProve(
          {
            leaf,
            path_elements: pathElements,
            path_index: pathIndex,
          },
          wasmFile,
          zkeyFile
        );
        setProof(JSON.stringify(proof, null, 2));

        const result = await groth16.verify(
          verificationKey,
          publicSignals,
          proof
        );
        console.log(result);
        setIsValid(result);
        setIsAdded(false);
      } catch (err) {
        setIsValid(false);
        console.log("Error: ", err);
      }
    }
  }

  // insertLeaf
  async function insertLeaf() {
    if (!hashedLeaf) return;
    if (typeof window.ethereum !== "undefined") {
      try {
        await requestAccount();
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(
          merkleTreeAddress,
          MerkleTree.abi,
          signer
        );
        const transaction = await contract.insertLeaf(hashedLeaf);
        await transaction.wait();
        setIsAdded(true);
        setProof("");
      } catch (err) {
        console.log(err);
      }
    }
  }

  return (
    <div className="App">
      <div className="App-header">
        <div style={{ margin: 10 }}>
          <input
            onChange={(e) => setLeaf(e.target.value)}
            placeholder="Set leaf"
          />
          <input
            onChange={(e) => {
              const pathElementArray = e.target.value.trim().split(",");
              console.log(e.target.value);
              setPathElements(pathElementArray);
            }}
            placeholder="Set path Elements"
          />
          <input
            onChange={(e) => {
              const pathIndexArray = e.target.value.split(",");
              console.log(pathIndexArray);
              return setPathIndex(pathIndexArray);
            }}
            placeholder="Set path Index"
          />
        </div>
        <button onClick={generateAndVerifyProof}>Generate Proof</button>
        <div style={{ margin: 10, flexDirection: "column" }}>
          <input
            onChange={(e) => setHashedLeaf(e.target.value)}
            placeholder="Set hashed leaf"
          />
        </div>
        <button onClick={insertLeaf}>Set Hashed Leaf</button>

        {proof && <p>{isValid ? "Valid proof" : "Invalid proof"}</p>}
        {isAdded ? <p>Node Successfully Added</p> : null}
      </div>
    </div>
  );
}

export default App;
