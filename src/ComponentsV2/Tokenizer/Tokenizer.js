import React from "react";

import MintToken from "./MintToken";
import IncreaseAmount from "./IncreaseAmount";
import DecreaseAmount from "./DecreaseAmount";
import Burn from "./Burn";

import "../cards.scss";
import TransferFrom from "./TransferFrom";
import Approve from "./Approve";
import ApproveAddress from "./ApproveAddress";

function Tokenizer() {
  return (
    <div>
      <div className="div3">
        <div className="div1">
          <MintToken />
        </div>
        <div className="div2">
          <TransferFrom />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <Approve />
        </div>
        <div className="div2">
          <IncreaseAmount />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <DecreaseAmount />
        </div>
        <div className="div2">
          <Burn />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <ApproveAddress />
        </div>
        <div className="div2">{/* <Burn /> */}</div>
      </div>
    </div>
  );
}

export default Tokenizer;
