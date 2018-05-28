pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;

/**
 * The Controller is a replaceable endpoint for minting and unminting Badge.sol
 */

import "./IBadges.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract Controller is Ownable {

    using SafeMath for uint;

    event Bought(uint tokenId, uint amountPaid, address boughtBy);


    address badges;
    uint editionSize = 100;

    function Controller(address _badges) public {
        badges = _badges;
    }    

    function getPrice(uint _workId) public constant returns (uint) {
        require(IBadges(badges).workExists(_workId));
        uint soldSoFar = IBadges(badges).workSold(_workId).add(10); // artist, programmer, new models editions
        require(soldSoFar < editionSize);
        uint price = 1 finney;
        price = price.mul(soldSoFar.sub(10).add(1).mul(10));
        return price;
    }

/* ------------------------------------------------------------------------------------ */

    /**
    * @dev Buy an edition of a work.
    * @param _to The address owning the work.
    * @param _workId The Id of the work.
    * @return A boolean representing whether or not the purchase was successful.
    */
    function buy(address _to, uint _workId) public payable returns (bool) {
        uint edition = IBadges(badges).workSold(_workId).add(1).add(10); // artist, programmer, new models editions
        require(edition <= editionSize);
        uint price = getPrice(_workId); // reverts if tokenId is out of range
        require(msg.value >= price);
        uint _tokenId = _workId.mul(100).add(edition);

        badges.transfer(price);
        if (msg.value > price) {
            msg.sender.send(msg.value.sub(price));
        }

        IBadges(badges).mint(_to, _tokenId);
        Bought(_tokenId, price, _to);
        return true;
    }

    function reserved(address _to, uint _workId) public returns (bool) {
        if (_to == IBadges(badges).workArtist(_workId)) {
            // sender is artist of work // 3 works
            for (uint i = 1; i < 4; i++) {
                if (!IBadges(badges).exists(_workId.mul(100).add(i))) {
                    IBadges(badges).mint(_to, _workId.mul(100).add(i));
                }
            }
        } else if (_to == IBadges(badges).getBilly()) {
            // sender is programmer Billy // 2 works
            for (i = 4; i < 6; i++) {
                if (!IBadges(badges).exists(_workId.mul(100).add(i))) {
                    IBadges(badges).mint(_to, _workId.mul(100).add(i));
                }
            }
        } else if (_to == IBadges(badges).getWallet()) {
            // sender is new models // 5 works
            for (i = 6; i < 11; i++) {
                if (!IBadges(badges).exists(_workId.mul(100).add(i))) {
                    IBadges(badges).mint(_to, _workId.mul(100).add(i));
                }
            }
        }
    }

    function moveEth(address _to, uint256 amount) public onlyOwner returns (bool) {
        require(amount <= this.balance);
        return _to.send(amount);
    }
    function moveToken(uint256 amount, address _to, address token) public onlyOwner returns (bool) {
        require(amount <= ERC20(token).balanceOf(this));
        return ERC20(token).transfer(_to, amount);
    }
    function approveToken(uint256 amount, address _to, address token) public onlyOwner returns (bool) {
        return ERC20(token).approve(_to, amount);
    }

}