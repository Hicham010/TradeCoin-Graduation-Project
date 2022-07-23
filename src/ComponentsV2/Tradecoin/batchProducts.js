import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import Card from "../Card";
import { notifyError, notifySuccess } from "../ToastNotify";

function BatchProducts() {
  const [productIDs, setProductIDsVal] = useState([]);
  const [loading, setLoadingVal] = useState(false);

  const fields = [["Product IDs", setProductIDsVal]];

  async function batchProducts() {
    if (!productIDs) return;
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
        transaction = await contract.batchCommodities(productIDs);
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
      title="Batch Products"
      func={batchProducts}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default BatchProducts;
