pragma solidity ^0.5.0;

import "./Contract.sol";
import "./Ticket.sol";

contract Market {
    Concert public concertContract;
    Ticket public ticketContract;

    struct Metadata {
        uint256 concertId;
        uint256 ticketId;
        uint256 ticketPrice;
        uint256 listingPrice;
        string ticketURI;
        address owner;
        address artist;
    }

    // owner of this contact
    address public owner;

    // the first unused listing id
    uint256 private listingId;

    // Storage Memory for Listings
    mapping(uint256 => Metadata) public Listings;


    // Event to track listing creation
    event ListingCreated(uint256 listingId, uint256 tokenId, uint256 listingPrice, address owner);

    // Event to track unlisting
    event ListingRemoved(uint256 listingId, uint256 tokenId, address owner);


    // Constructor
    constructor(address _concertContract, address _ticketContract) public {
        owner = msg.sender;
        concertContract = Concert(_concertContract);
        ticketContract = Ticket(_ticketContract);
    }


    // modifiers


    // functions
    // create a new Listing
    function createListing(uint256 _tokenId, uint256 _listingPrice) {
        // Ensure the caller owns the ticket
        require(
            ticketContract.ticketsMetadata(_tokenId).owner == msg.sender
        , "Caller is not the owner of the ticket");

        // Ensure listing price is valid
        require(_listingPrice > 0, "Listing price must be greater than zero");

        // Ensure the Market contract is approved to transfer the ticket
        address approvedAddress = ticketContract.getApproved(_tokenId);
        require(
            approvedAddress == address(this) || ticketContract.isApprovedForAll(tokenOwner, address(this)),
            "Market contract is not approved to transfer this ticket"
        );
        
        // transfer the ticket to the market contract

        // Create the listing
        Listings[listingId] = Metadata({
            concertId: ticketContract.ticketsMetadata(_tokenId).concertId,
            ticketId: _tokenId,
            ticketPrice: ticketContract.ticketsMetadata(_tokenId).ticketPrice,
            listingPrice: _listingPrice,
            ticketURI: ticketContract.ticketsMetadata(_tokenId).ticketURI,
            owner: msg.sender,
            artist: ticketContract.ticketsMetadata(_tokenId).artist
        });

        // Emit the event
        emit ListingCreated(listingId, _tokenId, _listingPrice, msg.sender);

        // Increment the listing ID for the next listing
        listingId++;
    }

    //unlist listing
    function unlist(uint256 _listingId) public {
        // Ensure the listing exists
        require(Listings[_listingId].owner != address(0), "Listing does not exist");

        // Ensure the caller is the owner of the listing
        require(Listings[_listingId].owner == msg.sender, "Caller is not the owner of the listing");

        //transfer the ticket back to owner

        // Remove the listing
        delete Listings[_listingId];

        // Emit the event
        emit ListingRemoved(_listingId, Listings[_listingId].ticketId, msg.sender);
    }
}