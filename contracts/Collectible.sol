pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Collectible is IERC721 {
    
    struct Metadata {
        uint256 tokenId;
        string tokenURI;
        address owner;
        address previousOwner;
        address artist;
    }

    address public owner;
    uint256 public tokenId;

    mapping(address=> mapping (address => bool)) private operatorApprovalsForAll;
    mapping(uint256 => address) private operatorApprovals;

    // storage of collectibles
    mapping(uint256 => Metadata) public collectiblesMetadata;

    // Keep Track of the total number of tokens a user has
    mapping(address => uint256) private balances;

    // Events from IERC721
    /*
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    */

    // Constructor
    constructor() public {
        owner = msg.sender;
    }

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
        require(collectiblesMetadata[_tokenId].owner == _owner, "Not the owner of the token");
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

    // check if sender is the contract owner or owner of collectible or have approval for all 
    modifier checkApproval(address _from, address _to, uint256 _tokenId) {
        if(msg.sender != _from) {
            require( 
                msg.sender == owner || 
                operatorApprovalsForAll[collectiblesMetadata[_tokenId].owner][msg.sender] == true || 
                operatorApprovals[_tokenId] == msg.sender
            , "Caller is not approved to transfer this token");
        }
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(collectiblesMetadata[_tokenId].owner != address(0), "Token does not exist");
        _;
    }


    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return collectiblesMetadata[_tokenId].owner;
    }

    function removeApproval(uint256 _tokenId) private {
        operatorApprovals[_tokenId] = address(0); 
    }

    function updateTokenOwner(uint256 _tokenId, address _to) private {
        collectiblesMetadata[_tokenId].previousOwner = collectiblesMetadata[_tokenId].owner;
        collectiblesMetadata[_tokenId].owner = _to;
        balances[collectiblesMetadata[_tokenId].previousOwner ] -= 1;
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
        require (msg.sender == owner || operatorApprovalsForAll[collectiblesMetadata[_tokenId].owner][msg.sender] == true, "Caller is not approved to approve this token"); 
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


    function mint(address _to, string calldata _tokenURI, address _artist) external isOwner() {
        collectiblesMetadata[tokenId] = Metadata(tokenId, _tokenURI, _to, address(0), _artist);
        balances[_to] += 1;
        tokenId += 1;
        emit Transfer(address(0), _to, tokenId);
    }

    
}