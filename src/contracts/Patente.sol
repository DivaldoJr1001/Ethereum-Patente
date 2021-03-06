// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Patente
 * @dev Possibilita a compra, venda e expiração de patentes
 */
contract Copyright {

    struct CopyrightHolder {
        string copyrightedTerm;
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
    mapping(address => CopyrightHolder[]) private holders;

    function buyCopyright(string memory term, uint256 durationSeconds) public payable {
        address claimer = msg.sender;

        require(bytes(term).length > 0, "You must search a term!");
        require(durationSeconds > 60, "The minimum duration of a newly bought copyright is 60 seconds!");
        require(!isCurrentOwner(term, msg.sender), "You already own this copyright!");

        copyrights[term].copyrightedTerm = term;

        if (copyrights[term].currentHolder.holder != address(0)) {
            if (isExpired(term)) {
                require(msg.value == (2 * durationSeconds * 10**18), append3("It costs 2 Ether per second to buy an expired copyright! (Current Price: ", uint2str(2 * durationSeconds), " Ether)"));
            } else {
                require(copyrights[term].forSale, "The copyright has a current owner and is not for sale!");

                if (copyrights[term].specificBuyer != address(0)) {
                    require(copyrights[term].specificBuyer == msg.sender, "The copyright is for sale, but it has been reserved for another address!");
                }

                require(msg.value == (copyrights[term].price + durationSeconds) * 10**18, append5("This copyright is being sold for ", uint2str(copyrights[term].price), " Ether on top of the fee of 1 Ether per second! (Current Price: ", uint2str(copyrights[term].price + durationSeconds), " Ether)"));

                copyrights[term].currentHolder.wasSold = true;

                address payable addr = payable(copyrights[term].currentHolder.holder);

                addr.transfer(copyrights[term].price * 10**18);

                for (uint256 i = 0; i < holders[copyrights[term].currentHolder.holder].length; i++) {
                    string memory currentTerm = holders[copyrights[term].currentHolder.holder][i].copyrightedTerm;
                    if (keccak256(bytes(currentTerm)) == keccak256(bytes(term))) {
                        holders[copyrights[term].currentHolder.holder][i].wasSold = true;
                        break;
                    }
                }
            }
            copyrights[term].previousHolders.push(copyrights[term].currentHolder);
            copyrights[term].forSale = false;
            copyrights[term].price = 0;
            copyrights[term].specificBuyer = address(0);
        } else {
            require(msg.value == (durationSeconds * 10**18), append3("It costs 1 Ether per second to buy a new copyright! (Current Price: ", uint2str(durationSeconds), " Ether)"));
        }

        CopyrightHolder memory newHolder = CopyrightHolder(term, claimer, block.timestamp, block.timestamp + (durationSeconds), false);

        copyrights[term].currentHolder = newHolder;
        holders[msg.sender].push(newHolder);
    }

    function extendCopyright(string memory term, uint256 durationSeconds) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(durationSeconds > 0, "You must choose the additional duration of the copyright in seconds!");
        require(msg.value ==  (durationSeconds * 10**18), append3("Each additional second owning a copyright costs 1 Ether! (Current Price: ", uint2str(durationSeconds), " Ether)"));
        
        copyrights[term].currentHolder.expirationDate += durationSeconds;
    }

    function sellCopyright(string memory term, uint256 price) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(copyrights[term].forSale == false, "This copyright is already up for sale!");
        require(msg.value == 50 ether, "It costs 50 Ether to set up a copyright sale!");

        copyrights[term].forSale = true;
        copyrights[term].price = price;
        copyrights[term].specificBuyer = address(0);
    }

    function sellCopyrightToAddress(string memory term, uint256 price, address specificBuyer) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(copyrights[term].forSale == false, "This copyright is already up for sale!");
        require(msg.value == 50 ether, "It costs 50 Ether to set up a copyright sale!");

        copyrights[term].forSale = true;
        copyrights[term].price = price;
        copyrights[term].specificBuyer = specificBuyer;
    }

    function changeTargetBuyer(string memory term, address specificBuyer) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(copyrights[term].forSale == true, "This copyright isn't for sale!");
        require(msg.value == 10 ether, "It costs 10 Ether to define a buyer address!");

        copyrights[term].specificBuyer = specificBuyer;
    }

    function makeSalePublic(string memory term) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(copyrights[term].forSale == true, "This copyright isn't for sale!");
        require(copyrights[term].specificBuyer == address(0), "This sale is already public!");
        require(msg.value == 10 ether, "It costs 10 Ether to make a copyright sale public!");

        copyrights[term].specificBuyer = address(0);
    }

    function changeSalePrice(string memory term, uint256 newPrice) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(copyrights[term].forSale == true, "This copyright isn't for sale!");
        require(msg.value == 5 ether, "It costs 5 Ether to change the copyright's sale price!");

        copyrights[term].price = newPrice;
    }

    function cancelSale(string memory term) public payable {
        require(isCurrentOwner(term, msg.sender), "You're not the current holder of this copyright!");
        require(msg.value == 10 ether, "It costs 10 Ether to cancel a copyright sale!");
        copyrights[term].forSale = false;
        copyrights[term].price = 0;
        copyrights[term].specificBuyer = address(0);
    }

    function getCopyrightStatus(string memory term) public view returns (CopyrightStatus memory copyrightStatus) {
        require(bytes(copyrights[term].copyrightedTerm).length > 0, "This copyright was never bought!");
        copyrightStatus = copyrights[term];
    }

    function getCurrentHolder(string memory term) public view returns (CopyrightHolder memory currentHolder) {
        require(bytes(copyrights[term].copyrightedTerm).length > 0, "This copyright has no holder yet!");
        currentHolder = copyrights[term].currentHolder;
    }

    function getPreviousHolders(string memory term) public view returns (CopyrightHolder[] memory previousHolders) {
        require(bytes(copyrights[term].copyrightedTerm).length > 0, "This copyright was never bought!");
        previousHolders = copyrights[term].previousHolders;
    }

    function getAddressCopyrights(address ownerAddress) public view returns (CopyrightHolder[] memory currentOwnedTerms) {
        currentOwnedTerms = holders[ownerAddress];
    }

    function isExpired(string memory term) private view returns (bool expired) {
        expired = block.timestamp > copyrights[term].currentHolder.expirationDate;
    }

    function isCurrentOwner(string memory term, address senderAddress) private view returns (bool isOwner) {
        isOwner = copyrights[term].currentHolder.holder == senderAddress && !isExpired(term);
    }
}

import "../utils/FormatConverter.sol";
import "../utils/StringAppender.sol";
