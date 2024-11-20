const _deploy_contracts = require("../migrations/1_migration.js");
const truffleAssert = require("truffle-assertions");
const assert = require("assert");

var Ticket = artifacts.require("../contracts/Ticket");
var Collectible = artifacts.require("../contracts/Collectible");
var Market = artifacts.require("../contracts/Market");

contract("Market", async (accounts) => {
  before(async () => {
    ticketInstance = await Ticket.deployed();
    collectibleInstance = await Collectible.deployed();
    marketInstance = await Market.deployed();
  });

  //Test Cases for createListing
  describe("Test Cases for createListing(Tickets):", async () => {
    describe("Test Case 1: Ticket Listed  + Ticket Unlisted", async () => {
      const ticketId = 0;
      before(async () => {
        await ticketInstance.mint(
          accounts[1],
          1,
          "1000000000000000000",
          "TokenURI",
          accounts[2],
          { from: accounts[0] }
        );
      });
      it("General Ticket Listed and unlisted", async () => {
        await marketInstance.createListing(ticketId, "5000000000000000000", 0, {
          from: accounts[1],
        });
        let price = await marketInstance.getListingPrice.call(0);
        assert.equal(price, "5000000000000000000");
        const tokenId = await marketInstance.getTokenId.call(0);
        const owner = await ticketInstance.ownerOf.call(tokenId);
        const prevOwner = await ticketInstance.getPreviousOwner.call(tokenId);
        assert.equal(prevOwner, accounts[1]);
        assert.equal(owner, marketInstance.address);
        await marketInstance.unlist(0, { from: accounts[1] });
        const newOwner = await ticketInstance.ownerOf.call(tokenId);
        const newPrevOwner = await ticketInstance.getPreviousOwner.call(
          tokenId
        );
        assert.equal(newPrevOwner, marketInstance.address);
        assert.equal(newOwner, accounts[1]);

        const lsitingState = await marketInstance.getListingState.call(0);
        assert.equal(lsitingState, 1);
      });
    });
    describe("Test Case 2: Collectible Listed  + Collectible Unlisted", async () => {
      const collectibleId = 1;
      before(async () => {
        await collectibleInstance.mint(
          accounts[3],
          "TokenURI",
          accounts[2],
          false
        );
      });
      it("Collectible Listed and unlisted", async () => {
        await marketInstance.createListing(
          collectibleId,
          "1000000000000000000",
          1,
          {
            from: accounts[3],
          }
        );
        let price = await marketInstance.getListingPrice.call(1);
        assert.equal(price, "1000000000000000000");
        const tokenId = await marketInstance.getTokenId.call(1);
        const owner = await collectibleInstance.ownerOf.call(tokenId);
        const prevOwner = await collectibleInstance.getPreviousOwner.call(
          tokenId
        );
        assert.equal(prevOwner, accounts[3]);
        assert.equal(owner, marketInstance.address);
        await marketInstance.unlist(1, { from: accounts[3] });
        const newOwner = await collectibleInstance.ownerOf.call(tokenId);
        const newPrevOwner = await collectibleInstance.getPreviousOwner.call(
          tokenId
        );
        assert.equal(newPrevOwner, marketInstance.address);
        assert.equal(newOwner, accounts[3]);
      });
      it("Ticket Listed price not enough to pay for platform", async () => {
        await truffleAssert.reverts(
          marketInstance.createListing(collectibleId, 1, 1, {
            from: accounts[3],
          }),
          "Listing price must be greater than zero and cover platform and artist fees."
        );
      });
    });
  });

  //Test Cases for buyListing
  describe("Test Cases for buyListing(Tickets):", async () => {
    describe("Test Case 1: Buy Ticket", async () => {
      const ticketId = 1;
      before(async () => {
        await ticketInstance.mint(
          accounts[5],
          1,
          "70000000000000000",
          "TokenURI",
          accounts[2]
        );
      });
      it("Buy Ticket", async () => {
        await marketInstance.createListing(ticketId, "70000000000000000", 0, {
          from: accounts[5],
        });
        let price = await marketInstance.getListingPrice.call(2);
        assert.equal(price, "70000000000000000");
        const initialContractBalance = await web3.eth.getBalance(
          marketInstance.address
        );
        const initialOwnerBalance = await web3.eth.getBalance(accounts[5]);
        const artistInitialBalance = await web3.eth.getBalance(accounts[2]);
        const buyerInitialBalance = await web3.eth.getBalance(accounts[6]);
        await marketInstance.buy(2, {
          from: accounts[6],
          value: "80000000000000000",
        });
        const tokenId = await marketInstance.getTokenId.call(2);
        const owner = await ticketInstance.ownerOf.call(tokenId);
        const prevOwner = await ticketInstance.getPreviousOwner.call(tokenId);
        assert.equal(prevOwner, marketInstance.address);
        assert.equal(owner, accounts[6]);
        const finalOwnerBalance = await web3.eth.getBalance(accounts[5]);
        const artistFinalBalance = await web3.eth.getBalance(accounts[2]);
        const finalContractBalance = await web3.eth.getBalance(
          marketInstance.address
        );
        const buyerFinalBalance = await web3.eth.getBalance(accounts[6]);
        assert.equal(
          finalContractBalance - initialContractBalance,
          10000000000000000
        );
        assert.equal(
          finalOwnerBalance - initialOwnerBalance,
          50000000000000000
        );
        assert.equal(
          artistFinalBalance - artistInitialBalance,
          10000000000000000
        );
        assert.equal(
          buyerFinalBalance - buyerInitialBalance - 70000000000000000 <
            10000000000000000,
          true
        );

        const lsitingState = await marketInstance.getListingState.call(2);
        assert.equal(lsitingState, 2);
      });
      // it("Buy Ticket without enough gas", async () => {
      //   await marketInstance.createListing(ticketId, "5000000000000000000", 0, {
      //     from: accounts[5],
      //   });
      //   await truffleAssert.reverts(
      //     marketInstance.buyListing(ticketId, {
      //       from: accounts[6],
      //       value: "4000000000000000000",
      //     }),
      //     "Insufficient funds"
      //   );
      // });
    });
  });
});
