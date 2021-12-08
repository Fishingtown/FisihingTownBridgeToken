// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FishingTownPresale is Ownable {

    mapping(address => bool) public whiteList;

    address[] private whiteListAccounts;
    using SafeERC20 for IERC20;

    IERC20 public busdToken;

    address public treasuryAddress;
    uint256 public totalBusdFund;
    uint256 public currentBusdFund;

    uint256 public startTime;
    // uint256 public deadLine;
    uint256 public minPrice;
    uint256 public maxPrice;
    bool presaleEnd;
    
    mapping(address => uint256) whiteListBusdBalances;

    // event
    event WhiteListAdded(address addr);
    event WhiteListRemoved(address addr);
    event WhiteListSale(address whitelist, uint256 amount);


    constructor(
        address _busdToken,
        address _treasuryAddress,
        uint256 _startTime,
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _totalBusdFund
        ) {
            require(
                _busdToken != address(0) &&
                _treasuryAddress != address(0) &&
                _startTime >= 0 &&
                _minPrice >= 0 &&
                _maxPrice >= 0, "not zero"
            );

            busdToken = IERC20(_busdToken);
            treasuryAddress = _treasuryAddress;
            totalBusdFund = _totalBusdFund * 1 ether;
            startTime = _startTime;
            minPrice = _minPrice * 1 ether;
            maxPrice = _maxPrice * 1 ether;

        }
    
    function whiteListPresale (uint256 busdAmount) external onlyWhiteList {
        require(!presaleEnd && block.timestamp >= startTime && currentBusdFund < totalBusdFund);
        //check address can buy total at max price
        uint256 amount = busdAmount * 1 ether;
        require(
            whiteListBusdBalances[msg.sender] + amount <= maxPrice && 
            (amount >= (100 * 1 ether)|| whiteListBusdBalances[msg.sender] >= (200 * 1 ether))
        );
        busdToken.safeTransferFrom(msg.sender,treasuryAddress, amount);
        whiteListBusdBalances[msg.sender] += amount;
        emit WhiteListSale(msg.sender, amount);
        currentBusdFund+= amount;
    }

    function getWhiteListBalance(address wlAddress) public view returns(uint256)  {
        return whiteListBusdBalances[wlAddress];
    }

    function setPresaleEnd() public onlyOwner {
        presaleEnd = true;
    }

    function setPresaleTime(uint256 _presaleTime) public onlyOwner {
        startTime = _presaleTime;
    }

    function transferToTreasury(uint256 amount) public onlyOwner {
        address(this).safeTransfer(treasuryAddress, amount * 1 ether);
    }

    // whitelist part

    modifier onlyWhiteList() {
        require(whiteList[msg.sender]);
        _;
    }

    function addWhiteList(address addr) onlyOwner public returns (bool success) {
        if(!whiteList[addr]) {
            whiteListAccounts.push(addr);
            whiteList[addr] = true;
            emit WhiteListAdded(addr);
            success = true;
        }
    }

    function removeWhiteList(address addr) onlyOwner public returns (bool success) {
        if(whiteList[addr]) {
            whiteList[addr] = false;
            emit WhiteListRemoved(addr);
            success = true;
        }
    }

    function addMultipleWhiteList(address[] memory addrs) onlyOwner public returns (bool success) {
        for(uint256 i=0; i < addrs.length; i++) {
            if(addWhiteList(addrs[i])) {
                success = true;
            }
        }
    }

    function removeMultipleWhiteList(address[] memory addrs) onlyOwner public returns (bool success) {
        for(uint256 i=0; i < addrs.length; i++) {
            if(removeWhiteList(addrs[i])) {
                success = true;
            }
        }
    }

    function getLengthWhiteList() public view onlyOwner returns(uint256){
        return whiteListAccounts.length;
    }

    function getwhiteListAccount(uint256 index) public view returns(address){
        return whiteListAccounts[index];
    }
}