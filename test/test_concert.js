const _deploy_contracts = require("../migrations/1_migration.js");
const truffleAssert = require("truffle-assertions");
const assert = require("assert");

var Concert = artifacts.require("../contracts/Concert");
var Ticket = artifacts.require("../contracts/Ticket");
var Supporter = artifacts.require("../contracts/Supporter");

contract("Concert", async (accounts) => {
  before(async () => {
    ticketInstance = await Ticket.deployed();
    supporterInstance = await Supporter.deployed();
    concertInstance = await Concert.deployed();
  });

  describe("Test Cases for checkOrganiserAddressApproval:", async () => {
    it("Organiser Address is not Approved", async () => {
      assert.equal(
        await concertInstance.checkOrganiserAddressApproval(accounts[0]),
        false
      );
    });
    it("Organiser Address is Approved", async () => {
      await concertInstance.approveOrganiser(accounts[0]);
      assert.equal(
        await concertInstance.checkOrganiserAddressApproval(accounts[0]),
        true
      );
    });
  });

  describe("Test Cases for checkVenueAddressApproval:", async () => {
    it("Venue Address is not Approved", async () => {
      assert.equal(
        await concertInstance.checkVenueAddressApproval(accounts[1]),
        false
      );
    });
    it("Venue Address is Approved", async () => {
      await concertInstance.approveVenue(accounts[1]);
      assert.equal(
        await concertInstance.checkVenueAddressApproval(accounts[1]),
        true
      );
    });
  });

  describe("Test Cases for checkArtistAddressApproval:", async () => {
    it("Artist Address is not Approved", async () => {
      assert.equal(
        await concertInstance.checkArtistAddressApproval(accounts[2]),
        false
      );
    });
    it("Artist Address is Approved", async () => {
      await concertInstance.approveArtist(accounts[2]);
      assert.equal(
        await concertInstance.checkArtistAddressApproval(accounts[2]),
        true
      );
    });
  });

  describe("Test Cases for Create Concert:", async () => {
    it("Create Concert", async () => {
      const artist = accounts[2];
      const venue = accounts[1];
      const organiser = accounts[0];
      const artistPayoutPercentage = 40;
      const orgnaiserPayoutPercentage = 40;
      const venuePayoutPercentage = 10;
      const totalTickets = 100;
      const preSaleQuality = 0;
      const ticketInfoURI = "https://www.ticket.com";
      const preSaleTicketPrice = web3.utils.toWei("0.1", "ether");
      const ticketPrice = web3.utils.toWei("0.2", "ether");

      const tx = await concertInstance.createConcert(
        artist,
        venue,
        artistPayoutPercentage,
        orgnaiserPayoutPercentage,
        venuePayoutPercentage,
        totalTickets,
        preSaleQuality,
        ticketInfoURI,
        preSaleTicketPrice,
        ticketPrice,
        { from: organiser }
      );
      // Extract the concert ID from the transaction receipt
      const concertID = tx.logs[0].args.concertID.toNumber();

      truffleAssert.eventEmitted(tx, "ConcertStatus", (ev) => {
        return (
          ev.concertID == concertID && ev.concertState == 11 // OrganiserApproved
        );
      });
    });
  });
});
