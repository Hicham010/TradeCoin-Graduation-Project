import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import CompositionAbi from "../../artifacts/contracts/TradeCoinComposition.sol/TradeCoinCompositionV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function AddTransformer() {
  const [addressForRole, setAddressForRoleVal] = useState("");
  const [loading, setLoadingVal] = useState(false);

  const fields = [["Address for role", setAddressForRoleVal]];

  async function addTransformer() {
    if (!addressForRole) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw "error";
      }
      setLoadingVal(true);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        ContractAdresses.TradeCoinV4,
        CompositionAbi.abi,
        signer
      );

      let transaction;
      try {
        transaction = await contract.addTransformationHandler(addressForRole);

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
      title="Grant Transformer Handler Role"
      func={addTransformer}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default AddTransformer;
