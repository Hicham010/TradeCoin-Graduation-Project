import { toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

export const notifyError = (error) => {
  toast.error(error, {
    position: "top-right",
    autoClose: 5000,
    hideProgressBar: false,
    closeOnClick: true,
    pauseOnHover: true,
    draggable: true,
    progress: undefined,
  });
};

const EtherscanLinkOfTx = ({ txHash, functionName }) => {
  return (
    <div>
      <div>{functionName}, Transaction Successful</div>
      <a
        href={"https://goerli.etherscan.io/tx/" + txHash}
        target="_blank"
        rel="noreferrer"
      >
        View Transaction
      </a>
    </div>
  );
};

export const notifySuccess = (txHash, functionName) => {
  toast.success(
    <EtherscanLinkOfTx txHash={txHash} functionName={functionName} />,
    {
      position: "top-right",
      autoClose: 5000,
      hideProgressBar: false,
      closeOnClick: true,
      pauseOnHover: true,
      draggable: true,
      progress: undefined,
    }
  );
};

export const notifyInfo = (info) => {
  toast.info(info, {
    position: "top-right",
    autoClose: 10000,
    hideProgressBar: false,
    closeOnClick: true,
    pauseOnHover: true,
    draggable: true,
    progress: undefined,
  });
};
