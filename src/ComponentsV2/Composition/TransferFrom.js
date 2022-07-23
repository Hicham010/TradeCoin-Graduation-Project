import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function TransferFrom() {
  const [tokenId, setTokenIdVal] = useState(undefined);
  const [toAddress, setToAddressVal] = useState(undefined);
  const [fromAddress, setFromAddressVal] = useState(undefined);
  const fields = [
    ["Token ID", setTokenIdVal],
    ["To Address", setToAddressVal],
    ["From Address", setFromAddressVal],
  ];
  const [loading, setLoadingVal] = useState(false);

  async function transferFrom() {
    if (!tokenId && !toAddress && !fromAddress) return;
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
        TokenizerAbi.abi,
        signer
      );

      let transaction;
      try {
        transaction = await contract.transferFrom(
          toAddress,
          fromAddress,
          tokenId
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
      title="Transfer From"
      func={transferFrom}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default TransferFrom;
