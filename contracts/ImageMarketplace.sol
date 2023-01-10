// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ImageMarketplace is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _marketItemIds;
    CountersUpgradeable.Counter public _itemsSold;
    CountersUpgradeable.Counter public _itemsCancelled;

    mapping(address => bool) public whitelistNFT;

    address public nftContract;
    IERC721Upgradeable public nft;

    uint256 private listingFee;
    uint256 private cap;

    struct MarketItem {
        uint256 marketItemId;
        uint256 tokenId;
        address nftContract;
        address seller;
        address owner;
        uint256 price;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        listingFee = 0.045 ether;
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function setNftContract(address _nftContract) public onlyOwner {
        require(_nftContract != address(0), "Invalid nft contract address");
        nftContract = _nftContract;
        nft = IERC721Upgradeable(_nftContract);
    }

    // List ImageNFT on marketplace
    function listImageNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public nonReentrant returns (uint256){
        // Verify
        require(_price > 0, "Price must be at least 1 wei");
        require(
            nft.ownerOf(_tokenId) == msg.sender, "You do not own this token"
        );
        require(
            !(idToMarketItem[_tokenId].price > 0), "This NFT has already been listed"
        );
        require(!whitelistNFT[msg.sender], "Invalid NFT contract address");

        _marketItemIds.increment();
        uint256 marketItemId = _marketItemIds.current();

        idToMarketItem[marketItemId] = MarketItem(
            marketItemId,
            _tokenId,
            _nftContract,
            payable(msg.sender),
            payable(address(this)),
            _price
        );

        // Transfer NFT to marketplace
        nft.transferFrom(msg.sender, address(this), _tokenId);

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
        nft.transferFrom(address(this), msg.sender, idToMarketItem[marketItemId].tokenId);

        delete idToMarketItem[marketItemId];

        // Emit
        emit CancelListImageNFT(marketItemId, nftContract);

        _itemsCancelled.increment();
    }

    // Buy ImageNFT
    function buyImageNFT(uint256 marketItemId)
        public nonReentrant payable
    {
        MarketItem storage item = idToMarketItem[marketItemId];
        require(item.seller != msg.sender, "Buyer cannot be seller");
        
        // Transfer NFT to buyer
        nft.transferFrom(address(this), msg.sender, item.tokenId);
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

        _itemsSold.increment();

        // Delete NFT on marketplace after buying
        delete idToMarketItem[marketItemId];
    }

    // function withdraw() external {
    //     // transfer this contract's whole BNB balance to the `0x123` address
    //     payable(address(0x123)).transfer(address(this).balance);
    // }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
