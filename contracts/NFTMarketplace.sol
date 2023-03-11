// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//INTERNAL IMPORT FOR NFT OPENZEPPELIN
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is
    ERC721URIStorage // Inheriting from ERC721URIStorage
{
    using Counters for Counters.Counter; // to use contract of Counter

    //Variable declaration
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    uint256 listingPrice = 0.0015 ether; // initial fees

    // whoever deploys this smart contract becomes the owner
    address payable owner; // making payable so that it can recieve funds

    mapping(uint256 => MarketItem) private idToMarketItem;
    // so every nft has unique id, and we are mapping that id to the struc that holds details about that paricular id

    struct MarketItem {
        // holds details regarding each nft
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // whenever any function (buying or selling happens we need to trigger some event)
    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // to setup owner supreme access (Security)
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only owner of the marketplace can change the listing price"
        );
        _;
    }

    // constructor of ERC721
    constructor() ERC721("MFT Metaverse Token", "MYNFT") {
        // eVERY nft must have a name and symbol respectively
        owner == payable(msg.sender); // signifies that whosoever deploys this becomes the owner
    }

    // To update prices of NFTs
    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        require(
            owner == msg.sender,
            "only owner of the marketplace can change the listing price"
        );
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice; // making it public so that anyone can get the price
    }

    // Let create "Create NFT Token function"

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        // all these below functiosn are from openzeppelin
        _tokenIds.increment(); // whenever someone creates a new token, tokenId gets incemented

        uint256 newTokenId = _tokenIds.current(); // assigns the incemented tokenId to new tokenId
        _mint(msg.sender, newTokenId); // now associating this id with the nft
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }
}
