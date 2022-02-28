//SPDX-License-Identifier: Zevo-Corporation
pragma solidity 0.7.6; 
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Xtoken is ERC721("CCrypto","C$C"),Ownable{
   
    address private admin;
    
    mapping(string => uint8)public counterfeit;
    
    event mintedNFT(address _user,uint256 _tokenId);

    event mintedNFTBatch(address[] _user,uint256[] _tokenId);
    
    mapping(address => uint256[])createdNFT;
    
    
    function createNFT(address _to,string memory _file,string memory _metadata)public returns(uint256){
        require(_to != address(0),"Use valid address");
        require(counterfeit[_file] != uint256(1),"Try different file");
        uint256 tokenId = this.totalSupply();
        
        createdNFT[msg.sender].push(tokenId);
        
        counterfeit[_file] = 1;
        _mint(_to,tokenId);
        _setTokenURI(tokenId,_metadata);
        emit mintedNFT(_to,tokenId);
        return tokenId;
    }
    function createNFTBatch(address[] memory _to,string[] memory _file,string[] memory _metadata) public returns(uint256[]){
        require(_to != address(0),"Use Valid Address");
        require(_to.length == _file.length && _metadata.length == _file.length,'Check entered parameters');

        uint256[] memory minted = new uint256[];
        for(uint256 i = 0;i<_to.length;i++){
            require(counterfeit[_file[i]] == 1,"already uploaded",i);
            uint256 tokenId = this.totalSupply();

            createdNFT[msg.sender].push(tokenId);
            counterfeit[_file[i]] = 1;
            _mint(_to[i],tokenId);
            _setTokenURI(tokenId, _metadata[i]); 
            minted.push(tokenId);
        }
        emit mintedNFT(_to,minted);
        return minted;
    }
     function createdNFTList(address _user)public view returns(uint256[] memory List){
         List = createdNFT[_user];
     }
}