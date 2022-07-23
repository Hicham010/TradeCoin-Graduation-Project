import React from "react";

import "../cards.scss";
import AddInformation from "./AddInformation";
import AddTransformation from "./AddTransformation";
import AddTransformer from "./AddTransformer";
import AppendCommodityToComposition from "./AppendCommodityToComposition";
import ApproveAddress from "./ApproveAddress";
import BurnComposition from "./BurnComposition";
import ChangeHandlerState from "./ChangeHandlerState";
import CheckQuality from "./CheckQuality";
import ConfirmLocation from "./ConfirmLocation";
import CreateComposition from "./CreateComposition";
import Decomposition from "./Decomposition";
import RemoveCommodityFromComposition from "./RemoveCommodityFromComposition";
import TransferFrom from "./TransferFrom";
import AddTokenizer from "./AddTokenizer";
import AddInformationHandler from "./AddInformationHandler";

function Composition() {
  return (
    <div>
      <div className="div3">
        <div className="div1">
          <CreateComposition />
        </div>
        <div className="div2">
          <AppendCommodityToComposition />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <RemoveCommodityFromComposition />
        </div>
        <div className="div1">
          <Decomposition />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <BurnComposition />
        </div>
        <div className="div1">
          <ConfirmLocation />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <AddInformation />
        </div>
        <div className="div1">
          <CheckQuality />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <AddTransformation />
        </div>
        <div className="div1">
          <ChangeHandlerState />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <TransferFrom />
        </div>
        <div className="div1">
          <ApproveAddress />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <AddTransformer />
        </div>
        <div className="div1">
          <AddTokenizer />
        </div>
      </div>

      <div className="div3">
        <div className="div2">
          <AddInformationHandler />
        </div>
      </div>
    </div>
  );
}

export default Composition;
