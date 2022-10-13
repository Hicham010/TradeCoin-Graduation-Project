import React from "react";
import { useState } from "react";
import Modal from "react-modal";
import { ethers } from "ethers";

import ContractAdresses from "../contract-address.json";

const customStyles = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)",
  },
};

Modal.setAppElement("#root");

function ConnectModal() {
  const [modalIsOpen, setIsOpen] = useState(true);
  const [address, setAddress] = useState("");
  const [, setNetworkID] = useState(0);
  const [disableBtn, setDisableBtn] = useState(true);
  const [message, setMessage] = useState("");

  function closeModal() {
    setIsOpen(false);
  }

  async function getAccount() {
    if (window.ethereum) {
      let addr;
      const provider = new ethers.providers.Web3Provider(
        window.ethereum,
        "any"
      );

      let netID = (await provider.getNetwork()).chainId;
      setNetworkID(() => netID);
      // console.log(networkID);

      if (netID !== 5) {
        setMessage(
          "You must be connected to the Goerli test network. " +
            "Press the connect button again if you are connected."
        );
        addGoerli();
      } else {
        try {
          await provider.send("eth_requestAccounts", []);
          const signer = provider.getSigner();
          addr = await signer.getAddress();

          // console.log(addr);

          setAddress(() => addr);
          // console.log(address);
          setDisableBtn(false);
          setMessage(
            "Thank you for connecting with " +
              addr +
              ". You can add the NFTs to your wallet by pressing the buttons bellow. " +
              "Afterwards, you can close this window. "
          );
        } catch (error) {
          setMessage(error.message);
        }
      }
    } else {
      setMessage("MetaMask was not detected! Download MetaMask to continue.");
    }
  }

  async function isConnected() {
    if (address !== undefined) {
      const provider = new ethers.providers.Web3Provider(
        window.ethereum,
        "any"
      );
      let netID = (await provider.getNetwork()).chainId;
      const signer = provider.getSigner();
      let addr = await signer.getAddress();

      if (netID === 5 && addr !== undefined) {
        closeModal();
      }
    }
  }

  async function addGoerli() {
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("wallet_switchEthereumChain", [{ chainId: "0x5" }]);
    }
  }

  async function AddTCToWallet() {
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("wallet_watchAsset", {
        type: "ERC20",
        options: {
          address: ContractAdresses.TradeCoinV4,
          symbol: "TC",
          decimals: 0,
          image: "",
        },
      });
    }
  }

  async function AddTCCToWallet() {
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("wallet_watchAsset", {
        type: "ERC20",
        options: {
          address: ContractAdresses.TradeCoinComposition,
          symbol: "TCC",
          decimals: 0,
          image: "",
        },
      });
    }
  }

  async function AddTCTToWallet() {
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("wallet_watchAsset", {
        type: "ERC20",
        options: {
          address: ContractAdresses.TradeCoinTokenizerV2,
          symbol: "TCT",
          decimals: 0,
          image: "",
        },
      });
    }
  }

  // async function personalSign() {
  //   if (window.ethereum) {
  //     const provider = new ethers.providers.Web3Provider(window.ethereum);
  //     const signer = provider.getSigner();
  //     console.log(
  //       await signer.signMessage(
  //         ethers.utils.arrayify(ethers.utils.toUtf8Bytes("Test : Test"))
  //       )
  //     );
  //   }
  // }

  const AddAssets = () => {
    return (
      <div>
        <button onClick={AddTCTToWallet}>Add Token NFT</button>
        <button onClick={AddTCToWallet}>Add Commodity NFT</button>
        <button onClick={AddTCCToWallet}>Add Composition NFT</button>
      </div>
    );
  };

  if (window.ethereum) {
    return (
      <Modal
        isOpen={modalIsOpen}
        onAfterOpen={isConnected}
        onRequestClose={closeModal}
        style={customStyles}
        contentLabel="Connect Wallet Modal"
        shouldCloseOnOverlayClick={false}
        shouldCloseOnEsc={false}
        preventScroll={false}
      >
        <div>
          <h2>Welcome to TradeCoin</h2>
          <p>{message}</p>
          <button onClick={getAccount}>Connect</button>
          <button disabled={disableBtn} onClick={closeModal}>
            close
          </button>
        </div>
        <br />
        <div>{<AddAssets />}</div>
        {/* <button onClick={personalSign}>Sign Message</button> */}
      </Modal>
    );
  } else {
    return (
      <Modal
        isOpen={modalIsOpen}
        onAfterOpen={isConnected}
        onRequestClose={closeModal}
        style={customStyles}
        contentLabel="Connect Wallet Modal"
        shouldCloseOnOverlayClick={false}
        shouldCloseOnEsc={false}
        preventScroll={false}
      >
        <div>
          <h2>Welcome to TradeCoin</h2>
          <p>{message}</p>
          <button onClick={getAccount}>Connect</button>
          <button disabled={disableBtn} onClick={closeModal}>
            close
          </button>
        </div>
        <br />
        {/* <button onClick={personalSign}>Sign Message</button> */}
      </Modal>
    );
  }
}

export default ConnectModal;
