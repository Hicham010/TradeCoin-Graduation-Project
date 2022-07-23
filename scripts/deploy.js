const { ethers } = require("hardhat");
const fs = require("fs");

// yours, or create new ones.
async function main() {
  const [deployer, ...accounts] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Tokenizer = await ethers.getContractFactory("TradeCoinTokenizerV2");
  const tokenizer = await Tokenizer.deploy();
  await tokenizer.deployed();

  const TradeCoin = await ethers.getContractFactory("TradeCoinV4");
  const tradeCoin = await TradeCoin.deploy(tokenizer.address);
  await tradeCoin.deployed();

  const Composition = await ethers.getContractFactory("TradeCoinCompositionV2");
  const composition = await Composition.deploy(tradeCoin.address);
  await composition.deployed();

  console.log("TradeCoinTokenizerV2 address:", tokenizer.address);
  console.log("TradeCoinV4 address:", tradeCoin.address);
  console.log("TradeCoinComposition address:", composition.address);

  saveFrontendFiles(tokenizer, tradeCoin, composition);
}

function saveFrontendFiles(tokenizer, tradeCoin, composition) {
  const contractsDir = __dirname + "/../src/artifacts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    JSON.stringify(
      {
        TradeCoinTokenizerV2: tokenizer.address,
        TradeCoinV4: tradeCoin.address,
        TradeCoinComposition: composition.address,
      },
      undefined,
      2
    )
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
