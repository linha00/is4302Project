pragma solidity ^0.5.0;

import "./Supporter.sol";
import "./Collectible.sol";
import "./Ticket.sol";

contract Market {

    Ticket public ticketContract;
    Supporter public supporterContract;
    Collectible public collectibleContract;

    struct Metadata {
       uint256 tokenId;
       TokenType tokenType;
       uint256 listingPrice;
       address seller;
       address artist;
    }

    enum ListingState {Listed, Unlisted, Sold}
    enum TokenType {Ticket, Collectible}

    uint256 public platformFee;
    uint256 public artistRoyaltyFee;

    // owner of this contact
    address public owner;
    uint256 public balance;

    // the first unused listing id
    uint256 private listingId;

    // Storage Memory for Listings
    mapping(uint256 => Metadata) public Listings;
    mapping(uint256 => bool) public ticketMapping;
    mapping(uint256 => bool) public collectibleMapping;
    mapping(uint256 => ListingState) public listingState;


    // Event to track listing creation
    event ListingEvent(uint256 listingId, uint256 tokenId, TokenType tokenType, ListingState state);

    // Constructor
    constructor(Collectible _collectibleContract, Ticket _ticketContract) public {
        owner = msg.sender;
        ticketContract = _ticketContract;
        collectibleContract = _collectibleContract;
        platformFee = 10000000000000000;
        artistRoyaltyFee = 10000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }   

    modifier isValidListing(uint256 _listingId) {
        require(Listings[_listingId].listingPrice != 0, "Listing does not exist");
        _;
    }

    function getListingState(uint256 _listingId) public view isValidListing(_listingId) returns (ListingState) {
        return listingState[_listingId];
    }

    function getListingPrice(uint256 _listingId) public view isValidListing(_listingId) returns (uint256) {
        return Listings[_listingId].listingPrice;
    }

    function getTokenId(uint256 _listingId) public view isValidListing(_listingId) returns (uint256) {
        return Listings[_listingId].tokenId;
    }

    function selfdestructContract() external onlyOwner() {
        selfdestruct(msg.sender);
    }

    // modifiers
    // functions
    // create a new Listing
    function createListing(uint256 _tokenId, uint256 _listingPrice, uint256 _tokenType) external {
        
        // Ensure listing price is valid
        require((_listingPrice > (platformFee + artistRoyaltyFee) ), "Listing price must be greater than zero and cover platform and artist fees");
        require(_tokenType < 4, "Invalid token type");

        // Create the listing
        // transfer the ticket to the market contract (Transfer would check for Approval)
        if(_tokenType == uint256(TokenType.Ticket)){
            require(ticketMapping[_tokenId] == false, "Ticket is already listed");
             // Ensure the caller owns the ticket
            require(
                ticketContract.ownerOf(_tokenId) == msg.sender
                , "Caller is not the owner of the ticket");
            Listings[listingId] = Metadata({
                tokenId: _tokenId,
                tokenType: TokenType.Ticket,
                listingPrice: _listingPrice,
                seller: msg.sender,
                artist: ticketContract.getArtist(_tokenId)
            });
            ticketContract.safeTransferFrom(msg.sender, address(this), _tokenId);
            ticketMapping[_tokenId] = true;
            // Emit the event
            emit ListingEvent(listingId, _tokenId, TokenType.Ticket, ListingState.Listed);
        }
        else if(_tokenType == uint256(TokenType.Collectible)){
            // Ensure the caller owns the Collectible
            require(collectibleMapping[_tokenId] == false, "Collectible is already listed");
            require(
                collectibleContract.ownerOf(_tokenId) == msg.sender
                , "Caller is not the owner of the collectible");
            Listings[listingId] = Metadata({
                tokenId: _tokenId,
                tokenType: TokenType.Collectible,
                listingPrice: _listingPrice,
                seller: msg.sender,
                artist: collectibleContract.getArtist(_tokenId)
            });
            collectibleContract.safeTransferFrom(msg.sender, address(this), _tokenId);
            collectibleMapping[_tokenId] = true;
            // Emit the event
            emit ListingEvent(listingId, _tokenId, TokenType.Collectible, ListingState.Listed);
        }
        else {
            require(false, "Invalid token type");
        }
        listingState[listingId] = ListingState.Listed;
        // Increment the listing ID for the next listing
        listingId++;
    }

    //unlist listing
    function unlist(uint256 _listingId) public isValidListing(_listingId) {
        require(listingState[_listingId]  == ListingState.Listed, "Listing is not for sale");

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
            ticketMapping[_tokenId] = false;
            // Emit the event
            emit ListingEvent(listingId, _tokenId, TokenType.Ticket, ListingState.Unlisted);
        }
        else if(Listings[_listingId].tokenType == TokenType.Collectible){
            // Ensure the caller owns the Collectible
            require(
                collectibleContract.ownerOf(_tokenId) == address(this)
                , "Caller is not the owner of the collectible");
            require(
                collectibleContract.getPreviousOwner(_tokenId) == msg.sender
                , "Caller is not the previous owner of the collectible");
            collectibleContract.safeTransferFrom(address(this), msg.sender, _tokenId);
            collectibleMapping[_tokenId] = false;
            // Emit the event
            emit ListingEvent(listingId, _tokenId, TokenType.Collectible, ListingState.Unlisted);
        }
        else {
            require(false, "Invalid token type");
        }

        listingState[_listingId] = ListingState.Unlisted;

        // Remove the listing
        // delete Listings[_listingId];

    }

    // Purchase a listed item
    function buy(uint256 _listingId) external payable isValidListing(_listingId) {
        require(listingState[_listingId]  == ListingState.Listed, "Listing is not for sale");

        require(msg.value >= Listings[_listingId].listingPrice, "Insufficient amount paid for NFT");
        
        // Transfer the NFT to the buyer
        if(Listings[_listingId].tokenType == TokenType.Ticket){
            ticketContract.safeTransferFrom(address(this), msg.sender, Listings[_listingId].tokenId);
            ticketMapping[Listings[_listingId].tokenId] = false;
        }
        else if(Listings[_listingId].tokenType == TokenType.Collectible){
            collectibleContract.safeTransferFrom(address(this), msg.sender, Listings[_listingId].tokenId);
            collectibleMapping[Listings[_listingId].tokenId] = false;
        }
        else {
            require(false, "Invalid token type");
        }

        // Update listing state to sold
        listingState[_listingId] = ListingState.Sold;

        // Return any change
        if (msg.value > Listings[_listingId].listingPrice) {
            uint256 change = msg.value - Listings[_listingId].listingPrice;
            (bool sent, ) = msg.sender.call.value(change)("");
            require(sent, "Failed to Return Change");
        }
        // Pay the Contract
        balance += platformFee;
        // Pay the Artist
        (bool sentArtist, ) = Listings[_listingId].artist.call.value(artistRoyaltyFee)("");
        require(sentArtist, "Failed to Pay Artist");
        // Pay the Seller
        (bool sentSeller, ) = Listings[_listingId].seller.call.value(Listings[_listingId].listingPrice - artistRoyaltyFee - platformFee)("");
        require(sentSeller, "Failed to Pay Seller");
        
        // Emit event for the sale
        emit ListingEvent(_listingId, Listings[_listingId].tokenId, Listings[_listingId].tokenType, ListingState.Sold);
    }
}
