pragma solidity ^0.4.24;

import "github.com/s-chepurnov/social-token/SafeMath.sol";
import "github.com/s-chepurnov/social-token/ERC20.sol";
import "github.com/s-chepurnov/social-token/owned.sol";

/**
 * @title SocialToken
 * 
 * One Ether is 1e18 Wei
 * One Euro  is 1e18 EuroWei
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract SocialToken is IERC20, owned {
  using SafeMath for uint256;

  string public constant name = "SocialToken";
  string public constant symbol = "SDT";
  uint8 public constant decimals = 12;
  uint256 public constant INITIAL_SUPPLY = 3000000000000 * (10 ** uint256(decimals));

  //0.0001 Euro = 1e12EuroWei = 1000000000000 EuroWei
  uint256 public priceOfOneTokenInEuroWei = 1000000000000;
  uint256 public freeTokens = 10000;

  uint256 private userCounter = 0;
  uint256 public transferedPeriod = 0; //uint32 possible
  uint256 public transferedValue = 0;
  uint256 public counterInvestment = 1; //uint8 possible
  mapping (address => bool) private registeredUsers;

  //standart
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  uint256 private _totalSupply;


  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public payable {
    _mint(msg.sender, INITIAL_SUPPLY.div(4));
    //_mint(msg.sender, INITIAL_SUPPLY.div(4)); TODO: second person
    _mint(address(this), INITIAL_SUPPLY.div(2));
  }

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(value);

    if (_isNeedToRegister(to)) {
      value = value.add(freeTokens);
      _balances[to] = _balances[to].add(value);            // Add the same to the recipient + freeTokens for a new user
    } else {
      _balances[to] = _balances[to].add(value);            // Add the same to the recipient
    }
    _trackTransfer(msg.sender, to, value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    
    if (_isNeedToRegister(_to)) {
      value = value.add(freeTokens);
      _balances[to] = _balances[to].add(value);            // Add the same to the recipient + freeTokens for a new user
    } else {
      _balances[to] = _balances[to].add(value);            // Add the same to the recipient
    }

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _trackTransfer(from, to, value);

    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
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
    address indexed from,
    address indexed to
  );

  // Internal transfer, can only be called by this contract
  function _transfer(address _from, address _to, uint _value) internal {
    require (_to != address(0x0));                          // Prevent transfer to 0x0 address. Use burn() instead
    require (_balances[_from] >= _value);                   // Check if the sender has enough
    require (_balances[_to] + _value >= _balances[_to]);    // Check for overflows
    _balances[_from] = _balances[_from].sub(_value);        // Subtract from the sender
    
    if (isNeedToRegister(_to)) {
      _value = _value.add(freeTokens);
      _balances[_to] = _balances[_to].add(_value);            // Add the same to the recipient + freeTokens for a new user
    } else {
      _balances[_to] = _balances[_to].add(_value);            // Add the same to the recipient
    }
    _trackTransfer(_from, _to, _value);

    emit Transfer(_from, _to, _value);
  }

  function _trackTransfer(address _from, address _to, uint256 _amount) internal {
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

  function get(uint256 amount) public onlyOwner {
    _transfer(address(this), msg.sender, amount);
  }

  function _isNeedToRegister(address _new) internal returns(bool) {
    if (registeredUsers[_new] == true) {
      return false;
    } else {
      userCounter = userCounter.add(1);
      //increase price by every new user
      increasePrice();
      registeredUsers[_new] = true;
      emit RegisterUser(_new, userCounter);    
      
      return true;
    }
  }

  function registerUser(address _newUserAddress) public {
    if (registeredUsers[_newUserAddress] == true) {
      return;
    }

    _transfer(msg.sender, _newUserAddress, freeTokens);

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
    _transfer(address(this), msg.sender, amount);

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
    _transfer(msg.sender, address(this), _amount);

    emit Sell(_amount, revenue, priceOfOneTokenInWei, msg.sender, address(this));
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
  function getPrice() internal returns(uint256 priceOfOneTokenInWei) {
    //price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591) // MAINNET ADDRESS
    //price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909) // TESTNET ADDRESS (ROPSTEN)
    //uint256 oneCent = price.EUR(0);// return price of 0.01 Euro in Wei
    //TODO: remove hard coded value
    //0.01 Euro = 0.0001 Ether = 1e14 Wei
    uint256 oneCent = 100000000000000;
    return priceOfOneTokenInEuroWei.mul(oneCent).div(10000000000000000);
  }

}
