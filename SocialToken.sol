pragma solidity ^0.4.24;

import "https://github.com/s-chepurnov/social-token/blob/master/SafeMath.sol";
import "https://github.com/s-chepurnov/social-token/blob/master/ERC20.sol";
import "https://github.com/s-chepurnov/social-token/blob/master/owned.sol";

/**
 * @title SocialToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * if (1 ETH == 100 EUR)
 * increase price by
 * One Ether is 1000000000000000000 wei
 */
contract SocialToken is ERC20, owned {

  string public constant name = "SocialToken";
  string public constant symbol = "SDT";
  uint8 public constant decimals = 12;
  uint256 public constant INITIAL_SUPPLY = 3000000000000 * (10 ** uint256(decimals));

  //0.0001 Euro = 0.000001 Ether = 1000000000000 Wei
  uint256 public priceOfOneTokenInWei = 1000000000000;
  uint256 private userCounter = 0;
  uint256 public transferedPeriod = 0; //uint32 possible
  uint256 public transferedValue = 0;
  uint256 public counterInvestment = 1; //uint8 possible
  mapping (address => bool) private registeredUsers;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

  event TrackTransfer(
    address indexed to,
    uint256 amount,
    uint256 transferedValue,
    uint256 transferedPeriod
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

  event RegisterUser(
    address indexed newUserAddress,
    uint256 userCounter
  );

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

  event IncreasePrice(
    uint256 userCounter
  );

  // 0.000001 Euro -> 0.00000001 Ether -> 1 000 000 000 0 Wei
  function increasePrice() internal {
      priceOfOneTokenInWei = priceOfOneTokenInWei.add(10000000000);

      emit IncreasePrice(priceOfOneTokenInWei);
  }

  event RegisterInvestment(
    address indexed owner,
    uint256 userCounter
  );

  function registerInvestment() onlyOwner public {
    counterInvestment = counterInvestment.add(1);
    increasePrice();

    emit RegisterInvestment(msg.sender, counterInvestment);
  }

  event Buy(
    uint256 amount,
    uint256 priceOfOneTokenInWei,
    address indexed sender
  );

  function buy() payable public returns (uint amount) {
    amount = msg.value/priceOfOneTokenInWei;
    trackTransfer(msg.sender, amount);

    emit Buy(amount, priceOfOneTokenInWei, msg.sender);
    return amount;
  }

  event Sell(
    uint256 amount,
    uint256 revenue,
    uint256 priceOfOneTokenInWei,
    address indexed sender
  );

  // read: https://github.com/ethereum/solidity/issues/3115
  function sell(uint256 amount) public returns(uint revenue) {
    trackTransfer(this, amount);              // makes the transfers

    //TODO: does it works? or should use the trackTransfer() ?
    msg.sender.transfer(amount * priceOfOneTokenInWei);   // sends ether to the seller. It's important to do this last to avoid recursion attacks
    revenue = amount * priceOfOneTokenInWei;

    emit Sell(amount, revenue, priceOfOneTokenInWei, msg.sender);
    return revenue;
  }

}
