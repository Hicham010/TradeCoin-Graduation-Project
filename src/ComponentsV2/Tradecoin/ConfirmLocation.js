import React from "react";
import { useState } from "react";
import { ethers } from "ethers";

import TradeCoinAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import ContractAdresses from "./../../contract-address.json";
import { notifyError, notifySuccess } from "../ToastNotify";

import Card from "../Card";

function ConfirmLocation() {
  const [productID, setProductIDVal] = useState(0);
  const [latitude, setLatitudeVal] = useState(0);
  const [longitude, setLongitudeVal] = useState(0);
  const [radius, setRadiusVal] = useState(0);
  const [loading, setLoadingVal] = useState(false);

  const fields = [
    ["Product ID", setProductIDVal],
    ["Latitude", setLatitudeVal],
    ["Longitude", setLongitudeVal],
    ["Radius", setRadiusVal],
  ];

  async function confirmLocation() {
    if (!productID && !latitude && !longitude && !radius) return;
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
        transaction = await contract.confirmCommodityLocation(
          productID,
          latitude,
          longitude,
          radius
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
      title="Confirm Location"
      func={confirmLocation}
      inputFields={fields}
      loading={loading}
    />
  );
}

export default ConfirmLocation;
