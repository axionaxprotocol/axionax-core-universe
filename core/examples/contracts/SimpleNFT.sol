// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleNFT
 * @dev Basic ERC-721 NFT Implementation for AxionAX Testnet
 * @notice Example NFT contract with metadata support
 */
contract SimpleNFT {
    string public name;
    string public symbol;
    uint256 private _tokenIdCounter;
    
    // Token ID => Owner
    mapping(uint256 => address) private _owners;
    
    // Owner => Token count
    mapping(address => uint256) private _balances;
    
    // Token ID => Approved address
    mapping(uint256 => address) private _tokenApprovals;
    
    // Owner => Operator => Approved
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Token ID => Metadata URI
    mapping(uint256 => string) private _tokenURIs;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Minted(address indexed to, uint256 indexed tokenId, string tokenURI);
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _tokenIdCounter = 1; // Start from 1
    }
    
    /**
     * @dev Returns the number of tokens owned by an address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Query for zero address");
        return _balances[owner];
    }
    
    /**
     * @dev Returns the owner of a token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    /**
     * @dev Returns the metadata URI for a token
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenURIs[tokenId];
    }
    
    /**
     * @dev Mint a new NFT with metadata
     * @param to The address to receive the NFT
     * @param uri Metadata URI (IPFS hash, HTTP URL, etc.)
     */
    function mint(address to, string memory uri) public returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");
        
        uint256 tokenId = _tokenIdCounter++;
        
        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;
        
        emit Transfer(address(0), to, tokenId);
        emit Minted(to, tokenId, uri);
        
        return tokenId;
    }
    
    /**
     * @dev Transfer NFT from one address to another
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(ownerOf(tokenId) == from, "From address is not owner");
        require(to != address(0), "Cannot transfer to zero address");
        
        // Clear approvals
        _approve(address(0), tokenId);
        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @dev Safe transfer with data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
    }
    
    /**
     * @dev Approve an address to transfer a specific token
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "Cannot approve to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");
        
        _approve(to, tokenId);
    }
    
    /**
     * @dev Get the approved address for a token
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenApprovals[tokenId];
    }
    
    /**
     * @dev Approve or remove operator for all tokens
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Cannot approve to self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /**
     * @dev Check if an address is an approved operator
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    /**
     * @dev Burn an NFT
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        
        address owner = ownerOf(tokenId);
        
        _approve(address(0), tokenId);
        
        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        
        emit Transfer(owner, address(0), tokenId);
    }
    
    /**
     * @dev Get total number of minted tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter - 1;
    }
    
    // Internal functions
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
}
