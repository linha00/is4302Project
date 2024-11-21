const Ticket = artifacts.require("Ticket");
const Supporter = artifacts.require("Supporter");
const Concert = artifacts.require("Concert");
const Collectible = artifacts.require("Collectible");
const Market = artifacts.require("Market");
const ComposableCollectible = artifacts.require("ComposableCollectible");

module.exports = async (deployer) => {
  // Deploy the Ticket contract
  await deployer.deploy(Ticket);
  const ticketInstance = await Ticket.deployed();

  // Deploy the Supporter contract
  await deployer.deploy(Supporter);
  const supporterInstance = await Supporter.deployed();

  // Deploy the Concert contract
  await deployer.deploy(
    Concert,
    ticketInstance.address,
    supporterInstance.address
  );

  // Deploy the Collectible contract
  await deployer.deploy(Collectible);
  const collectibleInstance = await Collectible.deployed();

  // Deploy the Market contract
  await deployer.deploy(
    Market,
    collectibleInstance.address,
    ticketInstance.address
  );

  await deployer.deploy(ComposableCollectible);
  const composableCollectibleInstance = await ComposableCollectible.deployed();
};
