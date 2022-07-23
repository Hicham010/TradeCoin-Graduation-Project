import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function InitializeSale() {
  const [owner, setOwnerVal] = useState("");
  const [handler, setHandlerVal] = useState("");
  const [tokenIdOfTokenizer, setTokenIdOfTokenizerVal] = useState(0);
  const [priceInEther, setPriceInWei] = useState(0);
  const [loading, setLoadingVal] = useState(false);

  const fields = [
    ["New Owner", setOwnerVal],
    ["Handler", setHandlerVal],
    ["Token ID", setTokenIdOfTokenizerVal],
    ["Price In Ether", setPriceInWei],
  ];

  async function initializeSale() {
    if (!owner && !handler && !tokenIdOfTokenizer && !priceInEther) return;
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
      let priceInEtherString = ethers.utils.parseEther(priceInEther);

      let transaction;
      try {
        transaction = await contract.initializeSale(
          owner,
          handler,
          tokenIdOfTokenizer,
          priceInEtherString
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
      title="Initialize Sale"
      func={initializeSale}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default InitializeSale;
