const { expect } = require("chai");
const { ethers } = require("hardhat");

let TradeCoin;
let tradeCoin;

let TradeCoinTokenizer;
let tradeCoinTokenizer;

let admin;
let owner;
let tokenizer;
let tHandler;
let iHandler;
let notApproved;
let accounts;

let address0;

let commodityState = {
  PendingConfirmation: 0,
  Confirmed: 1,
  PendingProcess: 2,
  Processing: 3,
  PendingTransport: 4,
  Transporting: 5,
  PendingStorage: 6,
  Stored: 7,
  EOL: 8,
};

beforeEach(async function () {
  TradeCoinTokenizer = await ethers.getContractFactory("TradeCoinTokenizerV2");
  tradeCoinTokenizer = await TradeCoinTokenizer.deploy();
  await tradeCoinTokenizer.deployed();

  TradeCoin = await ethers.getContractFactory("TradeCoinV4");
  tradeCoin = await TradeCoin.deploy(tradeCoinTokenizer.address);
  await tradeCoin.deployed();

  [admin, owner, tokenizer, tHandler, iHandler, notApproved, ...accounts] =
    await ethers.getSigners();

  address0 = "0x0000000000000000000000000000000000000000";

  await tradeCoinTokenizer.connect(tokenizer).mintToken("cashew", 10, "kg");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("cashew", 30, "kg");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("cashew", 55, "kg");

  await tradeCoinTokenizer.connect(tokenizer).mintToken("grain", 5, "bu");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("olive oil", 5, "l");
  await tradeCoinTokenizer.connect(tokenizer).mintToken("banana", 50, "lb");

  for (i = 0; i < 5; i++) {
    await tradeCoinTokenizer.connect(tokenizer).approve(tradeCoin.address, i);
  }

  await tradeCoin.connect(admin).addTokenizer(tokenizer.address);
  await tradeCoin.connect(admin).addTransformationHandler(tHandler.address);
  await tradeCoin.connect(admin).addInformationHandler(iHandler.address);

  await tradeCoin.connect(admin).addTransformationHandler(notApproved.address);
  await tradeCoin.connect(admin).addTransformationHandler(notApproved.address);

  await tradeCoin
    .connect(admin)
    .removeTransformationHandler(notApproved.address);
  await tradeCoin.connect(admin).removeInformationHandler(notApproved.address);

  await tradeCoin.connect(admin).addAdmin(notApproved.address);
  await tradeCoin.connect(admin).removeAdmin(notApproved.address);
});

