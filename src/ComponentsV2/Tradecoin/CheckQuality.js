import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function CheckQuality() {
  const [productID, setProductIDVal] = useState(0);
  const [info, setInfoVal] = useState("");
  const [loading, setLoadingVal] = useState(false);

  const fields = [
    ["Product ID", setProductIDVal],
    ["Information", setInfoVal],
  ];

  async function checkQuality() {
    if (!productID && !info) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw "error";
      }

      setLoadingVal(true);

      // const provider = new ethers.providers.Web3Provider(window.ethereum);
      // const signer = provider.getSigner();
      // const contract = new ethers.Contract(
      //   ContractAdresses.TradeCoinV4,
      //   TradeCoinAbi.abi,
      //   signer
      // );
      let transaction;
      try {
        const signer = provider.getSigner();
        const contract = new ethers.Contract(
          ContractAdresses.TradeCoinV4,
          TradeCoinAbi.abi,
          signer
        );
        transaction = await contract.checkQualityOfCommodity(productID, info);
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
      title="Quality Check"
      func={checkQuality}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default CheckQuality;
