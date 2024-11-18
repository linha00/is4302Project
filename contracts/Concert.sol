pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Supporter.sol";
import "./Ticket.sol";

contract Concert  {
    // Struct for Concert Listing
    struct Listing {
        address artist;
        address venue;
        address organiser;
        uint256 artistPayoutPercentage;
        uint256 organiserPayoutPercentage;
        uint256 venuePayoutPercentage;
        uint256 totalTickets;
        string  ticketInfoURI;
        uint256 preSaleQuantity;
        uint256 preSaleTicketPrice;
        uint256 generalSaleTicketPrice;
        uint256 concertState; 
    }
    
    // Enum for Concert State
    enum ConcertState {  PreSale, PreSaleOver, GeneralSale, SoldOut, Cancelled, Payout, Created,  PendingArtistApproval, ArtistApproved, PendingVenueApproval, VenueApproved, OrganiserApproved }

    // Storage Memory for Concert
    mapping(uint256 => Listing) public Listings;
    mapping(address => bool) public organisersApproval;
    mapping(address => bool) public venuesApproval;
    mapping(address => bool) public artistsApproval;
    mapping(uint256 => uint256) public ticketsSold;

    uint256 public defaultConcertPlatformPayoutPercentage;
    uint256 public defaultTicketPlatformFeePercentage;

    uint256 concertID;

    Supporter public supporterContract;
    address owner;
    Ticket public ticketContract;

    // Events
    event ConcertStatus(uint256 indexed concertID, uint256 indexed concertState);
    event TicketPurchase(uint256 indexed concertID, uint256 indexed supporterNFTID , uint256 indexed ticketID);

    // Constructor
    constructor(Ticket _ticketAddress, Supporter _supporterAddress) public {
        ticketContract = _ticketAddress;
        supporterContract = _supporterAddress;
        owner = msg.sender;
        concertID = 1;
        defaultConcertPlatformPayoutPercentage = 10;
        defaultTicketPlatformFeePercentage = 5;
    }

    // Check that Organiser is Approved
    modifier onlyApprovedOrganiser() {
        require(organisersApproval[msg.sender] == true, "Organiser not approved");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }   

    // Approve Organiser
    function approveOrganiser(address _organiser) external onlyOwner {
        organisersApproval[_organiser] = true;
    }

    // Approve Venue
    function approveVenue(address _venue) external onlyOwner {
        venuesApproval[_venue] = true;
    }

    // Approve Artist
    function approveArtist(address _artist) external onlyOwner {
        artistsApproval[_artist] = true;
    }

    // Function to create a new concert listing
    function createConcert(
        address _artist,
        address _venue,
        uint256 _artistPayoutPercentage,
        uint256 _organiserPayoutPercentage,
        uint256 _venuePayoutPercentage,
        uint256 _totalTickets,
        uint256 _preSaleQuality,
        string calldata _ticketInfoURI,
        uint256 _preSaleTicketPrice,
        uint256 _generalSaleTicketPrice
    ) external onlyApprovedOrganiser() returns (uint256) {
       
        //Error Checking

        //Payout Check
        require(_artistPayoutPercentage >= 0, "Artist Payout Percentage must be greater than or equal to 0");
        require(_artistPayoutPercentage <= 100, "Artist Payout Percentage must be less than or equal to 100");
        require(_organiserPayoutPercentage >= 0, "Organiser Payout Percentage must be greater than or equal to 0");
        require(_organiserPayoutPercentage <= 100, "Organiser Payout Percentage must be less than or equal to 100");
        require(_venuePayoutPercentage >= 0, "Venue Payout Percentage must be greater than or equal to 0");
        require(_venuePayoutPercentage <= 100, "Venue Payout Percentage must be less than or equal to 100");
        require(_artistPayoutPercentage + _organiserPayoutPercentage + _venuePayoutPercentage + defaultConcertPlatformPayoutPercentage == 100, "Total Payout Percentage must be equal to 100");

        //Total Tickets Check
        require(_totalTickets > 0, "Total Tickets must be greater than 0");
        require(_preSaleQuality <= _totalTickets, "Pre Sale Quality must be less than or equal to Total Tickets");

        //Ticket Price Check
        require(_preSaleTicketPrice >= 0, "Pre Sale Ticket Price must be greater than 0");
        require(_generalSaleTicketPrice >= 0, "General Sale Ticket Price must be greater than 0");

        Listings[concertID] = Listing(
            _artist,
            _venue,
            msg.sender,
            _artistPayoutPercentage,
            _organiserPayoutPercentage,
            _venuePayoutPercentage,
            _totalTickets,
            _ticketInfoURI,
               _preSaleQuality,
            _preSaleTicketPrice,
            _generalSaleTicketPrice,
            uint256(ConcertState.PendingVenueApproval)
        );



        // Record Concert Status
        emit ConcertStatus(concertID, uint256(ConcertState.OrganiserApproved));
        // Concert ID Increment
        concertID++;
        return concertID-1;
    }

    // Get all Concerts where Start Date Time is greater than current date time + 1 day
    function getListings() external view returns (Listing[] memory) {
        Listing[] memory listing = new Listing[](concertID);
        for (uint256 i = 0; i < concertID; i++) {
            //Created and Below
            if (Listings[i].concertState < 6) {
                listing[i] = Listings[i];
            }
        }
        return listing;
    } 

    function getListing(uint256 _concertID) external view returns (Listing memory) {
        return Listings[_concertID];
    }

    // Venue approve Concert
    function venueApproveConcert(uint256 _concertID) external {
        
        require(venuesApproval[msg.sender] == true, "Venue not approved");
        require(Listings[_concertID].venue == msg.sender, "Venue not the same as concert venue");
        require(Listings[_concertID].concertState == uint256(ConcertState.PendingVenueApproval), "Concert not in Pending Venue Approval State");

        Listings[_concertID].concertState = uint256(ConcertState.PendingArtistApproval);
        emit ConcertStatus(_concertID, uint256(ConcertState.VenueApproved));
    }

    // Artist approve Concert
    function artistApproveConcert(uint256 _concertID) external {
        
        require(artistsApproval[msg.sender] == true, "Artist not approved");
        require(Listings[_concertID].artist == msg.sender, "Artist not the same as concert artist");
        require(Listings[_concertID].concertState == uint256(ConcertState.PendingArtistApproval), "Concert not in Pending Artist Approval State");

        emit ConcertStatus(_concertID, uint256(ConcertState.ArtistApproved));
        emit ConcertStatus(_concertID, uint256(ConcertState.Created));

        //Decide if Concert is PreSale or General Sale
        if(Listings[_concertID].preSaleQuantity > 0) {
            Listings[_concertID].concertState = uint256(ConcertState.PreSale);
        } else {
            Listings[_concertID].concertState = uint256(ConcertState.GeneralSale);
        }
    }

    function checkVenueAddressApproval(address venue) external view returns (bool) {
        return venuesApproval[venue];
    }

    function checkArtistAddressApproval(address artist) external view returns (bool) {
        return artistsApproval[artist];
    }

    function checkOrganiserAddressApproval(address organiser) external view returns (bool) {
        return organisersApproval[organiser];
    }

}