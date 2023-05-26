// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC20Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DropTheNews is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private tokenId;

    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1; // cUSD token contract address

    struct News {
        address payable owner;
        string title;
        string description;
        uint256 likes;
        uint256 tips;
    }

    struct Claimer {
        bool isEligible;
        bool isClaimed;
    }

    mapping(uint256 => News) internal postedNews;
    mapping(uint256 => mapping(address => bool)) public likers;
    mapping(address => Claimer) internal claimers;
    mapping(address => uint256) public claimedNFTs;

    event NewsPosted(address indexed poster, string title, string description);
    event NewsDeleted(address indexed deleter, uint256 indexed index);
    event NewsLiked(uint256 indexed index, address indexed liker);
    event NewsDisliked(uint256 indexed index, address indexed disliker);
    event CreatorTipped(uint256 indexed index, address indexed tipper, uint256 amount);
    event NFTClaimed(address indexed claimer, uint256 tokenId, string tokenURI);

    constructor() ERC721("Proof of Tips", "POT") {}

    function postNews(string calldata _title, string calldata _description) public {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");

        for (uint256 i = 0; i < tokenId.current(); i++) {
            require(keccak256(bytes(postedNews[i].title)) != keccak256(bytes(_title)), "News with the same title already exists.");
        }

        News storage news = postedNews[tokenId.current()];
        news.owner = payable(msg.sender);
        news.title = _title;
        news.description = _description;

        _safeMint(msg.sender, tokenId.current());
        tokenId.increment();

        emit NewsPosted(msg.sender, _title, _description);
    }

    function deleteNews(uint256 _index) public {
        require(_index < tokenId.current(), "Invalid news article index");
        require(ownerOf(_index) == msg.sender, "Only news creator can delete news");

        _burn(_index);
        delete postedNews[_index];

        emit NewsDeleted(msg.sender, _index);
    }

    function getNews(uint256 _index) public view returns (address payable, string memory, string memory, uint256, uint256) {
        require(_index < tokenId.current(), "Invalid news article index");

        News memory news = postedNews[_index];
        return (news.owner, news.title, news.description, news.likes, news.tips);
    }

    function likeAndDislikeNews(uint256 _index) public {
        require(_index < tokenId.current(), "Invalid news article index");

        News storage news = postedNews[_index];
        bool liked = likers[_index][msg.sender];
        if (liked)
