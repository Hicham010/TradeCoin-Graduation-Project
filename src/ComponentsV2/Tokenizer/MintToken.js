import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function MintToken() {
  const [commodity, setCommodityVal] = useState("");
  const [amount, setAmountVal] = useState(0);
  const [unit, setUnitVal] = useState(0);
  const fields = [
    ["Commodity Name", setCommodityVal],
    ["Amount", setAmountVal],
    ["Unit", setUnitVal],
  ];
  const [loading, setLoadingVal] = useState(false);
  const title = "Mint Token";

  async function mintToken() {
    if (!commodity && !amount && !unit) return;
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
        transaction = await contract.mintToken(commodity, amount, unit);
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
    <div>
      <Card
        title="Mint Token"
        func={mintToken}
        inputFields={fields}
        loading={loading}
      />
    </div>
  );
}

export default MintToken;
