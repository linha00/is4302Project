pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Supporter.sol";
import "./Ticket.sol";

// SafeMath library to perform safe arithmetic operations (addition, subtraction, multiplication, division).
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// Main Concert contract to manage concert creation, ticket sales, and payouts.
contract Concert  {

    using SafeMath for uint256;

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
    }
    
    // Storage Memory for Concert
    mapping(uint256 => Listing) public Listings;
    mapping(address => bool) public organisersApproval;
    mapping(address => bool) public venuesApproval;
    mapping(address => bool) public artistsApproval;
    mapping(uint256 => uint256) public ticketsSold;
    mapping(uint256 => uint256) public preSaleticketsSold;
    mapping(uint256 => ConcertState) public concertState;


    // Enum for Concert State
    enum ConcertState {  PreSale, PreSaleOver, GeneralSale, SoldOut, Cancelled, Payout, Created,  PendingArtistApproval, ArtistApproved, PendingVenueApproval, VenueApproved, OrganiserApproved, Live }

    // Contract-level state variables
    uint256 public defaultConcertPlatformPayoutPercentage;
    uint256 public defaultTicketPlatformFeePercentage;

    uint256 concertID;
    uint256 balances;

    Supporter public supporterContract;
    Ticket public ticketContract;
    address owner;

    // Events to log concert status and ticket purchases
    event ConcertStatus(uint256 indexed concertID, ConcertState indexed concertState);
    event TicketPurchase(uint256 indexed concertID, uint256 indexed supporterNFTID , uint256 indexed ticketID);

    // Constructor to initialize the contract
    constructor(Ticket _ticketAddress, Supporter _supporterAddress) public {
        ticketContract = _ticketAddress;
        supporterContract = _supporterAddress;
        owner = msg.sender;
        concertID = 1;
        defaultConcertPlatformPayoutPercentage = 10;
        defaultTicketPlatformFeePercentage = 5;
    }

    // Check to restrict access to only approved organisers
    modifier onlyApprovedOrganiser() {
        require(organisersApproval[msg.sender] == true, "Organiser not approved");
        _;
    }

    // Check to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }   

    // Check to ensure the concert exists
    modifier concertExists(uint256 _concertID) {
        require(Listings[_concertID].artist != address(0), "Concert does not exist");
        _;
    }

    // Function to approve an organiser. Only the owner can call this
    function approveOrganiser(address _organiser) external onlyOwner {
        organisersApproval[_organiser] = true;
    }

    // Function to approve a venue. Only the owner can call this
    function approveVenue(address _venue) external onlyOwner {
        venuesApproval[_venue] = true;
    }

    // Function to approve an artist. Only the owner can call this
    function approveArtist(address _artist) external onlyOwner {
        artistsApproval[_artist] = true;
    }

    // Allows an approved venue to approve a concert and change its state
    function updateVenueStateApproval(uint256 _concertId) external  {
        require(venuesApproval[msg.sender] == true, "Venue not approved");
        require(Listings[_concertId].venue == msg.sender, "Venue not the same as concert venue");
        require(concertState[_concertId] == ConcertState.PendingVenueApproval, "Concert not in Pending Venue Approval State");
        concertState[_concertId] = ConcertState.PendingArtistApproval;
        emit ConcertStatus(_concertId, ConcertState.VenueApproved);
    }

    function selfdestructContract() external onlyOwner() {
        selfdestruct(msg.sender);
    }

    // Function to allow approved organiser to create a new concert listing
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

        //Validate payout percentages
        require(_artistPayoutPercentage > 0, "Artist Payout Percentage must be greater than or equal to 0");
        require(_artistPayoutPercentage <= 100, "Artist Payout Percentage must be less than or equal to 100");
        require(_organiserPayoutPercentage > 0, "Organiser Payout Percentage must be greater than or equal to 0");
        require(_organiserPayoutPercentage <= 100, "Organiser Payout Percentage must be less than or equal to 100");
        require(_venuePayoutPercentage > 0, "Venue Payout Percentage must be greater than or equal to 0");
        require(_venuePayoutPercentage <= 100, "Venue Payout Percentage must be less than or equal to 100");
        require(_artistPayoutPercentage + _organiserPayoutPercentage + _venuePayoutPercentage + defaultConcertPlatformPayoutPercentage == 100, "Total Payout Percentage must be equal to 100");

        // Validate ticket details
        require(_totalTickets > 0, "Total Tickets must be greater than 0");
        require(_preSaleQuality < _totalTickets, "Pre Sale Quality must be less than Total Tickets");

        // Validate ticket prices
        require(_preSaleTicketPrice >= 0, "Pre Sale Ticket Price must be greater than 0");
        require(_generalSaleTicketPrice >= 0, "General Sale Ticket Price must be greater than 0");

        // Create a new listing
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
            _generalSaleTicketPrice
        );

        concertState[concertID] = ConcertState.PendingVenueApproval;
        // Record Concert Status
        emit ConcertStatus(concertID, ConcertState.OrganiserApproved);
        // Concert ID Increment
        concertID++;
        return concertID-1;
    }

    // Get all Concerts where Start Date Time is greater than current date time + 1 day
    function getListings() external view returns (Listing[] memory) {
        Listing[] memory listing = new Listing[](concertID);
        for (uint256 i = 0; i < concertID; i++) {
            //Created and Below
            if (uint256(concertState[i]) < 6) {
                listing[i] = Listings[i];
            }
        }
        return listing;
    } 

    // Returns the details of a specific concert listing
    function getListing(uint256 _concertID) external view returns (Listing memory) {
        return Listings[_concertID];
    }

    // Returns the current state of a specific concert
    function getConcertState(uint256 _concertID) external view returns (ConcertState) {
        return concertState[_concertID];
    }

    // Allows an approved artist to approve a concert and change its state
    function updateArtistStateApproval(uint256 _concertID) external {
        
        require(artistsApproval[msg.sender] == true, "Artist not approved");
        require(Listings[_concertID].artist == msg.sender, "Artist not the same as concert artist");
        require(concertState[_concertID] == ConcertState.PendingArtistApproval, "Concert not in Pending Artist Approval State");

        emit ConcertStatus(_concertID, ConcertState.ArtistApproved);
        emit ConcertStatus(_concertID, ConcertState.Created);

        //Decide if Concert is PreSale or General Sale
        if(Listings[_concertID].preSaleQuantity > 0) {
            concertState[_concertID] = ConcertState.PreSale;
        } else {
            concertState[_concertID] = ConcertState.GeneralSale;
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

    // Allows an approved organiser to update the concert state to live or canceled
    function organiserUpdateState(uint256 _concertID, uint256 _newState) external onlyApprovedOrganiser() {
        require(concertState[_concertID]==ConcertState.PreSale || concertState[_concertID]==ConcertState.PreSaleOver || concertState[_concertID]==ConcertState.GeneralSale|| concertState[_concertID]==ConcertState.SoldOut, "Invalid Concert State");
        require(_newState == uint256(ConcertState.Cancelled) ||  _newState == uint256(ConcertState.Live), "Invalid Concert State");
        concertState[_concertID] = ConcertState(_newState);
        emit ConcertStatus(_concertID, ConcertState(_newState));
    }

    // Allows users to buy a ticket for a concert, with distinct logic for pre-sale and general sale
    function buyTicket(uint256 _concertID, string calldata ticketURI, string calldata supporterURI) external payable concertExists(_concertID) {
        require(concertState[_concertID] == ConcertState.PreSale || concertState[_concertID] == ConcertState.GeneralSale, "Tickets are not on sale now");
        //Pre sale
        if (concertState[_concertID] == ConcertState.PreSale) {
            require(msg.value >= Listings[_concertID].preSaleTicketPrice, "Insufficient amount paid for pre sale ticket");
            
            // Mint ticket and transfer to buyer
            uint256 ticketID = ticketContract.mint(owner, _concertID, Listings[_concertID].preSaleTicketPrice, ticketURI, Listings[_concertID].artist);
            ticketContract.safeTransferFrom(owner, msg.sender, ticketID);
            
            // Mint supporter nft and transfer to buyer
            uint256 supporterNFTID = supporterContract.mint(msg.sender, _concertID, supporterURI, Listings[_concertID].artist);
            
            // Update tickets sold and concert status
            preSaleticketsSold[_concertID]++;
            if (preSaleticketsSold[_concertID] == Listings[_concertID].preSaleQuantity) {
                concertState[_concertID] = ConcertState.GeneralSale;
                emit ConcertStatus(_concertID, ConcertState.PreSaleOver);
            }

            // Return any change
            if (msg.value > Listings[_concertID].preSaleTicketPrice) {
                uint256 change = msg.value - Listings[_concertID].preSaleTicketPrice;
                (bool sent, ) = msg.sender.call.value(change)("");
                require(sent, "Failed to Return Change");
            }
            // Pay the Contract
            balances += Listings[_concertID].preSaleTicketPrice;
            emit TicketPurchase(_concertID, supporterNFTID , ticketID);

        } else { // General sale
            require(msg.value >= Listings[_concertID].generalSaleTicketPrice, "Insufficient amount paid for general sale ticket");
            
            // Mint ticket and transfer to buyer
            uint256 ticketID = ticketContract.mint(owner, _concertID, Listings[_concertID].generalSaleTicketPrice, ticketURI, Listings[_concertID].artist);
            ticketContract.safeTransferFrom(owner, msg.sender, ticketID);
            
            // Update tickets sold and concert status
            ticketsSold[_concertID]++;
            if (ticketsSold[_concertID] + preSaleticketsSold[_concertID] == Listings[_concertID].totalTickets) {
                concertState[_concertID] = ConcertState.SoldOut;
                emit ConcertStatus(_concertID, ConcertState.SoldOut);
            }

            // Return any change
            if (msg.value > Listings[_concertID].generalSaleTicketPrice) {
                uint256 change = msg.value - Listings[_concertID].generalSaleTicketPrice;
                (bool sent, ) = msg.sender.call.value(change)("");
                require(sent, "Failed to Return Change");
            }
            // Pay the Contract
            balances += Listings[_concertID].generalSaleTicketPrice;
            emit TicketPurchase(_concertID, 0 , ticketID);
        }
    }

    function getListingID() external view returns (uint256) {
        return concertID;
    }

    // Triggers payouts for a live concert, distributing funds to the artist, organiser, and venue
    function triggerPayout(uint256 _concertID) external onlyOwner() {
        // Fetch the concert details
        Listing storage listing = Listings[_concertID];

        // Ensure the concert is in the correct state
        require(concertState[_concertID] == ConcertState.Live , "Concert is not in Correct state");

        // Calculate total funds collected (ticketsSold * ticket price, assuming one price for simplicity)
        uint256 totalFunds = (ticketsSold[_concertID] * listing.generalSaleTicketPrice) + (preSaleticketsSold[_concertID] * listing.preSaleTicketPrice);

        // Ensure the contract balance is sufficient for the payouts
        require(balances >= totalFunds, "Insufficient contract balance for payouts");


        // Ensure total percentages add up to 100
        require(
            listing.artistPayoutPercentage +
            listing.organiserPayoutPercentage +
            listing.venuePayoutPercentage +
            defaultConcertPlatformPayoutPercentage == 100,
            "Payout percentages do not add up to 100"
        );

        // Calculate payouts for Live Concert      
        uint256 artistPayout = (totalFunds.mul(listing.artistPayoutPercentage)).div(100);
        uint256 organiserPayout = (totalFunds.mul(listing.organiserPayoutPercentage)).div(100);
        uint256 venuePayout = (totalFunds.mul(listing.venuePayoutPercentage)).div(100);

        // Transfer funds to artist
        (bool sentArtist, ) = listing.artist.call.value(artistPayout)("");
        balances -= artistPayout;
        require(sentArtist, "Failed to transfer funds to artist");
        // Transfer funds to organiser
        (bool sentOrganiser, ) = listing.organiser.call.value(organiserPayout)("");
        balances -= organiserPayout;
        require(sentOrganiser, "Failed to transfer funds to organiser");
        // Transfer funds to venue
        (bool sentVenue, ) = listing.venue.call.value(venuePayout)("");
        balances -= venuePayout;
        require(sentVenue, "Failed to transfer funds to venue");
        
        require(balances > 0,"Contract balance is zero");
        // Update state
        concertState[_concertID] = ConcertState.Payout;
        emit ConcertStatus(_concertID, ConcertState.Payout);
    }


    // function transferNFTToAttendees(uint256 _concertID, uint256[] calldata _ticketIDs) external {
    //     // Ensure the caller is the artist of the concert
    //     Listing storage listing = Listings[_concertID];
    //     require(msg.sender == listing.artist, "Caller is not the artist of the concert");

    //     // Ensure the concert is in a state where NFT transfers are allowed
    //     require(listing.concertState == uint256(ConcertState.SoldOut), "Concert is not in a SoldOut state");

    //     // Loop through the list of ticket IDs and transfer the NFT to ticket holders
    //     for (uint256 i = 0; i < _ticketIDs.length; i++) {
    //         address attendee = ticketContract.ownerOf(_ticketIDs[i]);
    //         require(attendee != address(0), "Invalid ticket owner");

    //         // Transfer the NFT collectible to the attendee
    //         ticketContract.transferFrom(msg.sender, attendee, _ticketIDs[i]);
    //     }

    //     emit NFTTransferredToAttendees(_concertID, _ticketIDs);
    // }

    // // Event for tracking NFT transfers
    // event NFTTransferredToAttendees(uint256 indexed concertID, uint256[] ticketIDs);

    //function transferNFTToPresaleAttendees(uint256 _concertID, uint256[] calldata _ticketIDs) external{
    //    Listing storage listing = Listings[_concertID];
    //    require(msg.sender == listing.artist, "Caller is not the artist of the concert");

    //    for(uint256 i = 0; i < _ticketIDs.length; i++){
    //        address attendee = ticketContract.ownerOf(_ticketIDs[i]);
    //        require(attendee != address(0), "Invalid ticket owner");

    //        require(supporterTokenContract.balanceOf(attendee) > 0, "Attendee does not own a supporter token");
    //        ticketContract.transferFrom(msg.sender, attendee, _ticketIDs[i]);
    //    }
    //    emit transferNFTToPresaleAttendees(_concertID, _ticketIDs);

    //}
    //event transferNFTToPresaleAttendees(uint256 concertID, uint256[] ticketIDs);


}
