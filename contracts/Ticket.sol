pragma solidity ^0.5.0;

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC165} from "../interfaces/IERC165.sol";

contract Ticket is  IERC165 {
    
    // Struct for ticketsMetadata
    struct Metadata {
        uint256 concertId;
        uint256 ticketPrice;
        string ticketURI;
        address owner;
        address previousOwner;
        address artist;
    }

    // Contract-level state variables
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;    
    address public owner;
    uint256 public ticketId;


    // Storage Memory
    mapping(address=> mapping (address => bool)) private operatorApprovalsForAll;
    mapping(uint256 => address) private operatorApprovals;
    // stores the metadata of tickets 
    mapping(uint256 => Metadata) public ticketsMetadata;
    // keep track of the approved minters that are allowed to mint new tickets
    mapping(address => bool) public approvedMinters;
    // Keep track of the total number of tickets a user has
    mapping(address => uint256) private balances;
    // Keep track of the ticket used
    mapping(uint256 => bool) public usedTickets;


    // Events from IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // Constructor
    constructor() public {
        owner = msg.sender;
    }


    // modifiers
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // receiver cannot be null or 0
    modifier toCannotBeZero(address _to) {
        require(_to != address(0), "Invalid address");
        _;
    }

    // sender cannot be null or 0
    modifier fromCannotBeZero(address _from) {
        require(_from != address(0), "Invalid address");
        _;
    }

    // caller is the owner
    modifier isTokenOwner(uint256 _tokenId, address _owner) {
        require(ticketsMetadata[_tokenId].owner == _owner, "Not the owner of the token");
        _;
    }

    // check if the sender is an approved operator for the token
    modifier checkApproval(address _from, address _to, uint256 _tokenId) {
        if(msg.sender != _from) {
            require( 
                msg.sender == owner || 
                operatorApprovalsForAll[ticketsMetadata[_tokenId].owner][msg.sender] == true || 
                operatorApprovals[_tokenId] == msg.sender ||
                approvedMinters[msg.sender]
            , "Caller is not approved to transfer this token");
        }
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(ticketsMetadata[_tokenId].owner != address(0), "Token does not exist");
        _;
    }

    // set the approved minter for this contract to create new tokens
    function setApprovedMinter(address _minter) external isOwner {
        approvedMinters[_minter] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == INTERFACE_ID_ERC721;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return ticketsMetadata[_tokenId].owner;
    }

    function getTicketPrice(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        return ticketsMetadata[_tokenId].ticketPrice;
    }

    function getTicketConcertId(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        return ticketsMetadata[_tokenId].concertId;
    }

    function getTicketURI(uint256 _tokenId) external view tokenExists(_tokenId) returns (string memory) {
        return ticketsMetadata[_tokenId].ticketURI;
    }

    function getPreviousOwner(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return ticketsMetadata[_tokenId].previousOwner;
    }

    function removeApproval(uint256 _tokenId) private {
        operatorApprovals[_tokenId] = address(0); 
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public 
            tokenExists(_tokenId) 
            isTokenOwner(_tokenId, _from) 
            toCannotBeZero(_to) 
            fromCannotBeZero(_from) 
            checkApproval(msg.sender, _to, _tokenId) 
            {
   
        ticketsMetadata[_tokenId].previousOwner = _from;
        ticketsMetadata[_tokenId].owner = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        removeApproval(_tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    // prevent extra data from being sent
    function safeTransferFrom(address _from , address _to, uint256 _tokenId, bytes calldata _data) external {
        require(_data.length == 0, "Data must be empty");
        safeTransferFrom(_from, _to, _tokenId);
    }

    // delgates extra data to empty bytes
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId);
    }

    // approve the transcation
    function approve(address _approved, uint256 _tokenId) external tokenExists(_tokenId) {
        //The caller must own the token or be an approved operator.
        require (msg.sender == owner || operatorApprovalsForAll[ticketsMetadata[_tokenId].owner][msg.sender] == true, "Caller is not approved to approve this token"); 
        operatorApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    // set approval for all 
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

    // mint a new ticket
    function mint(address _to, uint256 _concertId, uint256 _ticketPrice, string calldata _ticketURI, address _artist ) external returns (uint256) {
        require(msg.sender == owner || approvedMinters[msg.sender], "Caller is not the owner or approved");
        ticketsMetadata[ticketId] = Metadata(_concertId, _ticketPrice, _ticketURI, _to, address(0), _artist);
        balances[_to] += 1;
        ticketId += 1;
        emit Transfer(address(0), _to, ticketId);

        return ticketId-1;
    }

    // get the total number of attendees for a concert
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

    function useTicket(uint256 _ticketId) external tokenExists(_ticketId) isTokenOwner(_ticketId,tx.origin) {
        require(!usedTickets[ticketId], "Ticket already used");
        usedTickets[ticketId] = true;
    }

    function getArtist(uint256 _ticketId) external view tokenExists(_ticketId) returns (address) {
        return ticketsMetadata[_ticketId].artist;
    }

}