// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Patente
 * @dev Possibilita a compra e expiração de patentes
 */
contract Copyright {
    
    struct CopyrightHolder {
        address holder;
        uint256 creationDate;
        uint256 expirationDate;
        bool wasSold;
    }
    
    struct CopyrightStatus {
        string copyrightedTerm;
        CopyrightHolder currentHolder;
        CopyrightHolder[] previousHolders;
        bool forSale;
        uint256 price;
        address specificBuyer;
    }
    
    mapping(string => CopyrightStatus) private copyrights;
    
    function buyCopyright(string memory term, uint256 durationDays) public payable {
        address claimer = msg.sender;

        require(bytes(term).length > 0, "You must search a term!");
        require(msg.sender != copyrights[term].currentHolder.holder, "You already own this copyright!");
        copyrights[term].copyrightedTerm = term;
        
        if (copyrights[term].currentHolder.holder != address(0)) {
            if (isExpired(term)) {
                require(msg.value == 60 ether, "It costs 60 Ether to buy an expired copyright!");
            } else {
                require(copyrights[term].forSale, "The copyright has a current owner and is not for sale!");
            
                if (copyrights[term].specificBuyer != address(0)) {
                    require(copyrights[term].specificBuyer == msg.sender, "The copyright is for sale, but it has been reserved for another address!");
                }
            
                require(msg.value == copyrights[term].price, append3("This copyright is being sold for ", uint2str(copyrights[term].price), " Ether!"));
                
                copyrights[term].currentHolder.wasSold = true;
            }
            copyrights[term].previousHolders.push(copyrights[term].currentHolder);
        } else {
            require(msg.value == durationDays * 10**18, append3("It costs 1 Ether per day to buy a new copyright! (Current Price: ", uint2str(durationDays), " Ether)"));
        }
        
        // Copyright lasts 600 seconds
        copyrights[term].currentHolder = CopyrightHolder(claimer, block.timestamp, block.timestamp + (durationDays * 86400), false);
        
        // If the copyright was bought, resets the selling properties
        cancelSale(term);
    }
    
    function sellCopyright(string memory term, uint256 price) public payable {
        require(msg.sender == copyrights[term].currentHolder.holder, "You can't sell a copyright which isn't yours!");
        require(msg.value == 5 ether, "It costs 5 Ether to set up a sale for a copyright!");
        
        copyrights[term].forSale = true;
        copyrights[term].price = price;
        copyrights[term].specificBuyer = address(0);
    }
    
    function sellCopyrightToAddress(string memory term, uint256 price, address specificBuyer) public payable {
        require(msg.sender == copyrights[term].currentHolder.holder, "You can't sell a copyright which isn't yours!");
        require(msg.value == 5 ether, "It costs 5 Ether to set up a sale for a copyright!");
        
        copyrights[term].forSale = true;
        copyrights[term].price = price;
        copyrights[term].specificBuyer = specificBuyer;
    }
    
    function isExpired(string memory term) private view returns (bool expired) {
        expired = block.timestamp > copyrights[term].currentHolder.expirationDate;
    }
    
    function cancelSale(string memory term) public {
        require(msg.sender == copyrights[term].currentHolder.holder, "You are not the current owner of this copyright!");
        copyrights[term].forSale = false;
        copyrights[term].price = 0;
        copyrights[term].specificBuyer = address(0);
    }
    
    function checkCopyright(string memory term) public view returns (string memory copyrightedTerm, address currentHolderAddress, uint256 creationDate, uint256 expirationDate, bool forSale, uint256 price, address specificBuyer) {
        copyrightedTerm = copyrights[term].copyrightedTerm;
        currentHolderAddress = copyrights[term].currentHolder.holder;
        creationDate = copyrights[term].currentHolder.creationDate;
        expirationDate = copyrights[term].currentHolder.expirationDate;
        forSale = copyrights[term].forSale;
        price = copyrights[term].price;
        specificBuyer = copyrights[term].specificBuyer;
    }
    
    function numberOfPreviousHolders(string memory term) public view returns (uint256 previousHolders) {
        require(bytes(copyrights[term].copyrightedTerm).length > 0, "This copyright has no holder yet!");
        previousHolders = copyrights[term].previousHolders.length;
    }
    
    function getCurrentHolder(string memory term) public view returns (address holder, uint256 creationDate, uint256 expirationDate, bool wasSold) {
        require(bytes(copyrights[term].copyrightedTerm).length > 0, "This copyright has no holder yet!");
        holder = copyrights[term].currentHolder.holder;
        creationDate = copyrights[term].currentHolder.creationDate;
        expirationDate = copyrights[term].currentHolder.expirationDate;
        wasSold = copyrights[term].currentHolder.wasSold;
    }
    
    function getPreviousHolder(string memory term, uint256 holderIndex) public view returns (address previousHolder, uint256 creationDate, uint256 expirationDate, bool wasSold) {
        require(bytes(copyrights[term].copyrightedTerm).length > 0, "This copyright has no holder yet!");
        require(holderIndex < copyrights[term].previousHolders.length, "There's no previous holder with this index!");
        previousHolder = copyrights[term].previousHolders[holderIndex].holder;
        creationDate = copyrights[term].previousHolders[holderIndex].creationDate;
        expirationDate = copyrights[term].previousHolders[holderIndex].expirationDate;
        wasSold = copyrights[term].previousHolders[holderIndex].wasSold;
    }
}

import "../utils/FormatConverter.sol";
import "../utils/StringAppender.sol";
