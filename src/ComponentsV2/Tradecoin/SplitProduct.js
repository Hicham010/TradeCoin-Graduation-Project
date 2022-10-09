import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function SplitProduct() {
  const [productID, setProductIDVal] = useState();
  const [partitions, setPartitionsVal] = useState([]);
  const [loading, setLoadingVal] = useState(false);

  const fields = [
    ["Product ID", setProductIDVal],
    ["Partitions", setPartitionsVal],
  ];

  const title = "Split Product";

  async function splitProduct() {
    if (!productID && !partitions) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw Error("error");
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
        transaction = await contract.splitCommodity(productID, partitions);
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
      title="Split Product"
      func={splitProduct}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default SplitProduct;
