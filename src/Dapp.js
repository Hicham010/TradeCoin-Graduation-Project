import React from "react";
import Navbar from "./ComponentsV2/Navbar";

import Tokenizer from "./ComponentsV2/Tokenizer/Tokenizer";
import TradeCoin from "./ComponentsV2/Tradecoin/TradeCoin";
import Composition from "./ComponentsV2/Composition/Composition";
import Journey from "./ComponentsV2/Journey.js/Journey";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
// import { NotFound } from "./ComponentsV2/NotFound";
// import ConnectModal from "./ComponentsV2/ConnectModal";
import { Route, Routes } from "react-router-dom";
import HomePage from "./ComponentsV2/HomePage";
// import Navbar from "react-bootstrap/Navbar";

function TradeCoinDapp() {
  return (
    <div id="dapp">
      {/* <div>
        <ConnectModal />
      </div> */}
      <Navbar />
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/tokenizer" element={<Tokenizer />} />
        <Route path="/commodity" element={<TradeCoin />} />
        <Route path="/composition" element={<Composition />} />
        <Route path="/journey" element={<Journey />} />
      </Routes>
      <ToastContainer />
    </div>
  );
}

export default TradeCoinDapp;
