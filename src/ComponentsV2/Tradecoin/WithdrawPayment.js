import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function WithdrawPayment() {
  const [tokenIdOfTokenizer, setTokenIdOfTokenizerVal] = useState(0);
  const field = [["Token ID", setTokenIdOfTokenizerVal]];
  const [loading, setLoadingVal] = useState(false);

  async function withdrawPayment() {
    if (!tokenIdOfTokenizer) return;
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
        TradeCoinAbi.abi,
        signer
      );
      let transaction;
      try {
        transaction = await contract.withdrawPayment(tokenIdOfTokenizer);
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
      title="Withdraw Payment"
      func={withdrawPayment}
      inputFields={field}
      loading={loading}
    />
  );
}

export default WithdrawPayment;
