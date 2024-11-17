pragma solidity ^0.5.0;

contract Concert  {
    // Struct for Concert Listing
    struct Listing {
        address artist;
        uint256 concertID;
        address venue;
        address organiser;
        uint256 artistPayoutPercentage;
        uint256 organiserPayoutPercentage;
        uint256 platformPayoutPercentage;
        uint256 venuePayoutPercentage;
        uint256 venuePostalCode;
        uint256 totalTickets;
        uint256 concertStartDateTime; //Epoch
        uint256 concertEndDateTime; //Epoch
        bool isBallot;
        uint256 preSaleQuality;
        uint256 preSaleStartDateTime; //Epoch
        uint256 preSaleEndDateTime; //Epoch
        uint256 generalSaleStartDateTime; //Epoch
        string ticketInfoURI;
        uint256 preSaleTicketPrice;
        uint256 generalSaleTicketPrice;
        uint256 concertState; // Created, ArtistApproval, VenueApproval, PreSale, GeneralSale, SoldOut, Cancelled, Payout
    }
    
    // Enum for Concert State
    enum ConcertState { Created, PreSale, GeneralSale, SoldOut, Cancelled }

    // Storage Memory for Concert
    mapping(uint256 => Listing) public Listings;
    uint256 public defaultConcertPlatformPayoutPercentage;
    uint256 public defaultTicketPlatformFeePercentage;
    address ticketContract;
    uint256 concertID;
    address supporterContract;
    
    // Events
    event ConcertStatus(uint256 concertID, uint256 concertState);
    event TicketPurchase(uint256 concertID, uint256 supporterNFTID , uint256 ticketID);




}