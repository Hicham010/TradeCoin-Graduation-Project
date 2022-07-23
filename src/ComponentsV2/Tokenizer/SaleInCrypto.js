import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import ContractAdresses from "../../artifacts/contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";
import Card from "../Card";

function SaleInCrypto() {
  const [tokenId, setTokenIdVal] = useState(0);
  const [owner, setOwnerVal] = useState("");
  const [handler, setHandlerVal] = useState("");
  const [priceInWei, setPriceInWeiVal] = useState(0);
  const fields = [
    ["Commodity ID", setTokenIdVal],
    ["New Owner", setOwnerVal],
    ["Handler", setHandlerVal],
    ["Price in wei", setPriceInWeiVal],
  ];

  async function saleInCrypto() {
    if (!tokenId && !owner && !handler && !priceInWei) return;
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      if ((await provider.getNetwork()).chainId !== 5) {
        notifyError("Connect to the Goerli test net!");
        throw "error";
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
        transaction = await contract.initializeCommoditySaleInCrypto(
          tokenId,
          owner,
          handler,
          priceInWei
        );
        await transaction.wait();
        setLoadingVal(false);
        notifySuccess();
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
    <Card title="Sale In Crypto" func={saleInCrypto} inputFields={fields} />
  );
}

export default SaleInCrypto;
