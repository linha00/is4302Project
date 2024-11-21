const _deploy_contracts = require("../migrations/1_migration.js");
const truffleAssert = require("truffle-assertions");
const assert = require("assert");

var Collectible = artifacts.require("../contracts/Collectible");
var Market = artifacts.require("../contracts/Market");
var ComposableCollectible = artifacts.require(
  "../contracts/ComposableCollectible"
);

contract("Collectible", async (accounts) => {
  before(async () => {
    collectibleInstance = await Collectible.deployed();
    marketInstance = await Market.deployed();
    ComposableCollectibleInstance = await ComposableCollectible.deployed();
  });
  it("Mint Collectible that can be used to form Composable Collectible", async () => {
    await collectibleInstance.mint(accounts[1], "TokenURI", accounts[2], true, {
      from: accounts[0],
    });
    const tokenId = 1;
    const owner = await collectibleInstance.ownerOf.call(tokenId);
    assert.equal(owner, accounts[1]);
  });
  it("Mint Composable Collectible", async () => {
    await ComposableCollectibleInstance.mint(accounts[1], accounts[2], {
      from: accounts[0],
    });
    const tokenId = 1;
    const owner = await ComposableCollectibleInstance.ownerOf.call(tokenId);
    assert.equal(owner, accounts[1]);
  });
  it("Transfer Collectible to Composable Collectible", async () => {
    await collectibleInstance.transferFrom(
      accounts[1],
      ComposableCollectibleInstance.address,
      1,
      { from: accounts[1] }
    );
    const owner = await collectibleInstance.ownerOf.call(1);
    assert.equal(owner, ComposableCollectibleInstance.address);

    //Set Collectible Contract in Composable Collectible Contract
    await ComposableCollectibleInstance.setCollectibleContract(
      collectibleInstance.address,
      { from: accounts[0] }
    );

    await ComposableCollectibleInstance.transferToParent(1, 1, {
      from: accounts[1],
    });
    const parent = await ComposableCollectibleInstance.parentOf.call(1);
    assert.equal(parent, 1);
  });
  it("List Part of Composable Collectible", async () => {
    //Would Fail
    await truffleAssert.reverts(
      marketInstance.createListing(1, "5000000000000000000", 1, {
        from: accounts[1],
      }),
      "Caller is not the owner of the collectible"
    );
  });
  it("Transfer more Collectible to Composable Collectible", async () => {
    await collectibleInstance.mint(accounts[5], "TokenURI", accounts[2], true, {
      from: accounts[0],
    });
    const tokenId = 2;
    const owner = await collectibleInstance.ownerOf.call(tokenId);
    assert.equal(owner, accounts[5]);

    await collectibleInstance.transferFrom(
      accounts[5],
      ComposableCollectibleInstance.address,
      2,
      { from: accounts[5] }
    );
    const newOwner = await collectibleInstance.ownerOf.call(1);
    assert.equal(newOwner, ComposableCollectibleInstance.address);

    await ComposableCollectibleInstance.transferToParent(2, 1, {
      from: accounts[5],
    });
    const parent = await ComposableCollectibleInstance.parentOf.call(2);
    assert.equal(parent, 1);
  });
  it("Transfer Collectible out of Composable Collectible", async () => {
    await collectibleInstance.transferFrom(
      ComposableCollectibleInstance.address,
      accounts[5],
      2,
      { from: accounts[0] }
    );
    const owner = await collectibleInstance.ownerOf.call(2);
    assert.equal(owner, accounts[5]);
    await ComposableCollectibleInstance.transferFromParent(2, {
      from: accounts[1],
    });
  });
  it("Test Listing of Collectibles in Market", async () => {
    await marketInstance.createListing(2, "5000000000000000000", 1, {
      from: accounts[5],
    });
    let price = await marketInstance.getListingPrice.call(0);
    assert.equal(price, "5000000000000000000");
  });
});
