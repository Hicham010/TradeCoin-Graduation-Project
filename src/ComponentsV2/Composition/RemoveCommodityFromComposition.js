import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinComposition.sol/TradeCoinCompositionV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function RemoveCommodityFromComposition() {
  const [compositionId, setCompositionId] = useState(undefined);
  const [indexCommodityId, setIndexCommodityId] = useState(undefined);
  const field = [
    ["Composition ID", setCompositionId],
    ["Index of Commodity ID", setIndexCommodityId],
  ];
  const [loading, setLoadingVal] = useState(false);

  async function removeCommodityFromComposition() {
    if (!compositionId && !indexCommodityId) return;
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
        transaction = await contract.removeCommodityFromComposition(
          compositionId,
          indexCommodityId
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
      title="Remove Commodity from Composition"
      func={removeCommodityFromComposition}
      inputFields={field}
      loading={loading}
    />
  );
}

export default RemoveCommodityFromComposition;
