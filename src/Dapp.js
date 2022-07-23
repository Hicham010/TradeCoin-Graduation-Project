import React from "react";
import Navbar from "./ComponentsV2/Navbar";

import Tokenizer from "./ComponentsV2/Tokenizer/Tokenizer";
import TradeCoin from "./ComponentsV2/Tradecoin/TradeCoin";
import Composition from "./ComponentsV2/Composition/Composition";
import Journey from "./ComponentsV2/Journey.js/Journey";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { NotFound } from "./ComponentsV2/NotFound";
import ConnectModal from "./ComponentsV2/ConnectModal";
// import Navbar from "react-bootstrap/Navbar";

function TradeCoinDapp() {
  let Component;
  switch (window.location.pathname) {
    case "https://hicham010.github.io/TradeCoin-Graduation-Project/":
      Component = TradeCoin;
      break;
    case "https://hicham010.github.io/TradeCoin-Graduation-Project/tokenizer":
      Component = Tokenizer;
      break;
    case "https://hicham010.github.io/TradeCoin-Graduation-Project/commodity":
      Component = TradeCoin;
      break;
    case "https://hicham010.github.io/TradeCoin-Graduation-Project/composition":
      Component = Composition;
      break;
    case "https://hicham010.github.io/TradeCoin-Graduation-Project/journey":
      Component = Journey;
      break;
    default:
      Component = NotFound;
      break;
  }

  return (
    <div id="dapp">
      <div>
        <ConnectModal />
      </div>
      <div>
        <Navbar />
      </div>
      <div>
        <Component />
      </div>
      <ToastContainer />
    </div>
  );
}

export default TradeCoinDapp;
