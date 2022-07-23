import { ethers } from "ethers";
import React, { useEffect, useState } from "react";
import { notifyError, notifyInfo } from "../ToastNotify";
import Select from "react-select";

import "../cards.scss";

import TokenizerAbi from "../../artifacts/contracts/TradeCoinTokenizerV2.sol/TradeCoinTokenizerV2.json";
import CommodityAbi from "../../artifacts/contracts/TradeCoinV4.sol/TradeCoinV4.json";
import CompositionAbi from "../../artifacts/contracts/TradeCoinComposition.sol/TradeCoinCompositionV2.json";

import ContractAdresses from "./../../contract-address.json";
import EventLogs from "./EventLogs";

let provider;

let tradeCoinCommodity;
let tradeCoinComposition;
let tradeCoinTokenizer;

let filterMintCommodity;
let filterTransCommodity;
let filterTransDecCommodity;
let filterSplitCommodity;
let filterBatchCommodity;
let filterBurnCommodity;
let filterStateHandlerCommodity;
let filterQualityCheckCommodity;
let filterLocationCommodity;
let filterInfoCommodity;
let filterEOLCommodity;
let filterTransferCommodity;
let filterApprCommodity;

let filterMintComposition;
let filterRemoveComComposition;
let filterAddComComposition;
let filterDecompComposition;
let filterTransComposition;
let filterTransDecComposition;
let filterBurnComposition;
let filterStateHandlerComposition;
let filterQualityCheckComposition;
let filterLocationComposition;
let filterInfoComposition;
let filterTransferComposition;
let filterApprComposition;

