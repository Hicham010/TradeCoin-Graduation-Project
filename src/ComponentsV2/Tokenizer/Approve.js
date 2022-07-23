import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "./../../contract-address.json";
import Card from "../Card";
import { notifyError, notifySuccess } from "../ToastNotify";

function Approve() {
  const [tokenID, setTokenIDVal] = useState(undefined);
  const field = [["Token ID", setTokenIDVal]];
  const [loading, setLoadingVal] = useState(false);

  async function approve() {
    if (!tokenID) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw "error";
      }
      setLoadingVal(true);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        ContractAdresses.TradeCoinTokenizerV2,
        TokenizerAbi.abi,
        signer
      );
      let transaction;
      try {
        transaction = await contract.approve(
          ContractAdresses.TradeCoinV4,
          tokenID
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
      title="Approve TradeCoin Contract"
      func={approve}
      inputFields={field}
      loading={loading}
    />
  );
}

export default Approve;
