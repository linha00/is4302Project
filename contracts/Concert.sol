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
    address owner;
    
    // Events
    event ConcertStatus(uint256 concertID, uint256 concertState);
    event TicketPurchase(uint256 concertID, uint256 supporterNFTID , uint256 ticketID);

    // Constructor
    constructor(address _ticketContract, address _supporterContract) public {
        ticketContract = _ticketContract;
        supporterContract = _supporterContract;
        owner = msg.sender;
        concertID = 1;
        defaultConcertPlatformPayoutPercentage = 10;
        defaultTicketPlatformFeePercentage = 5;
    }

    // Function to create a new concert listing
    function createConcert(
        address _artist,
        address _venue,
        address _organiser,
        uint256 _artistPayoutPercentage,
        uint256 _organiserPayoutPercentage,
        uint256 _venuePayoutPercentage,
        uint256 _venuePostalCode,
        uint256 _totalTickets,
        uint256 _concertStartDateTime,
        uint256 _concertEndDateTime,
        bool _isBallot,
        uint256 _preSaleQuality,
        uint256 _preSaleStartDateTime,
        uint256 _preSaleEndDateTime,
        uint256 _generalSaleStartDateTime,
        string memory _ticketInfoURI,
        uint256 _preSaleTicketPrice,
        uint256 _generalSaleTicketPrice
    ) public {
        Listings[concertID] = Listing(
            _artist,
            concertID,
            _venue,
            _organiser,
            _artistPayoutPercentage,
            _organiserPayoutPercentage,
            defaultConcertPlatformPayoutPercentage,
            _venuePayoutPercentage,
            _venuePostalCode,
            _totalTickets,
            _concertStartDateTime,
            _concertEndDateTime,
            _isBallot,
            _preSaleQuality,
            _preSaleStartDateTime,
            _preSaleEndDateTime,
            _generalSaleStartDateTime,
            _ticketInfoURI,
            _preSaleTicketPrice,
            _generalSaleTicketPrice,
            uint256(ConcertState.Created)
        );
        concertID++;
        
    }

}