// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

// TODO: Handle Chainlink Oracle to Verify the Green Report (using a Mock first)

contract NFTMarketplace is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    mapping(uint256 => uint256) private _tokenSalePrice;
    mapping(uint256 => bool) private _isTokenForSale;
    // Keep track of active tokens
    uint256[] private activeTokenIds;

    uint256 private constant COMMISSION_RATE = 10; // 10% commission
    address private _commissionReceiver; // Contract owner

    // Mapping from owner address to list of owned token IDs
    // mapping(address => uint256[]) private _ownedTokens;

    // // Mapping from token ID to index of the owner tokens list
    // mapping(uint256 => uint256) private _ownedTokensIndex;

    event TokenMinted(
        address indexed recipient,
        uint256 indexed tokenId,
        string tokenURI
    );
    event TokenListedForSale(uint256 indexed tokenId, uint256 salePrice);
    event TokenSaleWithdrawn(uint256 indexed tokenId);
    event TokenSold(uint256 indexed tokenId, address buyer, uint256 salePrice);
    event TokenBurned(uint256 indexed tokenId);

    constructor(
        address initialOwner
    ) ERC721("EnvironmentalCredit", "ECR") Ownable(initialOwner) {
        _commissionReceiver = msg.sender; // Contract deployer
        _tokenIdCounter = 0; // Explicit initialization for clarity
    }

    function _increaseBalance(
        address to,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(to, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        // Call the _update function from the base contract
        // with the correct parameters that were passed to this function.
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Override function to return the token URI
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Function to mint a new token with the option to list it for sale
    function safeMint(
        address recipient,
        string memory metadataURI,
        bool isListed,
        uint256 salePrice
    ) public /* onlyOwner */ {
        _safeMintWithListing(recipient, metadataURI, isListed, salePrice);
    }

    // Function to get all tokens owned by a specific address
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory, string[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return (new uint256[](0), new string[](0));
        } else {
            uint256[] memory tokens = new uint256[](tokenCount);
            string[] memory uris = new string[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, i);
                tokens[i] = tokenId;
                uris[i] = tokenURI(tokenId); // Make sure to pass the tokenId to the tokenURI function
            }
            return (tokens, uris);
        }
    }

    // Internal function that handles the minting logic
    function _safeMintWithListing(
        address recipient,
        string memory metadataURI,
        bool isListed,
        uint256 salePrice
    ) internal {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, metadataURI);
        activeTokenIds.push(tokenId);

        if (isListed) {
            _isTokenForSale[tokenId] = true;
            _tokenSalePrice[tokenId] = salePrice;
        }

        emit TokenMinted(recipient, tokenId, metadataURI);
    }

    function burn(uint256 tokenId) public onlyOwner {
        super._burn(tokenId);
        removeTokenId(tokenId);
        emit TokenBurned(tokenId);
    }

    function removeTokenId(uint256 tokenId) internal {
        for (uint256 i = 0; i < activeTokenIds.length; i++) {
            if (activeTokenIds[i] == tokenId) {
                activeTokenIds[i] = activeTokenIds[activeTokenIds.length - 1];
                activeTokenIds.pop();
                break;
            }
        }
    }

    function getTokenSalePrice(uint256 tokenId) public view returns (uint256) {
        require(_isTokenForSale[tokenId], "Token is not for sale");
        return _tokenSalePrice[tokenId];
    }

    // Get All the Tokens to be sold
    function getAllListedTokens()
        public
        view
        returns (uint256[] memory, string[] memory, uint256[] memory)
    {
        uint256 totalActive = activeTokenIds.length;
        uint256 totalListed = 0;
        for (uint256 i = 0; i < totalActive; i++) {
            if (_isTokenForSale[activeTokenIds[i]]) {
                totalListed++;
            }
        }

        uint256[] memory ids = new uint256[](totalListed);
        string[] memory uris = new string[](totalListed);
        uint256[] memory prices = new uint256[](totalListed);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalActive; i++) {
            uint256 tokenId = activeTokenIds[i];
            if (_isTokenForSale[tokenId]) {
                ids[currentIndex] = tokenId;
                uris[currentIndex] = tokenURI(tokenId);
                prices[currentIndex] = _tokenSalePrice[tokenId];
                currentIndex++;
            }
        }

        return (ids, uris, prices);
    }

    // Function to list a token for sale
    // function putTokenForSale(uint256 tokenId, uint256 salePrice) public {
    //     require(
    //         ownerOf(tokenId) == msg.sender,
    //         "Only token owner can put it for sale"
    //     );
    //     _isTokenForSale[tokenId] = true;
    //     _tokenSalePrice[tokenId] = salePrice;

    //     emit TokenListedForSale(tokenId, salePrice);
    // }

    // Function to remove a token from sale
    // function removeTokenFromSale(uint256 tokenId) public {
    //     require(
    //         ownerOf(tokenId) == msg.sender,
    //         "Only token owner can remove it from sale"
    //     );
    //     _isTokenForSale[tokenId] = false;

    //     emit TokenSaleWithdrawn(tokenId);
    // }

    // Function to buy and burn a token (Burn temporarily removed)
    function buyCredit(uint256 tokenId) public payable {
        require(_isTokenForSale[tokenId], "Token must be for sale");
        uint256 salePrice = _tokenSalePrice[tokenId];
        require(msg.value >= salePrice, "Insufficient funds sent");

        uint256 commission = (salePrice * COMMISSION_RATE) / 100;
        uint256 sellerProceeds = salePrice - commission;

        // Transfer commission and seller proceeds
        payable(_commissionReceiver).transfer(commission);
        payable(ownerOf(tokenId)).transfer(sellerProceeds);

        // Transfer the token to the buyer and then burn it
        _transfer(ownerOf(tokenId), msg.sender, tokenId);
        // _burn(tokenId); // Burn the token to remove it from circulation
        // emit TokenBurned(tokenId); // Emit an event for burning the token

        _isTokenForSale[tokenId] = false;

        emit TokenSold(tokenId, msg.sender, salePrice);
    }
}
