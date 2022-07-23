import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import CompositionAbi from "../../artifacts/contracts/TradeCoinComposition.sol/TradeCoinCompositionV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function CreateComposition() {
  const [compositionName, setCompositionName] = useState(undefined);
  const [tokenIdsOfTC, setTokenIdsOfTC] = useState(undefined);
  const [newHandler, setNewHandler] = useState(undefined);
  const field = [
    ["Name of Composition", setCompositionName],
    ["List of Commodity IDs", setTokenIdsOfTC],
    ["New Handler", setNewHandler],
  ];
  const [loading, setLoadingVal] = useState(false);

  async function createComposition() {
    if (!compositionName && !tokenIdsOfTC && !newHandler) return;
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
        CompositionAbi.abi,
        signer
      );

      let transaction;
      try {
        transaction = await contract.createComposition(
          compositionName,
          tokenIdsOfTC,
          //[1,2]
          newHandler
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
      title="Create Composition"
      func={createComposition}
      inputFields={field}
      loading={loading}
    />
  );
}

export default CreateComposition;
