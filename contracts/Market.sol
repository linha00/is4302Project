pragma solidity ^0.5.0;

import "./Concert.sol";
import "./Ticket.sol";

contract Market {

    Concert public concertContract;
    Ticket public ticketContract;

    struct Metadata {
       uint256 tokenId;
       TokenType tokenType;
       uint256 listingPrice;
       ListingState state;
    }

    enum ListingState {Listed, Unlisted, Sold}
    enum TokenType {Ticket, Supporter, Collectible}

    uint256 public platformFee;
    uint256 public artistRoyaltyFee;

    // owner of this contact
    address public owner;

    // the first unused listing id
    uint256 private listingId;

    // Storage Memory for Listings
    mapping(uint256 => Metadata) public Listings;


    // Event to track listing creation
    event ListingEvent(uint256 listingId, uint256 tokenId, TokenType tokenType, ListingState state);

    // Constructor
    constructor(address _concertContract, address _ticketContract) public {
        owner = msg.sender;
        concertContract = Concert(_concertContract);
        ticketContract = Ticket(_ticketContract);
    }

    // modifiers
    // functions
    // create a new Listing
    function createListing(uint256 _tokenId, uint256 _listingPrice, uint256 _tokenType) external {
       

        // Ensure listing price is valid
        require(_listingPrice - platformFee - artistRoyaltyFee > 0, "Listing price must be greater than zero and cover platform and artist fees");

        
        require(_tokenType < 4, "Invalid token type");

        // Create the listing
        // transfer the ticket to the market contract (Transfer would check for Approval)
        if(_tokenType == 1){
             // Ensure the caller owns the ticket
            require(
                ticketContract.ownerOf(_tokenId) == msg.sender
                , "Caller is not the owner of the ticket");
            Listings[listingId] = Metadata({
                tokenId: _tokenId,
                tokenType: TokenType.Ticket,
                listingPrice: _listingPrice,
                state: ListingState.Listed
            });
            ticketContract.safeTransferFrom(msg.sender, address(this), _tokenId);
            // Emit the event
            emit ListingEvent(listingId, _tokenId, TokenType.Ticket, ListingState.Listed);
        }

        // Increment the listing ID for the next listing
        listingId++;
    }

    //unlist listing
    function unlist(uint256 _listingId) public {
        // Ensure the listing exists
        require(Listings[_listingId].tokenId != 0, "Listing does not exist");
        uint256 _tokenId = Listings[_listingId].tokenId;
        if(Listings[_listingId].tokenType == TokenType.Ticket){
             // Ensure the caller owns the ticket
            require(
                ticketContract.ownerOf(_tokenId) == address(this)
                , "Caller is not the owner of the ticket");
            require(
                ticketContract.getPreviousOwner(_tokenId) == msg.sender
                , "Caller is not the previous owner of the ticket");
            ticketContract.safeTransferFrom(address(this), msg.sender, _tokenId);
            // Emit the event
            emit ListingEvent(listingId, _tokenId, TokenType.Ticket, ListingState.Unlisted);
        }

        // Remove the listing
        delete Listings[_listingId];

    }
}