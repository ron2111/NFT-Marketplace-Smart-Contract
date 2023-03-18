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

    mapping(uint256 => MarketItem) private idMarketItem;
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
        _mint(msg.sender, newTokenId); // now associating this id with the nft (internal function of openzeppelin)
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price); // to finally create the nft in the market
        return newTokenId;
    }

    // Creating market items
    function createMarketItem(uint256 tokenId, uint256 price) private {
        // private as we are calling it internally not externally
        require(price > 0, "Price must be at least 1 wei"); // checks
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        // mapping the token with MarketItem struct to declare its properties ones it gets created
        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender), //seller
            payable(address(this)), //ownersmart contract deployer)
            price,
            false // sold status
        );
        // to transfer
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated( // calling event when tranfer happens(from creator to contract)
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    //FUNCTION FOR RESALE OF TAKEN
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "Only Item owner can peform this purchase"
        ); // only the owner should be allowed to resale
        require(msg.value == listingPrice, "Price must be >= to listing price");

        //If everything checks out then making the sale happen and changing the state of the token's properties
        idMarketItem[tokenId].sold = false; // sell status changed
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement(); // as sale is done
        _transfer(msg.sender, address(this), tokenId); // transfer of token
    }

    //FUNCTION FOR MARKET ITEM SALE

       function createMarketSale(uint256 tokenId) public payable{
        uint256 price = idMarketItem[tokenId].price;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        idMarketItem[tokenId].owner == payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));// new owner

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId); // tranfer of token to new owner

        payable(owner).transfer(listingPrice); // commision goes to us(contract owner)
        payable(idMarketItem[tokenId].seller).transfer(msg.value); // rest amount goes to seller

       }


       //FUNCTION FOR UNSOLD NFT DATA

       function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current(); // count of nfts
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current(); // unsold nfts
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount); // unsold items array

        // We need to fill the above declared array
        for(uint256 i = 0;i< itemCount; i++){
            if(idMarketItem[i+1].owner == address(this)){ // checks if owner is contract that means the nft is unsold
            uint256 currentId = i+1;

            MarketItem storage currentItem = idMarketItem[currentId]; // storage keyword used to store data persistently and consumes more gas other than memory keyword.
            items[currentIndex] = currentItem; // filling the array
            currentIndex +=1;

            }
        }
              return items;// finally returning the unsold nft array
       }

       // PURCHASE ITEM- TO GET DATA OF ALL THE BUYER'S OWNED NFT

    function fetchMyNFT() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalCount; i++){
        if(idMarketItem[i+1].owner == msg.sender){ // checking if the nft owner is the buyer we need data of
            itemCount+=1; // we just update the data
        }
    }
            MarketItem[] memory items = new MarketItem[](itemCount); 
            // same as above function
       for(uint256 i = 0;i< totalCount; i++){
           uint256 currentId = i+1;
           MarketItem storage currentItem = idMarketItem[currentId];
           items[currentIndex] = currentItem;
           currentIndex += 1;
            
        }
            return items;
    }


    // SINGLE USER ITEMS

    function fetchItemsListed() public view returns (MarketItem[] memory ){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;


      for(uint256 i = 0; i < totalCount; i++){
        if(idMarketItem[i+1].seller == msg.sender){  // if seller's address and the person who is calling this function is =
            itemCount+=1; 
        }
    }
            MarketItem[] memory items = new MarketItem[](itemCount); 
            // same as above function
       for(uint256 i = 0;i< totalCount; i++){
           uint256 currentId = i+1;
           MarketItem storage currentItem = idMarketItem[currentId];
           items[currentIndex] = currentItem;
           currentIndex += 1;
            
        }
    
            return items;

    }
}
