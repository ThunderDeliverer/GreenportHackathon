pragma solidity ^0.4.18;

contract controlled{
  address owner;
  mapping (address => bool) isAdministrator;

  /*
  * @dev Deply function for controll mechanics.
  */
  function controlled() public{
    owner = msg.sender;
  }

  /*
  * @dev Transfers ownership rights to current owner to the new owner.
  * @param newOwner address Address to become the new SC owner.
  */
  function transferOwnership (address newOwner) onlyOwner public{
    owner = newOwner;
  }

  /*
  * @dev Creates a new administrator.
  * @param _administrator address Address for which we are changing administration rights.
  * @param _administrationRights bool Allows us to appoint or demote new administrator.
  */
  function appointAdministrator (address _administrator, bool _administrationRights) onlyOwner public{
    isAdministrator[_administrator] = _administrationRights;
  }

  /*
  * @dev Modifier to make sure the owner's functions are only called by the owner.
  */
  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }

  /*
  * @dev Modifier to make sure administration functions are only called by the administrator or owner.
  */
  modifier onlyAdministartor{
    require(isAdministrator[msg.sender] || msg.sender == owner);
    _;
  }
}

contract Greenport is controlled{
  string public name;
  string public symbol;
  uint8 public decimals;
  int256 public totalSupply;
  int256 public registrationCredits;
  uint256 public numberOfUsers;
  int256 public deltaCreditAwardFactor;

  struct User{
    int256 negativeValues;
    int256 positiveValues;
    int256 lastNegativeValues;
    int256 lastPositiveValues;
    int256 currentDelta;
    int256 averageDelta;
    int256 monthCounter;
  }

  //Keeps track of how many tokens each user has.
  mapping (uint256 => int256) public balances;

  //Maps users to their data.
  mapping (uint256 => User) public users;

  //Maps all registered users.
  mapping (uint256 => bool) isRegistered;

  /*
  * @dev Informs anyone listening that transaction of credits took place.
  * @param from uint256 User that sends the credits.
  * @param to uint256 User that receives the credits.
  * @param value int256 Amount of credits transferred.
  */
  event Transfer(uint256 indexed from, uint256 indexed to, int256 value);

  /*
  * @dev Deploy function
  * @param _name string Sets full, possibly multiword, name of the token.
  * @param _symbol string Sets abbriveration or symbol of our token.
  * @param _decimals uint8 Sets number of decimal places used by our token.
  * @param _startingSupply uint256 Creates specified amount of tokens at deployement to contract address.
  * @param _initialOwner address Apponts owner of the contract. If left blank, the contract will set the deployer as owner.
  */
  function Greenport(string _name, string _symbol, uint8 _decimals, int256 _startingSupply, address _initialOwner) public{
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    mintToken(0, _startingSupply);
    if(_initialOwner != 0){
      transferOwnership(_initialOwner);
    }
  }

  //@dev Returns the name of the token.
  function name() constant public returns (string tokenName){
    return name;
  }

  //@dev Returns the symbol of the token.
  function symbol() constant public returns (string tokenSymbol){
    return symbol;
  }

  //@dev Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.
  function decimals() constant public returns (uint8 tokenDecimals){
    return decimals;
  }

  /*
  * @dev Allows us to view the token balance of the account.
  * @param _tokenOwner uint256 Address of the user whose credits balance we are trying to view.
  */
  function balanceOf(uint256 _tokenOwner) constant public returns (int256 accountBalance){
    return balances[_tokenOwner];
  }

  function viewUser(uint256 _userID) constant public returns (int256 theNegativeValues, int256 thePositiveValues, int256 theLastNegativeValues, int256 theLastPositiveValues, int256 theCurrentDelta, int256 theAverageDelta, int256 theMonthCounter){
    var theUser = users[_userID];
    return(theUser.negativeValues, theUser.positiveValues, theUser.lastNegativeValues, theUser.lastPositiveValues, theUser.currentDelta, theUser.averageDelta, theUser.monthCounter);
  }

  /*
  * @dev Lets users share tokens and will allow us to implement loyality programs.
  * @param _userID uint256 User that sends the credits.
  * @param _to uint256 User that receives the credist.
  * @param _value int256 Amount of credits transferred.
  */
  function transfer(uint256 _to, int256 _value, uint256 _userID) public returns (bool success){
    require(isRegistered[_to]);
    require(balances[_userID] >= _value);
    //To avoid getting overflows:
    require((balances[_to] + _value) > balances[_to]);
    balances[_userID] -= _value;
    balances[_to] += _value;
    Transfer(_userID, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(uint256 _from, uint256 _to, int256 _value) internal{
    require(isRegistered[_to]);
    require(_value <= balances[_from]);
    //To avoid getting overflows:
    require((balances[_to] + _value) > balances[_to]);
    balances[_from] -= _value;
    balances[_to] += _value;
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Internal function to allow SC to create additional tokens if there aren't enough available.
   * @param _userID address Address to which we are minting new tokens.
   * @param mintedAmount uint256 Amount of tokens to be allocated t the _userID address. Please note that decimal places are considered as full integers in this call.
  */
  function mintToken(uint256 _userID, int256 mintedAmount) internal{
    balances[_userID] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, 0, mintedAmount);
    Transfer(0, _userID, mintedAmount);
  }

  /*
  * @dev Registers new user by their unique user ID.
  */
  function registerNewUser () onlyAdministartor public returns(uint256 userIdentifier){
    numberOfUsers += 1;
    uint256 _userID = numberOfUsers;
    isRegistered[_userID] = true;
    mintToken(_userID, registrationCredits);
    var theUser = users[_userID];
    theUser.negativeValues = 0;
    theUser.positiveValues = 0;
    theUser.lastNegativeValues = 0;
    theUser.lastPositiveValues = 0;
    theUser.currentDelta = 0;
    theUser.averageDelta = 0;
    theUser.monthCounter = 0;
    return(_userID);
  }

  /*
  * @dev Tracks negative actions of the user during the course of a month.
  * @param _userID uint256  User ID of the user that commited actions with negaitve impact.
  * @param _valuesToAdd int256 Variable to track the impact of user's negative actions.
  */
  function negativeValues (uint256 _userID, int256 _valuesToAdd) onlyAdministartor public{
    var theUser = users[_userID];
    theUser.negativeValues = _valuesToAdd;
    theUser.currentDelta = theUser.positiveValues - theUser.negativeValues;
  }

  /*
  * @dev Tracks the impact of the users positive actions.
  * @param _userID uint256 User ID of te user tat commited actions with positive impact.
  * @param _valuesToAdd int256 VAriable to track the impact of user's positive actions.
  */
  function positiveValues (uint256 _userID, int256 _valuesToAdd) onlyAdministartor public{
    var theUser = users[_userID];
    theUser.positiveValues = _valuesToAdd;
    theUser.currentDelta = theUser.positiveValues - theUser.negativeValues;
  }

  /*
  * @dev Assigns credits based on the current delta of positive vs. negative actions compared to current average for all users.
  */
  function assignCredits () onlyAdministartor public{
    for(uint256 i=1; i <= numberOfUsers; i++){
      var theUser = users[i];
      theUser.monthCounter += 1;
      theUser.lastNegativeValues = theUser.negativeValues;
      theUser.negativeValues = 0;
      theUser.lastPositiveValues = theUser.positiveValues;
      theUser.positiveValues = 0;
      int256 monthlyCreditsAward = (theUser.currentDelta - theUser.averageDelta) * deltaCreditAwardFactor;
      mintToken(i, monthlyCreditsAward);
      theUser.averageDelta = ((theUser.averageDelta * ((theUser.monthCounter - 1) / theUser.monthCounter)) + (theUser.currentDelta / theUser.monthCounter));
      theUser.currentDelta = 0;
    }
  }

  /*
  * @dev Sets credit awarding factor that multiplies with the positive impacto of the user.
  * @param _factor int256 The factor that awards users for positive behaviour (can be positive or negative, based on use case).
  */
  function setDeltaCreditAwardFactor (int256 _factor) onlyAdministartor public{
    deltaCreditAwardFactor = _factor;
  }

  /*
  * @dev Determines how many credits a new user is awarded in the beginning. Used to make sure the first action of the user doesn't award them less than 0 credits.
  * @param _amout int256 Amount of credit user receiv es at the beginning.
  */
  function setRegistrationCreditsAmount (int256 _amount) onlyAdministartor public{
    registrationCredits = _amount;
  }
}
