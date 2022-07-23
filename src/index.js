import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import TradeCoinDapp from "./Dapp";
import { HashRouter } from "react-router-dom";

ReactDOM.render(
  <React.StrictMode>
    <HashRouter>
      <TradeCoinDapp />
    </HashRouter>
  </React.StrictMode>,
  document.getElementById("root")
);
