const { expect } = require("chai");
const { ethers } = require("hardhat");

let TradeCoinComposition;
let tradeCoinComposition;

let TradeCoin;
let tradeCoin;

let TradeCoinTokenizer;
let tradeCoinTokenizer;

let admin;
let owner;
let tokenizer;
let tHandler;
let iHandler;
let attacker;
let accounts;

let address0;

beforeEach(async function () {
  TradeCoinTokenizer = await ethers.getContractFactory("TradeCoinTokenizerV2");
  tradeCoinTokenizer = await TradeCoinTokenizer.deploy();
  await tradeCoinTokenizer.deployed();

  TradeCoin = await ethers.getContractFactory("TradeCoinV4");
  tradeCoin = await TradeCoin.deploy(tradeCoinTokenizer.address);
  await tradeCoin.deployed();

  TradeCoinComposition = await ethers.getContractFactory(
    "TradeCoinCompositionV2"
  );
  tradeCoinComposition = await TradeCoinComposition.deploy(tradeCoin.address);
  await tradeCoinComposition.deployed();

  [admin, owner, tokenizer, tHandler, iHandler, attacker, ...accounts] =
    await ethers.getSigners();

  address0 = "0x0000000000000000000000000000000000000000";

  await tradeCoinTokenizer.connect(tokenizer).mintToken("cashew", 10, "kg");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("cashew", 30, "kg");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("cashew", 55, "kg");

  await tradeCoinTokenizer.connect(tokenizer).mintToken("grain", 5, "bu");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("olive oil", 5, "l");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("banana", 50, "lb");

  await tradeCoin.connect(admin).addTokenizer(tokenizer.address);
  await tradeCoin.connect(admin).addTransformationHandler(tHandler.address);
  await tradeCoin.connect(admin).addInformationHandler(iHandler.address);

  await tradeCoinComposition.connect(admin).addTokenizer(tokenizer.address);
  await tradeCoinComposition
    .connect(admin)
    .addTransformationHandler(tHandler.address);
  await tradeCoinComposition
    .connect(admin)
    .addInformationHandler(iHandler.address);

  for (i = 0; i < 5; i++) {
    await tradeCoinTokenizer.connect(tokenizer).approve(tradeCoin.address, i);

    await tradeCoin
      .connect(tokenizer)
      .initializeSale(owner.address, tHandler.address, i, 1000);

    await tradeCoin.connect(owner).paymentOfToken(i, { value: 1000 });

    await tradeCoin.connect(tHandler).mintCommodity(i);

    await tradeCoin.connect(owner).approve(tradeCoinComposition.address, i);

    await tradeCoin
      .connect(owner)
      .changeCurrentHandlerAndState(i, tHandler.address, 7);
  }
});

