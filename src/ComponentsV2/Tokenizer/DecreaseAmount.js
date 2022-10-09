import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function DecreaseAmount() {
  const [tokenId, setTokenIdVal] = useState(0);
  const [amount, setAmountVal] = useState(0);
  const [loading, setLoadingVal] = useState(false);
  const fields = [
    ["Token ID", setTokenIdVal],
    ["Amount", setAmountVal],
  ];
  const title = "Decrease Amount";

  async function decreaseAmount() {
    if (!tokenId && !amount) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw Error("error");
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
        transaction = await contract.decreaseAmount(tokenId, amount);
        let receipt = await transaction.wait();
        setLoadingVal(false);
        notifySuccess(receipt.transactionHash, title);
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
      title="Decrease Amount"
      func={decreaseAmount}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default DecreaseAmount;
