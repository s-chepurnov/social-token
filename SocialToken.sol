pragma solidity ^0.4.24;

import "github.com/s-chepurnov/social-token/SafeMath.sol";
import "github.com/s-chepurnov/social-token/ERC20.sol";
import "github.com/s-chepurnov/social-token/owned.sol";

/**
 * @title SocialToken
 * 
 * One Ether is 1e18 Wei
 * One Euro  is 1e18 EuroWei
 */
contract SocialToken is ERC20, owned {

  string public constant name = "SocialToken";
  string public constant symbol = "SDT";
  uint8 public constant decimals = 12;
  uint256 public constant INITIAL_SUPPLY = 3000000000000 * (10 ** uint256(decimals));

  //0.0001 Euro = 1e12EuroWei = 1000000000000 EuroWei
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
  constructor() public payable {
     // airdrop
     // create pre-addresses
     // 2 owners
    _mint(msg.sender, INITIAL_SUPPLY);
  }

  event TrackTransfer(
    address indexed from,	  
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
    uint256 currentPriceOfOneTokenInEuroWei
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
     /* Internal transfer, can only be called by this contract */
  function _transfer(address _from, address _to, uint _value) internal {
    require (_to != address(0x0));                          // Prevent transfer to 0x0 address. Use burn() instead
    require (_balances[_from] >= _value);                   // Check if the sender has enough
    require (_balances[_to] + _value >= _balances[_to]);    // Check for overflows
    _balances[_from] = _balances[_from].sub(_value);        // Subtract from the sender
    _balances[_to] = _balances[_to].add(_value);           // Add the same to the recipient
    emit Transfer(_from, _to, _value);
  }

  function _trackTransfer(address _from, address _to, uint256 _amount) internal {
    _transfer(_from, _to, _amount);

    // increase price after every 1 000 000 Euro transfered value
    // 1 000 000 Euro = 1e24 EuroWei
    transferedValue = transferedValue.add(_amount);
    if(transferedValue >= 1000000000000000000000000) {
      increasePrice();
      transferedValue = transferedValue.sub(1000000000000000000000000);
      // 1 period is 1e24 EuroWei to avoid an uint256 overflow
      transferedPeriod = transferedPeriod.add(1);
    }

    emit TrackTransfer(_from, _to, _amount, transferedValue, transferedPeriod);
  }

  function registerUser(address _newUserAddress) public {
    if (registeredUsers[_newUserAddress] == true) {
      return;
    }

    uint256 amount = 10000;//tokens
    _trackTransfer(address(this), _newUserAddress, amount);

    userCounter = userCounter.add(1);
    //increase price by every new user
    increasePrice();
    registeredUsers[_newUserAddress] = true;
    emit RegisterUser(_newUserAddress, userCounter);
  }

  function increasePrice() internal {
      // increase price by 0.000001 Euro
      // 0.000001 Euro -> 1e12 EuroWei
      priceOfOneTokenInEuroWei = priceOfOneTokenInEuroWei.add(1000000000000);

      emit IncreasePrice(priceOfOneTokenInEuroWei);
  }

  function registerInvestment() onlyOwner public {
    counterInvestment = counterInvestment.add(1);
    increasePrice();

    emit RegisterInvestment(msg.sender, counterInvestment);
  }

  function buy() payable public returns (uint256 amount) {
    uint256 priceOfOneTokenInWei = getPrice();
    amount = msg.value/priceOfOneTokenInWei;
    //makes the transfers of tokens
    //_transfer(address(this), msg.sender, amount);
    _trackTransfer(address(this), msg.sender, amount);

    emit Buy(amount, priceOfOneTokenInWei, msg.sender);
    return amount;
  }

  //read: https://github.com/ethereum/solidity/issues/3115
  //amount - tokens
  //revenue - ether
  function sell(uint256 _amount) public payable returns(uint256 revenue) {
    uint256 priceOfOneTokenInWei = getPrice();
    //sends Ether to the seller. It's important to do this last to avoid recursion attacks
    revenue = _amount * priceOfOneTokenInWei;
    //'msg.sender.send' means the contract sends Ether to 'msg.sender'
    require(msg.sender.send(revenue));   
    //makes the transfers of tokens
    _trackTransfer(msg.sender, address(this), _amount);

    emit Sell(_amount, revenue, priceOfOneTokenInWei, msg.sender);
    return revenue;
  }

 /**
  * 1 Euro = 1e18 EuroWei 
  *
  * if (100Euro == 1 Ether) {
  *   1 cent = 0.01 Euro = 0.0001 ETH = 1e14 Wei
  *   1 cent = 0.01 Euro = 1e16 EuroWei 
  *   
  *   1e16         EuroWei = oneCent Wei (e.g. 1e14 Wei)
  *   currentPrice EuroWei = x Wei
  * }
  *
  * return the price of one token in Wei
  * 
  */
  function getPrice() internal returns(uint256 price) { 
    //uint256 oneCent = price.EUR(0);// return price of 0.01 Euro in Wei
    //TODO: remove hard coded value
    //0.01 Euro = 0.0001 Ether = 1e14 Wei
    uint256 oneCent = 100000000000000;
    return priceOfOneTokenInEuroWei.mul(oneCent).div(10000000000000000);
  }

}
