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
        await concertInstance.checkOrganiserAddressApproval(accounts[8]),
        false
      );
    });
    it("Organiser Address is Approved", async () => {
      await concertInstance.approveOrganiser(accounts[8]);
      assert.equal(
        await concertInstance.checkOrganiserAddressApproval(accounts[8]),
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
      const organiser = accounts[8];
      const artistPayoutPercentage = 40;
      const orgnaiserPayoutPercentage = 40;
      const venuePayoutPercentage = 10;
      const totalTickets = 2;
      const preSaleQuality = 1;
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

  describe("Test Cases for Buying Tickets", async () => {
    it("Buy Ticket", async () => {
      //Venue Approvals
      await concertInstance.updateVenueStateApproval(1, { from: accounts[1] });
      const concertState = await concertInstance.getConcertState(1);
      assert.equal(concertState, 7); // Pending Artist Approval

      //Artist Approvals
      await concertInstance.updateArtistStateApproval(1, { from: accounts[2] });
      const concertState1 = await concertInstance.getConcertState(1);
      assert.equal(concertState1, 0); // Pre Sale

      //Give Ticket Minting Approval
      await ticketInstance.setApprovedMinter(concertInstance.address);
      //Give Supporter Minting Approval
      await supporterInstance.setApprovedMinter(concertInstance.address);

      //Contract Balance Before Buying Ticket
      const contractBalanceBefore = await web3.eth.getBalance(
        concertInstance.address
      );

      //Buy Ticket
      await concertInstance.buyTicket(1, "ipfs://Test", "ipfs://Test", {
        from: accounts[5],
        value: "200000000000000000",
      });
      const ticketOwner = await ticketInstance.ownerOf(0);
      assert.equal(ticketOwner, accounts[5]);
      const supporterOwner = await supporterInstance.ownerOf(0);
      assert.equal(supporterOwner, accounts[5]);

      //Get State of Concert
      const concertState2 = await concertInstance.getConcertState(1);
      assert.equal(concertState2, 2); // General Sale

      //Check Contract Balance After Buying Ticket
      const contractBalanceAfter = await web3.eth.getBalance(
        concertInstance.address
      );
      assert.equal(
        contractBalanceAfter - contractBalanceBefore,
        web3.utils.toWei("0.1", "ether")
      );

      //Buy Ticket
      await concertInstance.buyTicket(1, "ipfs://Test", "ipfs://Test", {
        from: accounts[6],
        value: "200000000000000000",
      });
      const ticketOwner1 = await ticketInstance.ownerOf(1);
      assert.equal(ticketOwner1, accounts[6]);

      //Get State of Concert
      const concertState3 = await concertInstance.getConcertState(1);
      assert.equal(concertState3, 3); // Sold Out

      //Check Contract Balance After Buying Ticket
      const contractBalanceAfter2 = await web3.eth.getBalance(
        concertInstance.address
      );
      assert.equal(
        contractBalanceAfter2 - contractBalanceAfter,
        web3.utils.toWei("0.2", "ether")
      );

      //Buy Ticket(Sold Out)
      await truffleAssert.reverts(
        concertInstance.buyTicket(1, "ipfs://Test", "ipfs://Test", {
          from: accounts[7],
          value: "200000000000000000",
        }),
        "Tickets are not on sale now"
      );

      //Organiser Update Concert State
      await concertInstance.organiserUpdateState(1, 12, { from: accounts[8] });
      const concertState4 = await concertInstance.getConcertState(1);
      assert.equal(concertState4, 12); // Live

      //Get Artist Balance
      const artistBalance = await web3.eth.getBalance(accounts[2]);
      const venueBalance = await web3.eth.getBalance(accounts[1]);
      const organiserBalance = await web3.eth.getBalance(accounts[8]);

      // //Trigger Payout
      await concertInstance.triggerPayout(1, { from: accounts[0] });

      //Get Artist Balance
      const artistBalance1 = await web3.eth.getBalance(accounts[2]);
      assert.equal(artistBalance1 - artistBalance + "", "120000000000000000");

      // //Get Venue Balance
      const venueBalance1 = await web3.eth.getBalance(accounts[1]);
      assert.equal(
        venueBalance1 - venueBalance,
        web3.utils.toWei("0.03", "ether")
      );

      // //Get Organiser Balance
      const organiserBalance1 = await web3.eth.getBalance(accounts[8]);
      assert.equal(
        organiserBalance1 - organiserBalance + "",
        "120000000000000000"
      );

      //Get Supporter of Concert
      const supporters = await supporterInstance.getSuppoterForConcert(1);
      assert.equal(supporters.length, 1);
      assert.equal(supporters[0], accounts[5]);

      //Get Attendees of Concert
      const attendees = await ticketInstance.getAttendees(1);
      assert.equal(attendees.length, 2);
      assert.equal(attendees[0], accounts[5]);
      assert.equal(attendees[1], accounts[6]);
    });
  });
});
