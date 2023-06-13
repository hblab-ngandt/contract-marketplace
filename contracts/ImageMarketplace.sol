// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ImageMarketplace is Ownable, ERC721Holder {
    using SafeMath for uint256;

    uint256 private _marketItemIds;
    uint256 private _itemsSold;
    uint256 private _itemsCancelled;

    address public nftContract;
    IERC721 public nft;

    struct MarketItem {
        uint256 marketItemId;
        uint256 tokenId;
        address nftContract;
        address seller;
        address owner;
        uint256 price;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event ListImageNFT(
        uint256 indexed marketItemId,
        uint256 indexed tokenId,
        address indexed nftContract,
        uint256 price,
        address seller,
        address owner
    );

    event CancelListImageNFT(uint256 indexed marketItemId, address nftContract);

    event BuyImageNFT(
        uint256 indexed marketItemId,
        uint256 indexed tokenId,
        address indexed nftContract,
        address seller,
        address owner,
        uint256 price
    );

    function setNftContract(address _nftContract) public {
        require(_nftContract != address(0), "Invalid nft contract address");
        nftContract = _nftContract;
        nft = IERC721(_nftContract);
    }

// List ImageNFT on marketplace
    function listImageNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public returns (uint256){
        // Verify
        require(_price > 0, "Price must be at least 1 wei");
        require(
            nft.ownerOf(_tokenId) == msg.sender, "You do not own this token"
        );
        require(nft.ownerOf(_tokenId) != address(this) , "This token has already been listed");

        _marketItemIds++;
        uint256 marketItemId = _marketItemIds;

        idToMarketItem[marketItemId] = MarketItem(
            marketItemId,
            _tokenId,
            _nftContract,
            payable(msg.sender),
            payable(address(this)),
            _price
        );

        // Transfer NFT to marketplace
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Emit event
        emit ListImageNFT(
            marketItemId,
            _tokenId,
            _nftContract,
            _price,
            payable(msg.sender),
            payable(address(this))
        );

        return marketItemId;
    }

// Cancel sell Image NFT
    function cancelListImageNFT(uint256 marketItemId) public {
        // Verify
        require(idToMarketItem[marketItemId].seller == msg.sender, "You do not own this NFT");
        require(idToMarketItem[marketItemId].price > 0, "Invalid NFT");

        // Transfer
        nft.safeTransferFrom(address(this), msg.sender, idToMarketItem[marketItemId].tokenId);

        delete idToMarketItem[marketItemId];

        // Emit
        emit CancelListImageNFT(marketItemId, nftContract);

        _itemsCancelled++;
    }

// Buy ImageNFT
    function buyImageNFT(uint256 marketItemId) public payable {
        MarketItem storage item = idToMarketItem[marketItemId];
        require(item.seller != msg.sender, "Buyer cannot be seller");

        // Transfer NFT to buyer
        nft.safeTransferFrom(address(this), msg.sender, item.tokenId);
        item.owner = payable(msg.sender);

        // Transfer money to seller
        require(msg.value >= item.price, "not submit price");
        payable(item.seller).transfer(msg.value);  // withdraw from contract to seller 

        emit BuyImageNFT(
            item.marketItemId,
            item.tokenId,
            nftContract,
            item.seller,
            msg.sender,
            item.price
        );
    }
}