describe("Testing the tradecoin contract", function () {
  describe("Testing if all the tokens are minted and the roles assigned", function () {
    it("The cashew tokens should be minted in the tokenizer contract", async function () {
      commodityTest = "cashew";
      unitTest = "kg";

      [commodity0, amount0, unit0] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(0);

      [commodity1, amount1, unit1] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(1);

      [commodity2, amount2, unit2] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(2);

      expect(commodityTest).to.equal(commodity0);
      expect(unitTest).to.equal(unit0);

      expect(commodityTest).to.equal(commodity1);
      expect(unitTest).to.equal(unit1);

      expect(commodityTest).to.equal(commodity2);
      expect(unitTest).to.equal(unit2);
    });

    it("The grain token should be minted in the tokenizer contract", async function () {
      commodityTest = "grain";
      amountTest = 5;
      unitTest = "bu";

      [commodity3, amount3, unit3] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(3);

      expect(commodityTest).to.equal(commodity3);
      expect(amountTest).to.equal(amount3.toNumber());
      expect(unitTest).to.equal(unit3);
    });

    it("The olive oil token should be minted in the tokenizer contract", async function () {
      commodityTest = "olive oil";
      amountTest = 5;
      unitTest = "l";

      [commodity4, amount4, unit4] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(4);

      expect(commodityTest).to.equal(commodity4);
      expect(amountTest).to.equal(amount4.toNumber());
      expect(unitTest).to.equal(unit4);
    });

    it("The banana token should be minted in the tokenizer contract", async function () {
      commodityTest = "banana";
      amountTest = 50;
      unitTest = "lb";

      [commodity5, amount5, unit5] = await tradeCoinTokenizer
        .connect(tokenizer)
        .tradeCoinToken(5);

      expect(commodityTest).to.equal(commodity5);
      expect(amountTest).to.equal(amount5.toNumber());
      expect(unitTest).to.equal(unit5);
    });

    it("The supply chain participants should have the appropriate role", async function () {
      await expect(tradeCoin.connect(owner).isTokenizer(tokenizer.address));
      await expect(
        tradeCoin.connect(owner).isInformationHandler(iHandler.address)
      );
      await expect(
        tradeCoin.connect(owner).isTransformationHandler(tHandler.address)
      );
    });
  });

  describe("Testing the three-party transaction", function () {
    it("Tokenizer should initialize the sale without a price", async function () {
      await expect(
        tradeCoin
          .connect(tokenizer)
          .initializeSale(owner.address, tHandler.address, 0, 0)
      )
        .to.emit(tradeCoin, "InitializeSale")
        .withArgs(0, tokenizer.address, owner.address, 0, true);

      [seller, newOwner, handler, isPaid, price] = await tradeCoin
        .connect(tokenizer)
        .commoditySaleQueue(0);

      expect(seller).to.be.equal(tokenizer.address);
      expect(newOwner).to.be.equal(owner.address);
      expect(handler).to.be.equal(tHandler.address);
      expect(price.toNumber()).to.be.equal(0);
      expect(isPaid);
      expect(await tradeCoinTokenizer.ownerOf(0)).to.be.equal(
        tradeCoin.address
      );
    });

    it("Should revert: pay for token when it has already been paid", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await expect(
        tradeCoin.connect(owner).paymentOfToken(0)
      ).to.be.revertedWith("Token is already paid for");
    });

    it("Should revert: handler initializes the sale", async function () {
      await expect(
        tradeCoin
          .connect(tHandler)
          .initializeSale(owner.address, tHandler.address, 0, 0)
      ).to.be.revertedWith("Restricted to Tokenizers and admin");
    });

    it("Should revert: wrong tokenizer initializes the sale", async function () {
      await tradeCoin.connect(admin).addTokenizer(notApproved.address);

      await expect(
        tradeCoin
          .connect(notApproved)
          .initializeSale(owner.address, tHandler.address, 0, 0)
      ).to.be.revertedWith("Not the owner");

      await tradeCoin.connect(admin).removeTokenizer(notApproved.address);
      await expect(
        tradeCoin.connect(notApproved).addTokenizer(notApproved.address)
      ).to.be.revertedWith("Restricted to admins");
    });

    it("Handler should mint the commodity", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 1000);

      await expect(tradeCoin.connect(owner).paymentOfToken(0, { value: 1000 }))
        .to.emit(tradeCoin, "PaymentOfToken")
        .withArgs(0, owner.address, 1000);

      await expect(tradeCoin.connect(tHandler).mintCommodity(0))
        .to.emit(tradeCoin, "MintCommodity")
        .withArgs(0, tHandler.address, 0, "cashew", 10, "kg");

      [amount, state, hashOfProperties, currentHandler] =
        await tradeCoin.tradeCoinCommodity(0);

      expect(amount.toNumber()).to.be.equal(10);
      expect(state).to.be.equal(1);
      expect(hashOfProperties).is.not.empty;
      expect(currentHandler).to.be.equal(tHandler.address);

      await expect(tradeCoinTokenizer.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );

      // [seller, newOwner, handler, price, isPaid] =
      //   await tradeCoin.commoditySaleQueue(0);

      // expect(seller).to.be.equal(address0);
      // expect(newOwner).to.be.equal(address0);
      // expect(handler).to.be.equal(address0);
      // expect(0).to.be.equal(0);
      // expect(!isPaid);
    });

    it("Should revert: wrong type handler mints the commodity", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await expect(
        tradeCoin.connect(iHandler).mintCommodity(0)
      ).to.be.revertedWith("Restricted to Transformation Handlers or admins");
    });

    it("Should revert: wrong transformation handler mints the commodity", async function () {
      await tradeCoin
        .connect(admin)
        .addTransformationHandler(notApproved.address);

      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await expect(
        tradeCoin.connect(notApproved).mintCommodity(0)
      ).to.be.revertedWith("Not a handler");
    });

    it("Tokenizer should initialize the sale with a price", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 1000);

      [seller, newOwner, handler, isPaid, price] = await tradeCoin
        .connect(tokenizer)
        .commoditySaleQueue(0);

      expect(seller).to.be.equal(tokenizer.address);
      expect(newOwner).to.be.equal(owner.address);
      expect(handler).to.be.equal(tHandler.address);
      expect(price.toNumber()).to.be.equal(1000);
      expect(!isPaid);
      expect(await tradeCoinTokenizer.ownerOf(0)).to.be.equal(
        tradeCoin.address
      );
    });

    it("Owner should pay for the token", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 1000);

      await tradeCoin.connect(owner).paymentOfToken(0, { value: 1000 });

      [seller, newOwner, handler, isPaid, price] =
        await tradeCoin.commoditySaleQueue(0);

      expect(seller).to.be.equal(tokenizer.address);
      expect(newOwner).to.be.equal(owner.address);
      expect(handler).to.be.equal(tHandler.address);
      expect(price.toNumber()).to.be.equal(1000);
      expect(isPaid);
      expect(await tradeCoinTokenizer.ownerOf(0)).to.equal(tradeCoin.address);
    });

    it("Should revert: Owner doesn't send enough Ether to pay for the token", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 1000);

      await expect(
        tradeCoin.connect(owner).paymentOfToken(0, { value: 500 })
      ).to.be.revertedWith("Not enough Ether");
    });

    it("Should revert: mint because token isn't paid for", async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 1000);

      await expect(
        tradeCoin.connect(tHandler).mintCommodity(0)
      ).to.be.revertedWith("Not payed for yet");
    });
  });

  describe("Testing the tranformations and information functions", function () {
    this.beforeEach(async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await tradeCoin.connect(tHandler).mintCommodity(0);

      await tradeCoin
        .connect(owner)
        .changeCurrentHandlerAndState(0, iHandler.address, 1);
    });

    it("Should add a transformation to the cashew token", async function () {
      await tradeCoin
        .connect(owner)
        .changeCurrentHandlerAndState(0, tHandler.address, 1);

      await expect(tradeCoin.connect(tHandler).addTransformation(0, "washing"))
        .to.emit(tradeCoin, "CommodityTransformation")
        .withArgs(0, tHandler.address, "washing");

      await tradeCoin.connect(tHandler).addTransformation(0, "cleanig");
      await tradeCoin.connect(tHandler).addTransformation(0, "salt");
      await tradeCoin.connect(tHandler).addTransformation(0, "A");
      await tradeCoin.connect(tHandler).addTransformation(0, "Lorem ipsum");

      [amount, , ,] = await tradeCoin.tradeCoinCommodity(0);

      expect(amount.toNumber()).to.be.equal(10);
    });

    it("Should add a transformation (washing) to the cashew token with a 1kg decrease", async function () {
      await tradeCoin
        .connect(owner)
        .changeCurrentHandlerAndState(0, tHandler.address, 1);

      await expect(
        tradeCoin.connect(tHandler).addTransformationDecrease(0, "washing", 1)
      )
        .to.emit(tradeCoin, "CommodityTransformationDecrease")
        .withArgs(0, tHandler.address, "washing", 1);

      [amount, , ,] = await tradeCoin.tradeCoinCommodity(0);

      await expect(amount.toNumber()).to.be.equal(9);
    });

    it("Should revert: add a transformation (washing) to the cashew token by wrong handler", async function () {
      await tradeCoin
        .connect(admin)
        .addTransformationHandler(notApproved.address);

      await expect(
        tradeCoin.connect(notApproved).addTransformation(0, "washing")
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a transformation (washing) to the cashew token with a 1kg decrease by wrong handler", async function () {
      await tradeCoin
        .connect(admin)
        .addTransformationHandler(notApproved.address);

      await expect(
        tradeCoin
          .connect(notApproved)
          .addTransformationDecrease(0, "washing", 1)
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should add information the cashew token", async function () {
      await tradeCoin.connect(iHandler).addInformationToCommodity(0, "T");
    });

    it("Should check the quality of the cashew token", async function () {
      await tradeCoin.connect(iHandler).checkQualityOfCommodity(0, "A");
    });

    it("Should confirm the location of the cashew token", async function () {
      await tradeCoin.connect(iHandler).confirmCommodityLocation(0, 10, 10, 10);
      await tradeCoin.connect(iHandler).confirmCommodityLocation(0, 1, 1, 1);
      await tradeCoin
        .connect(iHandler)
        .confirmCommodityLocation(
          0,
          1000000099999999,
          1003450000000000,
          1000000099999999
        );
    });

    it("Should revert: add a information by wrong ihandler to the cashew token", async function () {
      await tradeCoin.connect(admin).addInformationHandler(notApproved.address);

      await expect(
        tradeCoin
          .connect(notApproved)
          .addInformationToCommodity(0, "Lorem ipsum")
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a quality check by wrong ihandler to the cashew token", async function () {
      await tradeCoin.connect(admin).addInformationHandler(notApproved.address);

      await expect(
        tradeCoin
          .connect(notApproved)
          .checkQualityOfCommodity(0, "Bad really bad")
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a confirm location by wrong ihandler to the cashew token", async function () {
      await tradeCoin.connect(admin).addInformationHandler(notApproved.address);

      await expect(
        tradeCoin.connect(notApproved).confirmCommodityLocation(0, 10, 10, 10)
      ).to.be.revertedWith("Caller is not the current handler");
    });

    it("Should revert: add a information by wrong user to the cashew token", async function () {
      await expect(
        tradeCoin
          .connect(notApproved)
          .addInformationToCommodity(0, "foobar, hello world, test test test")
      ).to.be.revertedWith("Restricted to Information Handlers or admins");
    });

    it("Should revert: add a quality check by wrong user to the cashew token", async function () {
      await expect(
        tradeCoin
          .connect(notApproved)
          .checkQualityOfCommodity(
            0,
            "This product is amazing, very good quality"
          )
      ).to.be.revertedWith("Restricted to Information Handlers or admins");
    });

    it("Should revert: add a confirm location by wrong user to the cashew token", async function () {
      await expect(
        tradeCoin.connect(notApproved).confirmCommodityLocation(0, 10, 10, 10)
      ).to.be.revertedWith("Restricted to Information Handlers or admins");
    });
  });

  describe("Testing the change handler and state function", function () {
    this.beforeEach(async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await tradeCoin.connect(tHandler).mintCommodity(0);
    });
    it("Should be called by the owner of the token", async function () {
      await expect(
        tradeCoin
          .connect(owner)
          .changeCurrentHandlerAndState(0, iHandler.address, 5)
      )
        .to.emit(tradeCoin, "ChangeStateAndHandler")
        .withArgs(0, owner.address, iHandler.address, 5);

      [, state, , currentHandler] = await tradeCoin.tradeCoinCommodity(0);

      expect(state).to.be.equal(5);
      expect(currentHandler).to.be.equal(iHandler.address);
    });

    it("Should revert: called by the wrong owner of the token", async function () {
      await expect(
        tradeCoin
          .connect(notApproved)
          .changeCurrentHandlerAndState(0, tHandler.address, 5)
      ).to.be.revertedWith("Not the owner");
    });
  });

  describe("Testing the burn function", function () {
    this.beforeEach(async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await tradeCoin.connect(tHandler).mintCommodity(0);
    });

    it("Owner burning the token", async function () {
      await expect(tradeCoin.connect(owner).burnCommodity(0))
        .to.emit(tradeCoin, "CommodityOutOfChain")
        .withArgs(0, owner.address);

      await expect(tradeCoin.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });

    it("Should revert: wrong owner burning the token", async function () {
      await expect(
        tradeCoin.connect(notApproved).burnCommodity(0)
      ).to.be.revertedWith("Not the owner");
    });
  });

  describe("Testing the supports interface function", function () {
    it("Should support the ITradeCoin interface", async function () {
      expect(await tradeCoin.supportsInterface("0xe27c8709")).to.be.true;
    });
  });

  describe("Testing the change batching function", function () {
    this.beforeEach(async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 0, 0);

      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 1, 0);

      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 2, 0);

      await tradeCoin.connect(tHandler).mintCommodity(0);
      await tradeCoin.connect(tHandler).mintCommodity(1);
      await tradeCoin.connect(tHandler).mintCommodity(2);
    });

    it("Testing the batching function for 3 tokens", async function () {
      await expect(tradeCoin.connect(owner).batchCommodities([0, 1, 2]))
        .to.emit(tradeCoin, "BatchCommodities")
        .withArgs(3, owner.address, [0, 1, 2]);

      [amount, state, hashOfProperties, currentHandler] =
        await tradeCoin.tradeCoinCommodity(3);

      expect(amount.toNumber()).to.be.equal(10 + 30 + 55);
      expect(state).to.be.equal(1);
      expect(currentHandler).to.be.equal(tHandler.address);

      await expect(tradeCoin.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(tradeCoin.ownerOf(1)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(tradeCoin.ownerOf(2)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });

    it("Testing the batching function for 2 tokens", async function () {
      await tradeCoin.connect(owner).batchCommodities([0, 1]);

      [amount, state, hashOfProperties, currentHandler] =
        await tradeCoin.tradeCoinCommodity(3);

      expect(amount.toNumber()).to.be.equal(10 + 30);
      expect(state).to.be.equal(1);
      expect(currentHandler).to.be.equal(tHandler.address);

      await expect(tradeCoin.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(tradeCoin.ownerOf(1)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });

    it("Should revert: because length of the array is 1 in the batching function", async function () {
      await expect(
        tradeCoin.connect(owner).batchCommodities([0])
      ).to.be.revertedWith("Length of array must be greater than 1");
    });

    it("Should revert: wrong owner calling the batching function", async function () {
      await expect(
        tradeCoin.connect(notApproved).batchCommodities([0, 1, 2])
      ).to.be.revertedWith("Not the owner");
    });

    it("Should revert: wrong owner calling the batching function", async function () {
      await tradeCoin
        .connect(owner)
        .transferFrom(owner.address, notApproved.address, 0);

      await expect(
        tradeCoin.connect(notApproved).batchCommodities([0, 1, 2])
      ).to.be.revertedWith("Not the owner");
    });

    it("Should revert: because properties are not the same in the batching function", async function () {
      await tradeCoin.connect(tHandler).addTransformation(0, "washing");

      await expect(
        tradeCoin.connect(owner).batchCommodities([0, 1, 2])
      ).to.be.revertedWith("Properties don't match");
    });
  });

  describe("Testing the change split function", function () {
    this.beforeEach(async function () {
      await tradeCoin
        .connect(tokenizer)
        .initializeSale(owner.address, tHandler.address, 1, 0);

      await tradeCoin.connect(tHandler).mintCommodity(1);
    });

    it("split token into three tokens of 10kg each", async function () {
      await expect(tradeCoin.connect(owner).splitCommodity(0, [10, 10, 10]))
        .to.emit(tradeCoin, "SplitCommodity")
        .withArgs(0, owner.address, [1, 2, 3]);

      [amount1, , , currentHandler1] = await tradeCoin.tradeCoinCommodity(1);
      [amount2, , , currentHandler2] = await tradeCoin.tradeCoinCommodity(2);
      [amount3, , , currentHandler3] = await tradeCoin.tradeCoinCommodity(3);

      await expect(amount1.toNumber()).to.be.equal(10);
      await expect(amount2.toNumber()).to.be.equal(10);
      await expect(amount3.toNumber()).to.be.equal(10);

      await expect(currentHandler1).to.be.equal(tHandler.address);
      await expect(currentHandler2).to.be.equal(tHandler.address);
      await expect(currentHandler3).to.be.equal(tHandler.address);
    });

    it("split token into four tokens of 2x10kg and 2x5kg", async function () {
      await tradeCoin.connect(owner).splitCommodity(0, [10, 10, 5, 5]);

      [amount1, , , currentHandler1] = await tradeCoin.tradeCoinCommodity(1);
      [amount2, , , currentHandler2] = await tradeCoin.tradeCoinCommodity(2);
      [amount3, , , currentHandler3] = await tradeCoin.tradeCoinCommodity(3);
      [amount4, , , currentHandler3] = await tradeCoin.tradeCoinCommodity(4);

      expect(amount1.toNumber()).to.be.equal(10);
      expect(amount2.toNumber()).to.be.equal(10);
      expect(amount3.toNumber()).to.be.equal(5);
      expect(amount3.toNumber()).to.be.equal(5);

      expect(currentHandler1).to.be.equal(tHandler.address);
      expect(currentHandler2).to.be.equal(tHandler.address);
      expect(currentHandler3).to.be.equal(tHandler.address);
    });

    it("Should revert: wrong owner calling split token", async function () {
      await expect(
        tradeCoin.connect(notApproved).splitCommodity(0, [10, 10, 10])
      ).to.be.revertedWith("Not the owner");
    });

    it("Should revert: array length smaller than 1 when calling split token", async function () {
      await expect(
        tradeCoin.connect(owner).splitCommodity(0, [10])
      ).to.be.revertedWith("Length of array must be bigger than 1");
    });

    it("Should revert: the partitions don't add up", async function () {
      await expect(
        tradeCoin.connect(owner).splitCommodity(0, [10, 10, 5])
      ).to.be.revertedWith("The amounts don't add up");
    });

    it("Should revert: a partition is zero", async function () {
      await expect(
        tradeCoin.connect(owner).splitCommodity(0, [0, 10, 5])
      ).to.be.revertedWith("Partition can't be 0");
    });
  });
});
