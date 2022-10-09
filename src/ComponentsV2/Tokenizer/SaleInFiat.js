import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "../../artifacts/contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function SaleInFiat() {
  const [tokenId, setTokenIdVal] = useState(0);
  const [owner, setOwnerVal] = useState("");
  const [handler, setHandlerVal] = useState("");
  const fields = [
    ["Commodity ID", setTokenIdVal],
    ["New Owner", setOwnerVal],
    ["Handler", setHandlerVal],
  ];

  async function saleInFiat() {
    if (!tokenId && !owner && !handler) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw Error("error");
      }
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        ContractAdresses.TradeCoinTokenizerV2,
        TokenizerAbi.abi,
        signer
      );
      const transaction = await contract.initializeCommoditySaleInFiat(
        tokenId,
        owner,
        handler
      );
      await transaction.wait();
    }
  }

  return <Card title="Sale In Fiat" func={saleInFiat} inputFields={fields} />;
}

export default SaleInFiat;
