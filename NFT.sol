// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./DefaultOperatorFilterer.sol";

contract NFT is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    struct Album {
        uint256 price;
        string title;
        string artist;
        string img;
        uint256 songs;
        uint256 video;
        uint256 art;
        string desc;
    }

    mapping (uint256 => uint256) public _nftAllowsAlbum;

    mapping (uint256 => string[]) public _songsToNames;

    Album[] public _album;

    uint public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_MINT_PER_TX = 10;

    uint256 public totalAlbums = 0;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("NFT Name", "SYMBOL") {
        baseUri = "ipfs://bafybeiab2vjsz252unl7uk3tu4zufoyhzmldxkozylyqrebcfhrynlo744/";
    }

    // Public Functions
    function mint(uint256 _id) external payable {
        require(isSaleActive, "The sale is paused.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + 1 <= MAX_TOKENS, "Exceeds total supply.");
        require(msg.value == _album[_id].price, "Wrong amount sent");
        
            _safeMint(msg.sender, curTotalSupply + 1);

        _nftAllowsAlbum[curTotalSupply + 1] = _id;
        mintedPerWallet[msg.sender] += 1;
        totalSupply += 1;
    }

    function addAlbum(uint256 _price, string memory _title, string memory _artist, string memory _img, uint256 _songs, uint256 _video, uint256 _art, string memory _desc ) public onlyOwner {
        _album.push(Album(_price, _title, _artist, _img, _songs, _video, _art, _desc));
        totalAlbums += 1;
    }

    function setSongName(string[] memory _names, uint256 _albumID) public onlyOwner {
        require(_albumID < totalAlbums, "Wrong Album ID!");
        require(_names.length == _album[_albumID].songs, "Invalid Names amount sent!");
        for(uint256 i = 0; i < _names.length; i++) {
            _songsToNames[_albumID] = _names;
        }
    }

    function getAlbums() public view returns (Album[] memory) {
        return _album;
    }

    function getNames(uint256 _albumID) public view returns(string[] memory) {
        return _songsToNames[_albumID];
    }

    function canAccess(uint256 _albumID) public view returns (bool){
        uint256 balance = balanceOf(_msgSender());
        require(balance > 0, "You do not have any NFT");
        bool canA;
        for(uint256 i = 1; i < totalSupply + 1; i++){
            if(ownerOf(i) == _msgSender()) {
                if(_nftAllowsAlbum[i] == _albumID) {
                    canA = true;
                }
              
                }
            }
            return canA;
        
    }

    // Owner-only functions
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }
	
	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance * 70 / 100;
        uint256 balanceTwo = balance * 30 / 100;
        ( bool transferOne, ) = payable(0x7ceB3cAf7cA83D837F9d04c59f41a92c1dC71C7d).call{value: balanceOne}("");
        ( bool transferTwo, ) = payable(0x7ceB3cAf7cA83D837F9d04c59f41a92c1dC71C7d).call{value: balanceTwo}("");
        require(transferOne && transferTwo, "Transfer failed.");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}