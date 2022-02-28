//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";



contract Auction is IERC721Receiver{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    
    IERC721 public TokenX;
    
     mapping(address => conductedAuctionList)conductedAuction;
     
     mapping(address => mapping(uint256 =>uint256))participatedAuction;
     
     mapping(address => histo)history;
     
     mapping(address => uint256[])collectedArts;
     
     struct histo{
        uint256[] list;
     }
     
     struct conductedAuctionList{
        uint256[] list;
     }
     
    //mapping(uint256 => auction)auctiondetails;
    
    //mapping(address => mapping(uint256 => uint256))biddersdetails;
    
    uint256 public auctionTime = uint256(5 days);   
    
    Counters.Counter private totalAuctionId;
    
    enum auctionStatus { ACTIVE, OVER }
    
    auction[] internal auctions;
    
    EnumerableSet.UintSet TokenIds;
    
    
    //bidder[] internal bidders;
    
    address payable market;
    
    uint256 marketFeePercent = 2 ;
    
    
    
    struct auction{
        uint256 auctionId;
        uint256 start;
        uint256 end;
        uint256 tokenId;
        address auctioner;
        address highestBidder;
        uint256 highestBid;
        address[] prevBid;
        uint256[] prevBidAmounts;
        auctionStatus status;
    }
 
    constructor(IERC721 _tokenx){
        TokenX = _tokenx;
       
    }
    
    
    
    function createSaleAuction(uint256 _tokenId,uint256 _price)public returns(uint256){
	    require(TokenX.ownerOf(_tokenId) == msg.sender,"Auction your NFT");
	    
	    auction memory _auction = auction({
	    auctionId : totalAuctionId.current(),
        start: block.timestamp,
        end : block.timestamp.add(auctionTime),
        tokenId: _tokenId,
        auctioner: msg.sender,
        highestBidder: msg.sender,
        highestBid: _price,
        prevBid : new address[](0),
        prevBidAmounts : new uint256[](0),
        status: auctionStatus.ACTIVE
	    });
	    
	    conductedAuctionList storage list = conductedAuction[msg.sender];
	    list.list.push(totalAuctionId.current());
	    auctions.push(_auction);
	    TokenX.safeTransferFrom(address(msg.sender),address(this),_tokenId);
	    
	    totalAuctionId.increment();
	    return uint256(totalAuctionId.current());
    }
    
    function placeBid(uint256 _auctionId)public payable returns(bool){
        require(auctions[_auctionId].highestBid < msg.value,"Place a higher Bid");
        require(auctions[_auctionId].auctioner != msg.sender,"Not allowed");
        require(auctions[_auctionId].end > block.timestamp,"Auction Finished");
       
        auction storage auction = auctions[_auctionId];
        auction.prevBid.push(auction.highestBidder);
        auction.prevBidAmounts.push(auction.highestBid);
        if(participatedAuction[auction.highestBidder][_auctionId] > 0){
        participatedAuction[auction.highestBidder][_auctionId] = participatedAuction[auction.highestBidder][_auctionId].add(auction.highestBid); 
        }else{
            participatedAuction[auction.highestBidder][_auctionId] = auction.highestBid;
        }
        
        histo storage history = history[msg.sender];
        history.list.push(_auctionId);
        
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        return true;
    }
    
    function finishAuction(uint256 _auctionId) public{
        require(auctions[_auctionId].auctioner == msg.sender,"only auctioner");
        require(uint256(auctions[_auctionId].end) >= uint256(block.number),"already Finshed");
        
        auction storage auction = auctions[_auctionId];
        auction.end = uint32(block.number);
        auction.status = auctionStatus.OVER;
        
        uint256 marketFee = auction.highestBid.mul(marketFeePercent).div(100);
        
        if(auction.prevBid.length > 0){
            
        for(uint256 i = 1; i < auction.prevBid.length; i++){
            if(participatedAuction[auctions[_auctionId].prevBid[i]][_auctionId] == auctions[_auctionId].prevBidAmounts[i] ){
            address payable give = payable(auctions[_auctionId].prevBid[i]);
            uint256 repay = auctions[_auctionId].prevBidAmounts[i];
            give.transfer(repay); 
            }
        }
        collectedArts[auctions[_auctionId].highestBidder].push(auctions[_auctionId].tokenId);
        msg.sender.transfer(auctions[_auctionId].highestBid.sub(marketFee));
        market.transfer(marketFee);
        TokenX.safeTransferFrom(address(this),auctions[_auctionId].highestBidder,auctions[_auctionId].tokenId);
    }
    
    }
    
    function auctionStatusCheck(uint256 _auctionId)public view returns(bool){
        if(auctions[_auctionId].end > block.timestamp){
            return true;
        }else{
            return false;
        }
    }
    
    function auctionInfo(uint256 _auctionId)public view returns( uint256 auctionId,
        uint256 start,
        uint256 end,
        uint256 tokenId,
        address auctioner,
        address highestBidder,
        uint256 highestBid,
        uint256 status){
            
            auction storage auction = auctions[_auctionId];
            auctionId = _auctionId;
            start = auction.start;
            end =auction.end;
            tokenId = auction.tokenId;
            auctioner = auction.auctioner;
            highestBidder = auction.highestBidder;
            highestBid = auction.highestBid;
            status = uint256(auction.status);
        }
        
    function bidHistory(uint256 _auctionId) public view returns(address[]memory,uint256[]memory){
            return (auctions[_auctionId].prevBid,auctions[_auctionId].prevBidAmounts);
        }
        
    function participatedAuctions(address _user) public view returns(uint256[]memory){
        
        return history[_user].list;
           
    }
    
    
    function onERC721Received(address _operator,address _from,uint256 _tokenId,bytes calldata _data)
    external
    override
    returns(bytes4)
    {
    require(msg.sender == address(TokenX), "received from unauthenticated contract" );
    TokenIds.add(_tokenId);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    function totalAuction() public view returns(uint256){
       return auctions.length;
    }
    
    function conductedAuctions(address _user)public view returns(uint256[]memory){
        return conductedAuction[_user].list;
    }
    
    function collectedArtsList(address _user)public view returns(uint256[] memory){
        return collectedArts[_user];
    }
}