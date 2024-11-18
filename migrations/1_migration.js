const Ticket = artifacts.require("Ticket");
const Supporter = artifacts.require("Supporter");
const Concert = artifacts.require("Concert");

module.exports = async (deployer) => {
  // Deploy the Ticket contract
  await deployer.deploy(Ticket);
  const ticketInstance = await Ticket.deployed();

  // Deploy the Supporter contract
  await deployer.deploy(Supporter);
  const supporterInstance = await Supporter.deployed();

  await deployer.deploy(
    Concert,
    ticketInstance.address,
    supporterInstance.address
  );
};
