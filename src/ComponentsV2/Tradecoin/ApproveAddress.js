import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "./../../contract-address.json";
import Card from "../Card";
import { notifyError, notifySuccess } from "../ToastNotify";

function ApproveAddress() {
  const [tokenID, setTokenIDVal] = useState(undefined);
  const [address, setAddressVal] = useState(undefined);
  const field = [
    ["Token ID", setTokenIDVal],
    ["Address", setAddressVal],
  ];
  const [loading, setLoadingVal] = useState(false);

  async function approveAddress() {
    if (!tokenID & !address) return;
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
        TokenizerAbi.abi,
        signer
      );
      let transaction;
      try {
        transaction = await contract.approve(address, tokenID);
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
      title="Approve Address"
      func={approveAddress}
      inputFields={field}
      loading={loading}
    />
  );
}

export default ApproveAddress;
