import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import CompositionAbi from "../../artifacts/contracts/TradeCoinComposition.sol/TradeCoinCompositionV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function ChangeHandlerState() {
  const [productID, setProductIDVal] = useState(0);
  const [newHandler, setNewHandlerVal] = useState("");
  const [state, setStateVal] = useState(0);
  const [loading, setLoadingVal] = useState(false);

  const fields = [
    ["Composition ID", setProductIDVal],
    ["New Handler", setNewHandlerVal],
    ["New State", setStateVal],
  ];

  async function changeHandlerState() {
    if (!productID && !newHandler && !state) return;
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
        transaction = await contract.changeCurrentHandlerAndState(
          productID,
          newHandler,
          state
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
      title="Change Handler & State"
      func={changeHandlerState}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default ChangeHandlerState;
