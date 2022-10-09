/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
const { ethers } = require("hardhat");

let TradeCoinTokenizer;
let tradeCoinTokenizer;

let admin;
let tokenizer;
let tokenizer2;
let accounts;

let address0;

beforeEach(async function () {
  TradeCoinTokenizer = await ethers.getContractFactory("TradeCoinTokenizerV2");
  tradeCoinTokenizer = await TradeCoinTokenizer.deploy();
  await tradeCoinTokenizer.deployed();

  [admin, tokenizer, tokenizer2, ...accounts] = await ethers.getSigners();

  address0 = "0x0000000000000000000000000000000000000000";
});

describe("Testing the tokenizatihhon functions of the TradeCoinTokenizer", function () {
  describe("Test the tokenization functions", function () {
    it("Should tokenize 10kg of cashew", async function () {
      const commodityTest = "cashew";
      const amountTest = 10;
      const unitTest = "kg";

      await expect(
        tradeCoinTokenizer
          .connect(tokenizer)
          .mintToken(commodityTest, amountTest, unitTest)
      )
        .to.emit(tradeCoinTokenizer, "MintToken")
        .withArgs(0, tokenizer.address, "cashew", 10, "kg");

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });

    it("Should tokenize 100bu of grain", async function () {
      const commodityTest = "grain";
      const amountTest = 100;
      const unitTest = "bu";

      await expect(
        tradeCoinTokenizer
          .connect(tokenizer)
          .mintToken(commodityTest, amountTest, unitTest)
      )
        .to.emit(tradeCoinTokenizer, "MintToken")
        .withArgs(0, tokenizer.address, commodityTest, amountTest, unitTest);

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });
  });

  describe("Testing the increase and decrease function", function () {
    it("Should increase a 10kg of cashew to 20kg", async function () {
      const commodityTest = "cashew";
      const amountTest = 10;
      const unitTest = "kg";
      const amountIncrease = 10;

      await tradeCoinTokenizer
        .connect(tokenizer)
        .mintToken(commodityTest, amountTest, unitTest);

      expect(
        await tradeCoinTokenizer
          .connect(tokenizer)
          .increaseAmount(0, amountIncrease)
      );
      // .to.emit(tradeCoinTokenizer, "IncreaseCommodity")
      // .withArgs(0, 10);

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest + amountIncrease).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });

    it("Should decrease a 20l of olive oil to 10l", async function () {
      const commodityTest = "olive oil";
      const amountTest = 20;
      const unitTest = "l";
      const amountDecrease = 10;

      await tradeCoinTokenizer
        .connect(tokenizer)
        .mintToken(commodityTest, amountTest, unitTest);

      expect(
        await tradeCoinTokenizer
          .connect(tokenizer)
          .decreaseAmount(0, amountDecrease)
      );
      // .to.emit(tradeCoinTokenizer, "DecreaseCommodity")
      // .withArgs(0, 10);

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest - amountDecrease).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });

    it("Should revert: caller is not the owner so can't increase amount", async function () {
      const commodityTest = "cashew";
      const amountTest = 10;
      const unitTest = "kg";
      const amountIncrease = 10;

      await tradeCoinTokenizer
        .connect(tokenizer)
        .mintToken(commodityTest, amountTest, unitTest);

      await expect(
        tradeCoinTokenizer.connect(tokenizer2).increaseAmount(0, amountIncrease)
      ).to.be.revertedWith("Not the owner");

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });

    it("Should revert: the caller is not the owner and can't decrease amount", async function () {
      const commodityTest = "cashew";
      const amountTest = 20;
      const unitTest = "kg";
      const amountDecrease = 10;

      await tradeCoinTokenizer
        .connect(tokenizer)
        .mintToken(commodityTest, amountTest, unitTest);

      await expect(
        tradeCoinTokenizer.connect(tokenizer2).decreaseAmount(0, amountDecrease)
      ).to.be.revertedWith("Not the owner");

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });
  });

  describe("Testing the burning function", function () {
    it("Should burn a 20kg of cashew", async function () {
      const commodityTest = "cashew";
      const amountTest = 20;
      const unitTest = "kg";

      await tradeCoinTokenizer
        .connect(tokenizer)
        .mintToken(commodityTest, amountTest, unitTest);

      let [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);

      await tradeCoinTokenizer.connect(tokenizer).burnToken(0);

      [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      // expect("").to.equal(commodity0);
      // expect(0).to.equal(amount0.toNumber());
      // expect("").to.equal(unit0);

      await expect(tradeCoinTokenizer.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });

    it("Should revert: because the caller is not the owner and can't burn the token", async function () {
      const commodityTest = "cashew";
      const amountTest = 20;
      const unitTest = "kg";

      await tradeCoinTokenizer
        .connect(tokenizer)
        .mintToken(commodityTest, amountTest, unitTest);

      await expect(
        tradeCoinTokenizer.connect(tokenizer2).burnToken(0)
      ).to.be.revertedWith("Not the owner");

      const [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      expect(commodityTest).to.equal(commodity0);
      expect(amountTest).to.equal(amount0.toNumber());
      expect(unitTest).to.equal(unit0);
    });
  });

  describe("Testing the interface function", function () {
    it("Does the contract support the interface ITradeCoinTokenizer", async function () {
      expect(await tradeCoinTokenizer.supportsInterface("0x017eb193")).to.be
        .true;
    });
  });
});
