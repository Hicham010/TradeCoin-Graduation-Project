import React from "react";
import "../cards.scss";
import AddInformation from "./AddInformation";
import AddTransformation from "./AddTransformation";
import AddTransformationDec from "./AddTransformationDec";
import ApproveForComposition from "./ApproveForComposition";
import BatchProducts from "./batchProducts";
import BurnProduct from "./BurnProduct";
import ChangeHandlerState from "./ChangeHandlerState";
import CheckQuality from "./CheckQuality";
import ConfirmLocation from "./ConfirmLocation";
import InitializeSale from "./InitializeSale";
import MintProduct from "./MintProduct";
import PaymentOfToken from "./PaymentOfToken";
import SplitProduct from "./SplitProduct";
import WithdrawPayment from "./WithdrawPayment";
import ApproveAddress from "./ApproveAddress";
import TransferFrom from "../Tokenizer/TransferFrom";
import AddTokenizer from "./AddTokenizer";
import AddTransformer from "./AddTransformer";
import AddInformationHandler from "./AddInformationHandler";
import ConnectModal from "../ConnectModal";

function TradeCoin() {
  return (
    <div>
      <div>
        <ConnectModal />
      </div>
      <div className="div3">
        <div className="div1">
          <InitializeSale />
        </div>
        <div className="div2">
          <PaymentOfToken />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <MintProduct />
        </div>
        <div className="div2">
          <WithdrawPayment />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <AddTransformation />
        </div>
        <div className="div2">
          <AddTransformationDec />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <AddInformation />
        </div>
        <div className="div2">
          <CheckQuality />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <ConfirmLocation />
        </div>
        <div className="div2">
          <BurnProduct />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <BatchProducts />
        </div>
        <div className="div2">
          <SplitProduct />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <ApproveForComposition />
        </div>
        <div className="div2">
          <ApproveAddress />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <TransferFrom />
        </div>
        <div className="div2">
          <ChangeHandlerState />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <AddTokenizer />
        </div>
        <div className="div2">
          <AddTransformer />
        </div>
      </div>

      <div className="div3">
        <div className="div1">
          <AddInformationHandler />
        </div>
      </div>
    </div>
  );
}

export default TradeCoin;
