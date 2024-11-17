pragma solidity ^0.5.0;

contract Concert  {
    // Struct for Concert Listing
    struct Listing {
        address artist;
        uint256 id;
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
        uint256 concertState; // 0 - Created, 1 - PreSale, 2 - GeneralSale, 3 - SoldOut, 4 - Cancelled
    }

}