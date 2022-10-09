import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function PaymentOfToken() {
  const [tokenIdOfTokenizer, setTokenIdOfTokenizerVal] = useState(0);
  const field = [["Token ID", setTokenIdOfTokenizerVal]];
  const [loading, setLoadingVal] = useState(false);

  const title = "Payment Of Token";

  var priceInWei;

  async function paymentOfToken() {
    if (!tokenIdOfTokenizer) return;
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

      // [, , , , priceInWei] = await contract.commoditySaleQueue(
      //   tokenIdOfTokenizer
      // );
      // let priceInWeiString = ethers.utils.formatEther(priceInWei);

      // transaction = await contract.paymentOfToken(tokenIdOfTokenizer, {
      //   value: ethers.utils.parseEther(priceInWeiString),
      // });
      // await transaction.wait();
      // setLoadingVal(false);

      let transaction;
      try {
        [, , , , priceInWei] = await contract.commoditySaleQueue(
          tokenIdOfTokenizer
        );
        let priceInWeiString = ethers.utils.formatEther(priceInWei);

        transaction = await contract.paymentOfToken(tokenIdOfTokenizer, {
          value: ethers.utils.parseEther(priceInWeiString),
        });
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
      title="Payment Of Token"
      func={paymentOfToken}
      inputFields={field}
      loading={loading}
    />
  );
}

export default PaymentOfToken;
