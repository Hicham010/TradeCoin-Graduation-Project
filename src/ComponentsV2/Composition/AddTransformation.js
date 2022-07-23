import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function AddTransformation() {
  const [productID, setProductIDVal] = useState(0);
  const [transformation, setTransformationVal] = useState("");
  const [loading, setLoadingVal] = useState(false);

  const fields = [
    ["Composition ID", setProductIDVal],
    ["Transformation", setTransformationVal],
  ];

  async function addTransformation() {
    if (!productID && !transformation) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw "error";
      }
      setLoadingVal(true);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        ContractAdresses.TradeCoinComposition,
        TradeCoinAbi.abi,
        signer
      );

      let transaction;
      try {
        transaction = await contract.addTransformation(
          productID,
          transformation
        );
        let receipt = await transaction.wait();
        setLoadingVal(false);
        notifySuccess(receipt.transactionHash);
      } catch (error) {
        setLoadingVal(false);
        let errorMessage =
          error?.error?.message !== undefined
            ? error.error.message
            : error?.message !== undefined
            ? error.message
            : error;
        notifyError(errorMessage);
      }
    }
  }

  return (
    <Card
      title="Add Transformation"
      func={addTransformation}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default AddTransformation;
