pragma solidity ^0.5.0;

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC165} from "../interfaces/IERC165.sol";

contract Supporter is IERC721, IERC165 {
    
    // Struct for supportersMetadata
    struct Metadata {
        uint256 concertId;
        string tokenURI;
        address owner;
        address previousOwner;
        address artist;
        bool transferrable;
    }

    // Contract-level state variables
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    address public owner;
    uint256 public tokenId;


    // Storage Memory
    mapping(address=> mapping (address => bool)) private operatorApprovalsForAll;
    mapping(uint256 => address) private operatorApprovals;
    mapping(uint256 => Metadata) public supportersMetadata;
    mapping(address => bool) public approvedMinters;
    // Keep Track of the total number of Token a user has
    mapping(address => uint256) private balances;


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

    // reciever cannt be null or 0
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
        require(supportersMetadata[_tokenId].owner == _owner, "Not the owner of the token");
        _;
    }

    // check if the sender is an approved operator for the token
    modifier checkApproval(address _from, address _to, uint256 _tokenId) {
        if(msg.sender != _from) {
            require( msg.sender == owner || operatorApprovalsForAll[supportersMetadata[_tokenId].owner][msg.sender] == true || operatorApprovals[_tokenId] == msg.sender || approvedMinters[msg.sender], "Caller is not approved to transfer this token");
        }
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(supportersMetadata[_tokenId].owner != address(0), "Token does not exist");
        _;
    }

    modifier isTransferrable(uint256 _tokenId) {
        require(supportersMetadata[_tokenId].transferrable == true, "Token is not transferrable");
        _;
    }

    function setApprovedMinter(address _minter) external isOwner {
        approvedMinters[_minter] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return 
        interfaceId == INTERFACE_ID_ERC721;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return supportersMetadata[_tokenId].owner;
    }

    function getPreviousOwner(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return supportersMetadata[_tokenId].previousOwner;
    }


    function removeApproval(uint256 _tokenId) private {
        operatorApprovals[_tokenId] = address(0); 
    }

    function updateTokenOwner(uint256 _tokenId, address _to, address _from) private {
        supportersMetadata[_tokenId].previousOwner = _from;
        supportersMetadata[_tokenId].owner = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public 
        isTransferrable(_tokenId) 
        toCannotBeZero(_to) 
        fromCannotBeZero(_from) 
        tokenExists(_tokenId) i
        sTokenOwner(_tokenId, _from) 
        checkApproval(msg.sender, _to, _tokenId) {
            updateTokenOwner(_tokenId, _to, _from);
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
        require (msg.sender == owner || operatorApprovalsForAll[supportersMetadata[_tokenId].owner][msg.sender] == true, "Caller is not approved to approve this token"); 
        operatorApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    // set approval for all 
    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != address(0), "Operator address cannot be zero"); 
        operatorApprovalsForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(owner, _operator, _approved);
    }

    // get the total number of token minted for the concert
    function getSuppoterForConcert(uint256 _concertId) external view returns (address[] memory) {
        address[] memory supporters = new address[](tokenId);
        for(uint256 i = 0; i < tokenId; i++) {
            if(supportersMetadata[i].concertId == _concertId) {
                supporters[i] = supportersMetadata[i].owner;
            }
        }
        return supporters;
    }

    //Returns the Account approved for TokenId
    function getApproved(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return operatorApprovals[_tokenId];
    } 

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovalsForAll[_owner][_operator];
    }

    function setTransferrable(uint256 _tokenId, bool _transferrable) external tokenExists(_tokenId)  {
        require(msg.sender == supportersMetadata[_tokenId].owner || tx.origin == supportersMetadata[_tokenId].artist, "Caller is not the owner or artist of the token");
        supportersMetadata[_tokenId].transferrable = _transferrable;
    }

    // mint a new token 
    function mint(address _to, uint256 _concertId, string calldata _tokenURI, address _artist) external  returns (uint256) {
        require(msg.sender == owner || approvedMinters[msg.sender], "Caller is not the owner or approved");
        supportersMetadata[tokenId] = Metadata(_concertId, _tokenURI, _to, address(0), _artist, false);
        balances[_to] += 1;
        tokenId += 1;
        emit Transfer(address(0), _to, tokenId);

        return tokenId;
    }

    
}