import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import CompositionAbi from "../../artifacts/contracts/TradeCoinComposition.sol/TradeCoinCompositionV2.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function AppendCommodityToComposition() {
  const [compositionId, setCompositionId] = useState(undefined);
  const [commodityId, setCommodityId] = useState(undefined);
  const field = [
    ["Composition ID", setCompositionId],
    ["Commodity ID", setCommodityId],
  ];
  const [loading, setLoadingVal] = useState(false);

  async function appendCommodityToComposition() {
    if (!compositionId && !commodityId) return;
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
        CompositionAbi.abi,
        signer
      );

      let transaction;
      try {
        transaction = await contract.appendCommodityToComposition(
          compositionId,
          commodityId
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
      title="Append Commodity to Composition"
      func={appendCommodityToComposition}
      inputFields={field}
      loading={loading}
    />
  );
}

export default AppendCommodityToComposition;
