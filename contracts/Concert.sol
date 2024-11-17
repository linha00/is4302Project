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
        uint256 concertState; // PendingArtistApproval, ArtistApproval, PendingVenueApproval, VenueApproval, PreSale, GeneralSale, SoldOut, Cancelled, Payout
    }
    
    // Enum for Concert State
    enum ConcertState {  PreSale, GeneralSale, SoldOut, Cancelled, Payout, PendingArtistApproval, ArtistApproval, PendingVenueApproval, VenueApproval, Created }


    // Storage Memory for Concert
    mapping(uint256 => Listing) public Listings;
    uint256 public defaultConcertPlatformPayoutPercentage;
    uint256 public defaultTicketPlatformFeePercentage;
    address ticketContract;
    uint256 concertID;
    address supporterContract;

    address owner;
    
    // Events
    event ConcertStatus(uint256 indexed concertID, uint256 indexed concertState);
    event TicketPurchase(uint256 indexed concertID, uint256 indexed supporterNFTID , uint256 indexed ticketID);

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
       
        //Error Checking
        //Payout Check
        require(_artistPayoutPercentage >= 0, "Artist Payout Percentage must be greater than or equal to 0");
        require(_artistPayoutPercentage <= 100, "Artist Payout Percentage must be less than or equal to 100");
        require(_organiserPayoutPercentage >= 0, "Organiser Payout Percentage must be greater than or equal to 0");
        require(_organiserPayoutPercentage <= 100, "Organiser Payout Percentage must be less than or equal to 100");
        require(_venuePayoutPercentage >= 0, "Venue Payout Percentage must be greater than or equal to 0");
        require(_venuePayoutPercentage <= 100, "Venue Payout Percentage must be less than or equal to 100");
    
        //Total Tickets Check
        require(_totalTickets > 0, "Total Tickets must be greater than 0");
        require(_preSaleQuality <= _totalTickets, "Pre Sale Quality must be less than or equal to Total Tickets");

        //Date Time Check
        require(_concertStartDateTime > now, "Concert Start Date Time must be greater than current date time");
        require(_concertEndDateTime > _concertStartDateTime, "Concert End Date Time must be greater than Concert Start Date Time");
        require(_preSaleStartDateTime > now, "Pre Sale Start Date Time must be greater than current date time");
        require(_preSaleEndDateTime > _preSaleStartDateTime, "Pre Sale End Date Time must be greater than Pre Sale Start Date Time");
        require(_generalSaleStartDateTime > _preSaleEndDateTime, "General Sale Start Date Time must be greater than Pre Sale End Date Time");
        require(_concertStartDateTime > _generalSaleStartDateTime, "Concert Start Date Time must be greater than General Sale Start Date Time");
        //Ticket Price Check
        require(_preSaleTicketPrice >= 0, "Pre Sale Ticket Price must be greater than 0");
        require(_generalSaleTicketPrice >= 0, "General Sale Ticket Price must be greater than 0");



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
            uint256(ConcertState.PendingArtistApproval)
        );

        // Concert ID Increment
        concertID++;
        // Record Concert Status
        emit ConcertStatus(concertID, uint256(ConcertState.PendingArtistApproval));

    }

}