function Journey() {
  const [tokenId, setTokenIdVal] = useState();
  const [contractTC, setContractTCVal] = useState("");
  const [contractTCForOwned, setContractTCForOwnedVal] = useState("");
  const [allLogs, setAllLogsVal] = useState([]);

  const options = [
    { value: ContractAdresses.TradeCoinV4, label: "Commodity" },
    { value: ContractAdresses.TradeCoinComposition, label: "Composition" },
  ];

  const optionsForOwnedTokens = [
    { value: ContractAdresses.TradeCoinV4, label: "Commodity" },
    { value: ContractAdresses.TradeCoinComposition, label: "Composition" },
    { value: ContractAdresses.TradeCoinTokenizerV2, label: "Token" },
  ];

  useEffect(() => {
    provider = new ethers.providers.Web3Provider(window.ethereum);

    tradeCoinTokenizer = new ethers.Contract(
      ContractAdresses.TradeCoinTokenizerV2,
      TokenizerAbi.abi,
      provider
    );

    tradeCoinCommodity = new ethers.Contract(
      ContractAdresses.TradeCoinV4,
      CommodityAbi.abi,
      provider
    );

    filterMintCommodity = tradeCoinCommodity.filters.MintCommodity(tokenId);
    filterTransCommodity =
      tradeCoinCommodity.filters.CommodityTransformation(tokenId);
    filterTransDecCommodity =
      tradeCoinCommodity.filters.CommodityTransformationDecrease(tokenId);
    filterSplitCommodity = tradeCoinCommodity.filters.SplitCommodity(tokenId);
    filterBatchCommodity = tradeCoinCommodity.filters.BatchCommodities(tokenId);
    filterBurnCommodity = tradeCoinCommodity.filters.BurnCommodity(tokenId);
    filterStateHandlerCommodity =
      tradeCoinCommodity.filters.ChangeStateAndHandler(tokenId);
    filterQualityCheckCommodity =
      tradeCoinCommodity.filters.QualityCheckCommodity(tokenId);
    filterLocationCommodity =
      tradeCoinCommodity.filters.LocationOfCommodity(tokenId);
    filterInfoCommodity = tradeCoinCommodity.filters.AddInformation(tokenId);
    filterEOLCommodity =
      tradeCoinCommodity.filters.CommodityOutOfChain(tokenId);
    filterTransferCommodity = tradeCoinCommodity.filters.Transfer(
      null,
      null,
      tokenId
    );
    filterApprCommodity = tradeCoinCommodity.filters.Approval(
      null,
      null,
      tokenId
    );

    tradeCoinComposition = new ethers.Contract(
      ContractAdresses.TradeCoinComposition,
      CompositionAbi.abi,
      provider
    );

    filterMintComposition =
      tradeCoinComposition.filters.MintComposition(tokenId);
    filterRemoveComComposition =
      tradeCoinComposition.filters.RemoveCommodityFromComposition(tokenId);
    filterAddComComposition =
      tradeCoinComposition.filters.AppendCommodityToComposition(tokenId);
    filterDecompComposition =
      tradeCoinComposition.filters.Decomposition(tokenId);
    filterTransComposition =
      tradeCoinComposition.filters.CompositionTransformation(tokenId);
    filterTransDecComposition =
      tradeCoinComposition.filters.CompositionTransformationDecrease(tokenId);
    filterBurnComposition =
      tradeCoinComposition.filters.BurnComposition(tokenId);
    filterStateHandlerComposition =
      tradeCoinComposition.filters.ChangeStateAndHandler(tokenId);
    filterQualityCheckComposition =
      tradeCoinComposition.filters.QualityCheckComposition(tokenId);
    filterLocationComposition =
      tradeCoinComposition.filters.LocationOfComposition(tokenId);
    filterInfoComposition =
      tradeCoinComposition.filters.AddInformation(tokenId);
    filterTransferComposition = tradeCoinComposition.filters.Transfer(
      null,
      null,
      tokenId
    );
    filterApprComposition = tradeCoinComposition.filters.Approval(
      null,
      null,
      tokenId
    );
  });

  async function getAllLogsWithIdFromCommodity() {
    setAllLogsVal(() => []);
    console.log(contractTC);

    if (tokenId !== 0 && !tokenId) return;

    const tokenCounter =
      contractTC === ContractAdresses.TradeCoinV4
        ? (await tradeCoinCommodity.tokenCounter()).toNumber()
        : (await tradeCoinComposition.tokenCounter()).toNumber();

    const contractType =
      contractTC === ContractAdresses.TradeCoinV4
        ? "in the commodity contract."
        : "in the composition contract.";

    if (tokenId >= tokenCounter) {
      notifyError(`Token Id ${tokenId} does not exist ` + contractType);
      return;
    }

    let filtersCommodity = [
      filterMintCommodity,
      filterTransCommodity,
      filterTransDecCommodity,
      filterSplitCommodity,
      filterBatchCommodity,
      filterBurnCommodity,
      filterStateHandlerCommodity,
      filterQualityCheckCommodity,
      filterLocationCommodity,
      filterInfoCommodity,
      filterEOLCommodity,
      filterTransferCommodity,
      filterApprCommodity,
    ];

    let filtersComposition = [
      filterMintComposition,
      filterRemoveComComposition,
      filterAddComComposition,
      filterDecompComposition,
      filterTransComposition,
      filterTransDecComposition,
      filterBurnComposition,
      filterStateHandlerComposition,
      filterQualityCheckComposition,
      filterLocationComposition,
      filterInfoComposition,
      filterTransferComposition,
      filterApprComposition,
    ];

    let filters =
      contractTC === ContractAdresses.TradeCoinV4
        ? filtersCommodity
        : filtersComposition;

    filters.forEach(async (filter) => {
      let commodityLogs =
        contractTC === ContractAdresses.TradeCoinV4
          ? await tradeCoinCommodity.queryFilter(filter)
          : await tradeCoinComposition.queryFilter(filter);

      for (let i = 0; i < commodityLogs.length; i++) {
        const lengthArgs = commodityLogs[i].args.length;
        const logs = commodityLogs[i];

        let eventParams = Object.entries(commodityLogs[i].args).slice(
          lengthArgs,
          lengthArgs * 2 + 1
        );

        eventParams.unshift(["Event", logs.event]);
        const date = (await commodityLogs[i].getBlock()).timestamp;
        eventParams.push(["Date", new Date(date * 1000)]);

        setAllLogsVal((allLogs) => [...allLogs, eventParams]);
      }
    });
    // console.log(allLogs);
    setTokenIdVal(undefined);
  }

  async function getAllCommoditiesOwned() {
    const addressOfWallet = await provider.getSigner().getAddress();
    let contract;
    let contractType;

    if (contractTCForOwned === ContractAdresses.TradeCoinV4) {
      contractType = "in the commodity contract.";
      contract = tradeCoinCommodity;
    } else if (contractTCForOwned === ContractAdresses.TradeCoinComposition) {
      contractType = "in the composition contract.";
      contract = tradeCoinComposition;
    } else {
      contractType = "in the tokenizer contract.";
      contract = tradeCoinTokenizer;
    }

    const balanceOf = (await contract.balanceOf(addressOfWallet)).toNumber();

    const tokenCounter = (await contract.tokenCounter()).toNumber();

    let mapOfOwnerIds = [];
    for (let i = 0; i < tokenCounter; i++) {
      if (balanceOf === mapOfOwnerIds.length) break;

      let ownerOfId = await contract.ownerOf(i);
      if (ownerOfId === addressOfWallet) {
        mapOfOwnerIds.push([i]);
      }
    }

    if (mapOfOwnerIds.length === 0) {
      notifyInfo("You own no tokens " + contractType);
    } else {
      notifyInfo(
        "You own the following token(s) ID(s): " +
          mapOfOwnerIds.toString() +
          " " +
          contractType
      );
    }
  }

  if (allLogs.length !== 0) {
    console.log(allLogs);
    return (
      <div>
        <div>
          <div className="div1">
            <div className="l-design-widht">
              <div className="card card--accent">
                <input
                  className="input__field"
                  placeholder="Fill in a tokenId"
                  onChange={(e) => setTokenIdVal(Number(e.target.value))}
                />
                <Select
                  options={options}
                  onChange={(e) => setContractTCVal(e.value)}
                />
                <button
                  className="button-journey"
                  // className="button-V2"
                  onClick={getAllLogsWithIdFromCommodity}
                >
                  All Logs
                </button>
              </div>
            </div>
          </div>
          <div className="div2">
            <div className="l-design-widht">
              <div className="card card--accent">
                <Select
                  options={optionsForOwnedTokens}
                  onChange={(e) => setContractTCForOwnedVal(e.value)}
                />
                <button
                  className="button-journey"
                  onClick={getAllCommoditiesOwned}
                >
                  Get All Owned Tokens
                </button>
              </div>
            </div>
          </div>
        </div>
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <div className="centered">
          <EventLogs
            logs={allLogs}
            onChange={(e) => setContractTCVal(e.value)}
          />
        </div>
      </div>
    );
  } else {
    return (
      <div>
        <div className="div3">
          <div className="div1">
            <div className="l-design-widht">
              <div className="card card--accent">
                <input
                  className="input__field"
                  placeholder="Fill in a tokenId"
                  onChange={(e) => setTokenIdVal(Number(e.target.value))}
                />
                <Select
                  options={options}
                  onChange={(e) => setContractTCVal(e.value)}
                />
                <button
                  className="button-journey"
                  // className="button-V2"
                  onClick={getAllLogsWithIdFromCommodity}
                >
                  All Logs
                </button>
              </div>
            </div>
          </div>
          <div className="div2">
            <div className="l-design-widht">
              <div className="card card--accent">
                <Select
                  options={optionsForOwnedTokens}
                  onChange={(e) => setContractTCForOwnedVal(e.value)}
                />
                <button
                  className="button-journey"
                  onClick={getAllCommoditiesOwned}
                >
                  Get All Owned Tokens
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

export default Journey;
