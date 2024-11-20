pragma solidity ^0.5.0;

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {Collectible} from "./Collectible.sol";

contract ComposableCollectible is IERC721, IERC165 {
    
    struct Metadata {
        address owner;
        address previousOwner;
        address artist;
        uint256[] composableTokens;
    }
    
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    Collectible public collectibleContract;

    address public owner;
    
    uint256 public tokenId;
    
    mapping(uint256 => uint256 ) public tokenIdToComposableIndex;
    mapping(uint256 => uint256) public tokenIdToComposableTokenId;
    mapping(address => mapping (address => bool)) private operatorApprovalsForAll;
    mapping(uint256 => address) private operatorApprovals;

    // storage of ComposableCollectibles
    mapping(uint256 => Metadata) public composableCollectiblesMetadata;
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
        require(composableCollectiblesMetadata[_tokenId].owner == _owner, "Not the owner of the token");
        _;
    }

    modifier isRootOwner(uint256 _tokenId, address _owner) {
        require(composableCollectiblesMetadata[tokenIdToComposableTokenId[_tokenId]].owner == _owner , "Token is not the root Owner");
        _;
    }

    // check if sender is the contract owner or owner of collectible or have approval for all 
    modifier checkApproval(address _from, address _to, uint256 _tokenId) {
        if(msg.sender != _from) {
            require( 
                msg.sender == owner || 
                operatorApprovalsForAll[composableCollectiblesMetadata[_tokenId].owner][msg.sender] == true || 
                operatorApprovals[_tokenId] == msg.sender
            , "Caller is not approved to transfer this token");
        }
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(composableCollectiblesMetadata[_tokenId].owner != address(0), "Token does not exist");
        _;
    }

    modifier isCollectibleContractAddressSet() {
        require(address(collectibleContract) != address(0), "Collectible contract address is not set");
        _;
    }

    function setCollectibleContract(address _collectibleAddress) external isOwner() {
        collectibleContract = Collectible(_collectibleAddress);
    }

    function parentOf(uint256 _collectibleTokenId) external view returns (uint256) {
        return tokenIdToComposableTokenId[_collectibleTokenId];
    }

    // Add to form Composable
    function transferToParent(uint256 _collectibleTokenId, uint256 _parentTokenId) external isCollectibleContractAddressSet() tokenExists(_parentTokenId) {
        require(collectibleContract.getPreviousOwner(_collectibleTokenId) == tx.origin, "Caller is not the owner of the token");
        require(collectibleContract.ownerOf(_collectibleTokenId) == address(this), "Token is not owned by the contract");  
        require(tokenIdToComposableTokenId[_collectibleTokenId] > 0, "Token is already a child");

        //Set Index
        tokenIdToComposableIndex[_collectibleTokenId] = composableCollectiblesMetadata[_parentTokenId].composableTokens.length + 1; // Because empty element returns 0 too
        //Set Parent
        tokenIdToComposableTokenId[_collectibleTokenId] = _parentTokenId;
        composableCollectiblesMetadata[_parentTokenId].composableTokens.push(_collectibleTokenId);
    }   

    // Remove from Composable
    function transferFromParent(uint256 _collectibleTokenId) external isCollectibleContractAddressSet() isRootOwner(_collectibleTokenId, tx.origin) {
        
        uint256 _parentTokenId = tokenIdToComposableTokenId[_collectibleTokenId];
        uint256 _index = tokenIdToComposableIndex[_collectibleTokenId]-1;
  
        //Remove from Parent
        delete tokenIdToComposableIndex[_collectibleTokenId];
        delete tokenIdToComposableTokenId[_collectibleTokenId];
        
        // Overwrite the element to be deleted with the last element
        uint256 lastIndex = composableCollectiblesMetadata[_parentTokenId].composableTokens.length - 1;
        if (_index != lastIndex) {
            // Move the last element to the index being removed
            uint256 lastToken = composableCollectiblesMetadata[_parentTokenId].composableTokens[lastIndex];
            composableCollectiblesMetadata[_parentTokenId].composableTokens[_index] = lastToken;
            tokenIdToComposableIndex[lastToken] = _index;
        }
        // Remove the last element
        composableCollectiblesMetadata[_parentTokenId].composableTokens.pop();
    }


    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == INTERFACE_ID_ERC721;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return composableCollectiblesMetadata[_tokenId].owner;
    }

    function removeApproval(uint256 _tokenId) private {
        operatorApprovals[_tokenId] = address(0); 
    }

    function updateTokenOwner(uint256 _tokenId, address _to) private {
        composableCollectiblesMetadata[_tokenId].previousOwner = composableCollectiblesMetadata[_tokenId].owner;
        composableCollectiblesMetadata[_tokenId].owner = _to;
        balances[composableCollectiblesMetadata[_tokenId].previousOwner ] -= 1;
        balances[_to] += 1;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public 
            toCannotBeZero(_to) 
            fromCannotBeZero(_from) 
            tokenExists(_tokenId) 
            isTokenOwner(_tokenId, _from) 
            checkApproval(msg.sender, _to, _tokenId) {
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
        require (msg.sender == owner || operatorApprovalsForAll[composableCollectiblesMetadata[_tokenId].owner][msg.sender] == true, "Caller is not approved to approve this token"); 
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


    function mint(address _to, address _artist) external isOwner() {
        composableCollectiblesMetadata[tokenId] = Metadata( _to, address(0), _artist, new uint256[](0));
        balances[_to] += 1;
        tokenId += 1;
        emit Transfer(address(0), _to, tokenId);
    }

    
}