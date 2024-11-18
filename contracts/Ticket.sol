pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Contract.sol";


contract Ticket is IERC721 {
    
    Concert public concertContract;

    struct Metadata {
        uint256 concertId;
        uint256 ticketId;
        uint256 ticketPrice;
        string ticketURI;
        address owner;
        address previousOwner;
        address artist;
    }

    address public owner;
    uint256 public ticketId;
    mapping(address=> mapping (address => bool)) private operatorApprovalsForAll;
    mapping(uint256 => address) private operatorApprovals;

    mapping(uint256 => Metadata) public ticketsMetadata;

    // Keep Track of the total number of tickets a user has
    mapping(address => uint256) private balances;

    // Keep track of the ticket used
    mapping(uint256 => bool) public usedTickets;

    // Events from IERC721
    /*
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    */

    // Constructor
    constructor(address _concertContract) public {
        owner = msg.sender;
        concertContract = Concert(_concertContract);
    }

    // modifiers
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier toCannotBeZero(address _to) {
        require(_to != address(0), "Invalid address");
        _;
    }

    modifier fromCannotBeZero(address _from) {
        require(_from != address(0), "Invalid address");
        _;
    }

    modifier isTokenOwner(uint256 _tokenId, address _owner) {
        require(ticketsMetadata[_tokenId].owner == _owner, "Not the owner of the token");
        _;
    }

    modifier isNotContract(address _addr) {
        
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        require(size == 0, "Contracts are not allowed");
        _;
    }

    modifier checkApproval(address _from, address _to, uint256 _tokenId) {
        if(msg.sender != _from) {
            require( 
                msg.sender == owner || 
                operatorApprovalsForAll[ticketsMetadata[_tokenId].owner][msg.sender] == true || 
                operatorApprovals[_tokenId] == msg.sender
            , "Caller is not approved to transfer this token");
        }
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(ticketsMetadata[_tokenId].owner != address(0), "Token does not exist");
        _;
    }


    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return ticketsMetadata[_tokenId].owner;
    }

    function removeApproval(uint256 _tokenId) private {
        operatorApprovals[_tokenId] = address(0); 
    }

    function updateTokenOwner(uint256 _tokenId, address _to) private {
        ticketsMetadata[_tokenId].previousOwner = ticketsMetadata[_tokenId].owner;
        ticketsMetadata[_tokenId].owner = _to;
        balances[ticketsMetadata[_tokenId].previousOwner ] -= 1;
        balances[_to] += 1;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public 
            toCannotBeZero(_to) 
            fromCannotBeZero(_from) 
            isNotContract(_to) 
            tokenExists(_tokenId) 
            isTokenOwner(_tokenId, _from) 
            checkApproval(_from, _to, _tokenId) {
   
        updateTokenOwner(_tokenId, _to);
        removeApproval(_tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from , address _to, uint256 _tokenId, bytes calldata _data) external {
        require(_data.length == 0, "Data must be empty");
        safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external tokenExists(_tokenId) {
        //The caller must own the token or be an approved operator.
        require (msg.sender == owner || operatorApprovalsForAll[ticketsMetadata[_tokenId].owner][msg.sender] == true, "Caller is not approved to approve this token"); 
        operatorApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != address(0), "Operator address cannot be zero"); 
        operatorApprovalsForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(owner, _operator, _approved);
    }

    //Returns the Account approved for TokenId
    function getApproved(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return operatorApprovals[_tokenId];
    } 

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovalsForAll[_owner][_operator];
    }

    function mint(address _to, uint256 _concertId, uint256 _ticketPrice, string calldata _ticketURI, address _artist ) external isOwner() {
        ticketsMetadata[ticketId] = Metadata(_concertId, ticketId, _ticketPrice, _ticketURI, _to, address(0), _artist);
        balances[_to] += 1;
        ticketId += 1;
        emit Transfer(address(0), _to, ticketId);
    }

    function getAttendees(uint256 _concertId) external view returns (address[] memory) {
        address[] memory attendees = new address[](ticketId);
        uint256 count = 0;
        for(uint256 i = 0; i < ticketId; i++) {
            if(ticketsMetadata[i].concertId == _concertId) {
                attendees[count] = ticketsMetadata[i].owner;
                count += 1;
            }
        }
        return attendees;
    }
    
    function useTicket(uint256 ticketId) external tokenExists(ticketId) {
        // fetch address of organiser of event
        address organiser = concertContract.Listings(concertId).organiser;

        // only the organiser || the owner of the contract
        require(
            organiser == msg.sender || 
            owner == msg.sender
        , "Caller is not authorized to use the ticket");

        require(!usedTickets[ticketId], "Ticket already used");
        usedTickets[ticketId] = true;
    }

}