describe("Test the composition contract", function () {
  describe("Testing the create composition function", function () {
    it("Create a composition of two cashew tokens", async function () {
      await expect(
        tradeCoinComposition
          .connect(owner)
          .createComposition("cashew mix", [0, 1], tHandler.address)
      )
        .to.emit(tradeCoinComposition, "MintComposition")
        .withArgs(0, owner.address, [0, 1], "cashew mix", 40);

      [amountCompo, , handler] =
        await tradeCoinComposition.tradeCoinComposition(0);
      expect(amountCompo.toNumber()).to.equal(40);
      expect(handler).to.equal(tHandler.address);
    });

    it("Should revert: create a composition of one cashew token", async function () {
      await expect(
        tradeCoinComposition
          .connect(owner)
          .createComposition("cashew mix", [0], tHandler.address)
      ).to.be.revertedWith("Composition must be more than 2 tokens");
    });

    it("Should revert: create a composition of two cashew token by the wrong owner", async function () {
      await expect(
        tradeCoinComposition
          .connect(attacker)
          .createComposition("cashew mix", [0, 1], tHandler.address)
      ).to.be.revertedWith("ERC721: transfer from incorrect owner");
    });

    it("Should revert: create a composition of two cashew tokens with the wrong state", async function () {
      await tradeCoin
        .connect(owner)
        .changeCurrentHandlerAndState(1, tHandler.address, 1);

      await expect(
        tradeCoinComposition
          .connect(owner)
          .createComposition("cashew mix", [0, 1], tHandler.address)
      ).to.be.revertedWith("Commodity must be stored");
    });
  });

  describe("Testing the append commodity to composition function", function () {
    this.beforeEach(async function () {
      await tradeCoinComposition
        .connect(owner)
        .createComposition("cashew mix", [0, 1], tHandler.address);
    });
    it("Append a token to the composition", async function () {
      await tradeCoinComposition
        .connect(owner)
        .appendCommodityToComposition(0, 2);

      [amountCompo, ,] = await tradeCoinComposition.tradeCoinComposition(0);
      expect(amountCompo.toNumber()).to.equal(95);

      [id0, id1, id2] = await tradeCoinComposition.getIdsOfCommodities(0);
      expect(id0.toNumber()).to.equal(0);
      expect(id1.toNumber()).to.equal(1);
      expect(id2.toNumber()).to.equal(2);
    });

    it("Should revert: append a token to the composition by wrong owner", async function () {
      await expect(
        tradeCoinComposition
          .connect(attacker)
          .appendCommodityToComposition(0, 2)
      ).to.be.revertedWith("Not the owner");

      [id0, id1] = await tradeCoinComposition.getIdsOfCommodities(0);
      expect(id0.toNumber()).to.equal(0);
      expect(id1.toNumber()).to.equal(1);
    });
  });

  describe("Testing the remove commodity from composition function", function () {
    this.beforeEach(async function () {
      await tradeCoinComposition
        .connect(owner)
        .createComposition("cashew mix", [0, 1, 2, 3], tHandler.address);
    });

    it("Call the remove commodity from composition function", async function () {
      await tradeCoinComposition
        .connect(owner)
        .removeCommodityFromComposition(0, 0);

      [amountCompo, ,] = await tradeCoinComposition.tradeCoinComposition(0);
      expect(amountCompo.toNumber()).to.equal(90);

      [id0, id1, id2] = await tradeCoinComposition.getIdsOfCommodities(0);
      expect(id0.toNumber()).to.equal(3);
      expect(id1.toNumber()).to.equal(1);
      expect(id2.toNumber()).to.equal(2);
    });

    it("Should revert: remove a token from the composition by of length 2", async function () {
      await tradeCoinComposition
        .connect(owner)
        .removeCommodityFromComposition(0, 0);

      await tradeCoinComposition
        .connect(owner)
        .removeCommodityFromComposition(0, 0);

      await expect(
        tradeCoinComposition.connect(owner).removeCommodityFromComposition(0, 1)
      ).to.be.revertedWith("Must contain at least 2 tokens");
    });

    it("Should revert: remove a token from the composition by wrong owner", async function () {
      await expect(
        tradeCoinComposition
          .connect(attacker)
          .removeCommodityFromComposition(0, 1)
      ).to.be.revertedWith("Not the owner");
    });

    it("Should revert: remove an index that is out of range from the composition", async function () {
      await expect(
        tradeCoinComposition
          .connect(owner)
          .removeCommodityFromComposition(0, 100)
      ).to.be.revertedWith("Index not in range");

      [id0, id1, id2, id3] = await tradeCoinComposition.getIdsOfCommodities(0);
      expect(id0.toNumber()).to.equal(0);
      expect(id1.toNumber()).to.equal(1);
      expect(id2.toNumber()).to.equal(2);
      expect(id3.toNumber()).to.equal(3);
    });
  });

  describe("Testing the decomposition function", function () {
    this.beforeEach(async function () {
      await tradeCoinComposition
        .connect(owner)
        .createComposition("cashew mix", [0, 1, 2, 3], tHandler.address);
    });

    it("Call the decomposition function", async function () {
      await tradeCoinComposition.connect(owner).decomposition(0);

      await expect(tradeCoinComposition.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );

      expect(await tradeCoin.ownerOf(0)).to.equal(owner.address);
      expect(await tradeCoin.ownerOf(1)).to.equal(owner.address);
      expect(await tradeCoin.ownerOf(2)).to.equal(owner.address);
      expect(await tradeCoin.ownerOf(3)).to.equal(owner.address);
    });

    it("Should revert: Call the decomposition function by the wrong owner", async function () {
      await expect(
        tradeCoinComposition.connect(attacker).decomposition(0)
      ).to.be.revertedWith("Not the owner");
    });
  });

  describe("Testing the transformation and information functions", function () {
    this.beforeEach(async function () {
      await tradeCoinComposition
        .connect(owner)
        .createComposition("cashew mix", [0, 1, 3], tHandler.address);
    });

    it("Add a transformation", async function () {
      await tradeCoinComposition
        .connect(tHandler)
        .addTransformation(0, "salting");
    });

    it("Add a transformation with a 1kg decrease", async function () {
      await tradeCoinComposition
        .connect(tHandler)
        .addTransformationDecrease(0, "salting", 1);
      [amountCompo, ,] = await tradeCoinComposition.tradeCoinComposition(0);
      expect(amountCompo.toNumber()).to.equal(44);
    });

    it("Add information to the composition", async function () {
      await tradeCoinComposition.changeStateAndHandler(0, iHandler.address, 1);
      await tradeCoinComposition
        .connect(iHandler)
        .addInformationToComposition(0, "foobar");

      await tradeCoinComposition
        .connect(iHandler)
        .addInformationToComposition(0, "Lorem ipsum, Hello world");
    });

    it("Add quality check the composition", async function () {
      await tradeCoinComposition.changeStateAndHandler(0, iHandler.address, 1);
      await tradeCoinComposition
        .connect(iHandler)
        .checkQualityOfComposition(0, "foobar");

      await tradeCoinComposition
        .connect(iHandler)
        .checkQualityOfComposition(0, "Lorem ipsum, Hello world");
    });

    it("Confirm location of the composition", async function () {
      await tradeCoinComposition.changeStateAndHandler(0, iHandler.address, 1);
      await tradeCoinComposition
        .connect(iHandler)
        .checkQualityOfComposition(0, "foobar");

      await tradeCoinComposition
        .connect(iHandler)
        .confirmCompositionLocation(0, 10, 10, 10);

      await tradeCoinComposition
        .connect(iHandler)
        .confirmCompositionLocation(0, 100939032923, 1000000, 6961);
    });

    it("Should revert: add a transformation (washing) to the composition by wrong handler", async function () {
      await tradeCoinComposition
        .connect(admin)
        .addTransformationHandler(attacker.address);

      await expect(
        tradeCoinComposition.connect(attacker).addTransformation(0, "washing")
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a transformation (washing) to the composition by wrong type of handler", async function () {
      await tradeCoinComposition
        .connect(admin)
        .addInformationHandler(attacker.address);

      await expect(
        tradeCoinComposition.connect(attacker).addTransformation(0, "washing")
      ).to.be.revertedWith("Restricted to Transformation Handlers or admins");
    });

    it("Should revert: add a transformation (washing) to the composition with a 1kg decrease by wrong handler", async function () {
      await tradeCoinComposition
        .connect(admin)
        .addTransformationHandler(attacker.address);

      await expect(
        tradeCoinComposition
          .connect(attacker)
          .addTransformationDecrease(0, "washing", 1)
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a information by wrong ihandler to the composition", async function () {
      await tradeCoinComposition
        .connect(admin)
        .addInformationHandler(attacker.address);

      await expect(
        tradeCoinComposition
          .connect(attacker)
          .addInformationToComposition(0, "Test")
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a quality check by wrong ihandler to the composition", async function () {
      await tradeCoinComposition
        .connect(admin)
        .addInformationHandler(attacker.address);

      await expect(
        tradeCoinComposition
          .connect(attacker)
          .checkQualityOfComposition(0, "Good")
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a confirm location by wrong ihandler to the composition", async function () {
      await tradeCoinComposition
        .connect(admin)
        .addInformationHandler(attacker.address);

      await expect(
        tradeCoinComposition
          .connect(attacker)
          .confirmCompositionLocation(0, 10, 10, 10)
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a information by wrong user to the composition", async function () {
      await expect(
        tradeCoinComposition
          .connect(attacker)
          .addInformationToComposition(0, "Test")
      ).to.be.revertedWith("Restricted to Information Handlers or admins");
    });

    it("Should revert: add a quality check by wrong user to the composition", async function () {
      await expect(
        tradeCoinComposition
          .connect(attacker)
          .checkQualityOfComposition(0, "Good")
      ).to.be.revertedWith("Restricted to Information Handlers or admins");
    });

    it("Should revert: add a confirm location by wrong user to the composition", async function () {
      await expect(
        tradeCoinComposition
          .connect(attacker)
          .confirmCompositionLocation(0, 10, 10, 10)
      ).to.be.revertedWith("Restricted to Information Handlers or admins");
    });
  });

  describe("Testing the burn composition function", function () {
    this.beforeEach(async function () {
      await tradeCoinComposition
        .connect(owner)
        .createComposition("cashew mix", [0, 1, 2, 3], tHandler.address);
    });

    it("Call the decomposition function", async function () {
      await tradeCoinComposition.connect(owner).burnComposition(0);

      await expect(tradeCoinComposition.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );

      await expect(tradeCoin.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(tradeCoin.ownerOf(1)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(tradeCoin.ownerOf(2)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(tradeCoin.ownerOf(3)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });

    it("Should revert: Call the decomposition function by wrong owner", async function () {
      await expect(
        tradeCoinComposition.connect(attacker).burnComposition(0)
      ).to.be.revertedWith("Not the owner");
    });
  });

  describe("Testing support interface and get ids of commodities functions", function () {
    this.beforeEach(async function () {
      await tradeCoinComposition
        .connect(owner)
        .createComposition("cashew mix", [0, 1, 3], tHandler.address);
    });

    it("supportsInterface function", async function () {
      expect(await !tradeCoinComposition.supportsInterface("0xffffffff"));
    });

    it("Should support the ITradeCoin interface", async function () {
      expect(await tradeCoinComposition.supportsInterface("0x1c10033b")).to.be
        .true;
    });

    it("getIdsOfCommoditiesfunction", async function () {
      [id0, id1, id2] = await tradeCoinComposition.getIdsOfCommodities("0");
      expect(id0.toNumber()).to.equal(0);
      expect(id1.toNumber()).to.equal(1);
      expect(id2.toNumber()).to.equal(3);
    });
  });
});
