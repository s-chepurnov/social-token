pragma solidity ^0.4.24;

import "github.com/s-chepurnov/social-token/SafeMath.sol";
import "github.com/s-chepurnov/social-token/ERC20.sol";
import "github.com/s-chepurnov/social-token/owned.sol";

/**
 * @title SocialToken
 * 
 * One Ether is 10e18 Wei
 * One Euro  is 10e18 EuroWei
 */
contract SocialToken is ERC20, owned {

  string public constant name = "SocialToken";
  string public constant symbol = "SDT";
  uint8 public constant decimals = 12;
  uint256 public constant INITIAL_SUPPLY = 3000000000000 * (10 ** uint256(decimals));

  //0.0001 Euro = 1000000000000 EuroWei
  uint256 public priceOfOneTokenInEuroWei = 1000000000000;

  uint256 private userCounter = 0;
  uint256 public transferedPeriod = 0; //uint32 possible
  uint256 public transferedValue = 0;
  uint256 public counterInvestment = 1; //uint8 possible
  mapping (address => bool) private registeredUsers;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  //TODO: constructor should gives tokens for users.
  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

  event TrackTransfer(
    address indexed to,
    uint256 amount,
    uint256 transferedValue,
    uint256 transferedPeriod
  );

  event RegisterUser(
    address indexed newUserAddress,
    uint256 userCounter
  );

  event IncreasePrice(
    uint256 userCounter
  );

  event RegisterInvestment(
    address indexed owner,
    uint256 userCounter
  );

  event Buy(
    uint256 amount,
    uint256 priceOfOneTokenInWei,
    address indexed sender
  );

  event Sell(
    uint256 amount,
    uint256 revenue,
    uint256 priceOfOneTokenInWei,
    address indexed sender
  );

  function trackTransfer(address to, uint256 amount) internal {
    transfer(to, amount);

    //1 000 000 Euro = 10 000 ETH = 1 000 000 000 000 000 000 000 0 Wei
    transferedValue = transferedValue.add(amount);
    if(transferedValue >= 10000000000000000000000) {
      increasePrice();

      transferedValue = transferedValue.sub(10000000000000000000000);
      transferedPeriod = transferedPeriod.add(1);
    }

    emit TrackTransfer(to, amount, transferedValue, transferedPeriod);
  }

  //TODO: find out -> give to user tokens or Wei?
  function registerUser(address newUserAddress) public {
    if (registeredUsers[newUserAddress] == true) {
      return;
    }

    uint256 amount = 10000;
    trackTransfer(newUserAddress, amount);

    userCounter = userCounter.add(1);
    increasePrice();
    registeredUsers[newUserAddress] = true;
    emit RegisterUser(newUserAddress, userCounter);
  }

  // 0.000001 Euro -> 0.00000001 Ether -> 1 000 000 000 0 Wei
  function increasePrice() internal {
      priceOfOneTokenInWei = priceOfOneTokenInWei.add(10000000000);

      emit IncreasePrice(priceOfOneTokenInWei);
  }

  function registerInvestment() onlyOwner public {
    counterInvestment = counterInvestment.add(1);
    increasePrice();

    emit RegisterInvestment(msg.sender, counterInvestment);
  }

  function buy() payable public returns (uint256 amount) {
    uint256 rate = getExchangeRate(priceOfOneTokenInEur);
    uint256 cents = price.USD(0);
    return cents * 500;
    amount = msg.value/priceOfOneTokenInWei;
    
     
    trackTransfer(msg.sender, amount);

    emit Buy(amount, priceOfOneTokenInWei, msg.sender);
    return amount;
  }

  // read: https://github.com/ethereum/solidity/issues/3115
  function sell(uint256 amount) public returns(uint256 revenue) {
    trackTransfer(this, amount);              // makes the transfers

    //TODO: does it works? or should use the trackTransfer() ?
    msg.sender.transfer(amount * priceOfOneTokenInWei);   // sends ether to the seller. It's important to do this last to avoid recursion attacks
    revenue = amount * priceOfOneTokenInWei;

    emit Sell(amount, revenue, priceOfOneTokenInWei, msg.sender);
    return revenue;
  }

 /**
  * 1 Euro = 1e18 EuroWei 
  *
  * if (100Euro == 1 Ether) {
  *   1 cent = 0.01 Euro = 0.0001 ETH = 1e14 Wei
  *   1 cent = 0.01 Euro = 1e16 EuroWei 
  *   
  *   1e16         EuroWei = 1e14 Wei
  *   currentPrice EuroWei = x Wei
  * }
  *
  * return the price of one token in Wei
  * 
  */
  function getPrice(uint256 currentEurPrice) internal returns(uint256 price) { 
    uint256 oneCent = price.EUR(0);// return price of 0.01 Euro in Wei
    price = priceOfOneTokenInEuroWei.mul(OneCent).div(10000000000000000);
    return price;
  }

}
