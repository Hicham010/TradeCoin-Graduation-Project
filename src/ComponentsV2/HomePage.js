import React from "react";

const HomePage = () => {
  return (
    <div
      className="card card--accent"
      style={{ marginLeft: "75px", marginRight: "75px" }}
    >
      <h1>TradeCoin Graduation Internship</h1>
      <p>
        My name is{" "}
        <a
          href="https://www.linkedin.com/in/hicham-el-marzgioui-62bb0b167/"
          target="_blank"
          rel="noreferrer"
        >
          Hicham El Marzgioui
        </a>{" "}
        and this is my graduation project for the Rotterdam University of
        Applied sciences. I did my internship at BlockLab, a company in
        Rotterdam, that focusses on energy and logistics. I received a 9.6 for
        my graduation thesis.
      </p>
      <p>
        The project I worked on was a proof of concept called TradeCoin. The
        goal of TradeCoin is to lower the deep-tiered financing risk which will
        increase the social, and economic impact for the deepest-tiered supply
        chain participants in the agricultural supply chain, because it will
        give them ability to get financing. To accomplish this a supply chain
        tracking system was to be developed that would track tokenized
        commodities in a safe accurate and trustworthy way. This was done by
        using non-fungible tokens that would represent the physical commodities
        on the blockchain. The digital twin is then supposed to mimic the
        commodity, that means that if a transformation happens on the commodity,
        for example a batch of coffee beans get roasted then this should be
        present on the digital twin itself as well.
      </p>
      <p>
        My internship was focussed on creating the smart contract architecture
        that would make creating a supply chain tracking system on the
        blockchain possible. So during my internship it wrote a bunch of smart
        contract. But because the concept of smart contracts and NFT's can be
        hard to understand I also developed this website to showcase how the
        smart contract work together in creating this tracking system. That is
        also why this website doesn't look all that nice. I mainly foccused on
        the smart contracts. Below you can find a couple of video's that show
        how to use the track system. The{" "}
        <a
          href=" https://github.com/Hicham010/TradeCoin-Graduation-Project/tree/main"
          target="_blank"
          rel="noreferrer"
        >
          code
        </a>{" "}
        for this project and the smart contracts on the Goerli testnet can be
        found here for the{" "}
        <a
          target="_blank"
          rel="noreferrer"
          href="https://goerli.etherscan.io/address/0xFeC45460C430eE549d9C66A5878752a37983eb9E"
        >
          tokenizer
        </a>
        ,{" "}
        <a
          target="_blank"
          rel="noreferrer"
          href="https://goerli.etherscan.io/address/0x17daF1039971ad3D7B872A6b334169E7f671F5ef"
        >
          commodity
        </a>{" "}
        and{" "}
        <a
          target="_blank"
          rel="noreferrer"
          href="https://goerli.etherscan.io/address/0x1c5ab1a09B81038C408db8A8962A8f681Bf6C4Cc"
        >
          composition
        </a>{" "}
        contract. The{" "}
        <a
          href="https://docs.google.com/document/d/19_4U9_X8TmUxjECiavANyn34iBZb-RgR/edit?usp=sharing&ouid=107555786808680859462&rtpof=true&sd=true"
          target="_blank"
          rel="noreferrer"
        >
          one-page summary
        </a>{" "}
        of my thesis and my{" "}
        <a
          href="https://docs.google.com/presentation/d/11kVBJ4BxDMFkLiu6cUIekctF8xeqBJN87OCCN9U0qr4/edit?usp=sharing"
          target="_blank"
          rel="noreferrer"
        >
          final presentation
        </a>{" "}
        for more information about my thesis.
      </p>
      <p>
        Thank you for visiting website and if you have any questions you can
        shoot me a message.
      </p>
      <br />

      <h4>Tutorial 1: Wallet Setup & Minting a Tokenizer NFT </h4>
      <p>
        This tutorial will show you how to setup your wallet to be able to use
        the tracking system. It will first prompt you to connect with your{" "}
        <a href="https://metamask.io/" target="_blank" rel="noreferrer">
          MetaMask extension
        </a>{" "}
        and then will ask you to switch to the Goerli testnet. If you don't have
        any Goerli Ether here is a{" "}
        <a
          href=" https://goerli-faucet.pk910.de/"
          target="_blank"
          rel="noreferrer"
        >
          faucet
        </a>{" "}
        where you can mine some . It is also recommended to add the Token NFT
        and Commodity NFT to your wallet so it will be visible after minting in
        your wallet. After the wallet setup a Token NFT will be minted which
        will be needed to mint a commodity NFT (digital twin). On the Journey
        page you can find the tokens you own with their corresponding ID's.
      </p>
      <iframe
        width="800"
        height="400"
        src="https://www.youtube.com/embed/0yyTmbD8zgo"
        title="TradeCoin Tutorial Part 1/3"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
      ></iframe>

      <br />
      <br />

      <h4>Tutorial 2: Role Assigment & Minting a Commodity NFT </h4>
      <p>
        The second tutorial will be about minting the commodity NFT. But first
        you will have to assign a couple of roles to your wallet. These roles
        would have normally been given to different wallets so multiple people
        can vouch for the creation of the digital twin. After the roles have
        been assigned a sale has to be initialised to sell the token to
        yourself. Normally, you would be a farmer selling to someone in the
        supply chain. After the initialisation the token can be minted, which
        happens by a handler in this case it is you. By minting the commodity
        NFT you also burn the tokenizer token.
      </p>
      <iframe
        width="800"
        height="400"
        src="https://www.youtube.com/embed/fvXRRNGOnKY"
        title="TradeCoin Tutorial Part 2/3"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
      ></iframe>

      <br />
      <br />

      <h4>Tutorial 3: Commodity Transformations & Commodity Journey </h4>
      <p>
        For the last tutorial we will add some information and transformations
        to our newly minted commodity token and see the commodity journey. This
        will also show why the token ID is so important because it will link all
        of information about the token back to it. After this will we then look
        at the commodity journey. Where we can find all of the transactions and
        wallets that have interacted with the digital twin.
      </p>
      <iframe
        width="800"
        height="400"
        src="https://www.youtube.com/embed/P8LWUI14P1U"
        title="TradeCoin Tutorial Part 3/3"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
      ></iframe>
    </div>
  );
};

export default HomePage;
