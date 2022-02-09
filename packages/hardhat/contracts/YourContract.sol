pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 

contract YourContract is Ownable {

  address public taxCollector;

  enum Status {
    Unpaid,
    Partial,
    Paid,
    Late,
    Exempt
  }

  Status public status;

  struct TaxPayer {
    bool onboard;
    address taxpayerAddress;
    bool single;
    uint256 salary;
    uint256 taxRate;
    uint256 taxBalance;
    bool taxable;
    Status status;
  }
  
  mapping(address => TaxPayer) public taxpayers;

  event Onboard(bool onboard, address taxpayerAddress, bool single, uint256 salary, uint256 taxRate, uint256 taxBalance, bool taxable, Status status);

  constructor() payable {
    taxCollector = address(this);
  }

  function taxBracket(uint256 _salary, bool _single) private pure returns(uint256 taxRate) {
    if(_single ? (_salary >= 539900) : (_salary >= 647850)) {
      return 37;
    } else if(_single ? (_salary >= 215950 && _salary < 539900) : (_salary >= 431900 && _salary < 647850)) {
      return 35;
    } else if(_single ? (_salary >= 170050 && _salary < 215950) : (_salary >= 340100 && _salary < 431900)) {
      return 32;
    } else if(_single ? (_salary >= 89075 && _salary < 170050) : (_salary >= 178150 && _salary < 340100)) {
      return 24;
    } else if(_single ? (_salary >= 41775 && _salary < 89075) : (_salary >= 83550 && _salary < 178150)) {
      return 22;
    } else if(_single ? (_salary >= 10275 && _salary < 41775) : (_salary >= 20550 && _salary < 83550)) {
      return 12;
    } else if(_single ? (_salary >= 0 && _salary < 10275) : (_salary >= 0 && _salary < 20550)) {
      return 10;
    }
  }
  function onboard(uint256 _salary, bool _single, bool _taxable) public payable {
    // Onboard one-time but able to update salary...
    TaxPayer storage taxpayer = taxpayers[msg.sender];
    require(!taxpayer.onboard, "Already onboarded");
    
    bool _onboard = true;
    uint256 taxRate = taxBracket(_salary, _single);

    // Sloppy taxBal USD to ETH
    uint256 taxBalance = (((_salary * taxRate) / 100) / 3000) * 10**18;
    uint256 taxBalancePartial = taxBalance - msg.value;
    if(_taxable) {
      status = Status.Unpaid;
    } else {
      require(msg.value == 0, "Not taxable");
      status = Status.Exempt;
    }

    taxpayers[msg.sender] = TaxPayer({
      onboard: _onboard,
      taxpayerAddress: msg.sender,
      salary: _salary,
      single: _single,
      taxRate: taxRate,
      taxBalance: taxBalancePartial,
      taxable: _taxable,
      status: taxBalance != taxBalancePartial ? Status.Partial : status
    });

    emit Onboard(_onboard, msg.sender, _single, _salary, taxRate, taxBalance, _taxable, status);
  }

  function payTaxBalance() public payable {
    TaxPayer storage taxpayer = taxpayers[msg.sender];
    uint256 _amount = msg.value;

    require(_amount > 0, "Please enter a positive amount");
    require(taxpayer.onboard, "You have not been onboarded");
    require(taxpayer.status != Status.Exempt, "You are exempt from paying taxes");
    require(taxpayer.taxBalance >= _amount, "You are paying too much taxes");

    (bool sent, bytes memory data) = taxCollector.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    
    taxpayer.taxBalance -= _amount;

    if(taxpayer.taxBalance > 0) {
      taxpayer.status = Status.Partial;
    } else if(taxpayer.taxBalance == 0) {
      taxpayer.status = Status.Paid;
    }
  }

  receive() external payable {}
  fallback() external payable {}
}
