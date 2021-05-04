pragma solidity 0.8.3;

contract Ownable {
    address[5] public authorized;
    uint public voteAuthorizerCounter;
    uint public voteDeadline;
    address public oldAuthorizer;
    address public newAuthorizer;

    event AuthorizerTransferred(address indexed previousOwner, address indexed newOwner);
    mapping(address => bool) public isAuthorizer;
    mapping(address => bool) public votedChangeAuthorizer;


  // Modifier similar to onlyOwner.
  modifier onlyAuthorized() {
      require(isAuthorized(), "Caller is not an authorizer.");
      _;
  }
  
  // Function checks if user is an authorizer.
  function isAuthorized() public view returns(bool) {
      return isAuthorizer[msg.sender]; 
  }
  
  // Function that votes to change an Authorizer
  function voteChangeAuthorizer(address _oldAuthorizer, address _newAuthorizer) public onlyAuthorized {
      if(oldAuthorizer == address(0) && newAuthorizer == address(0)){
          oldAuthorizer = _oldAuthorizer;
          newAuthorizer = _newAuthorizer;
          voteDeadline = block.timestamp + 2 minutes;
      }
      require(_oldAuthorizer == oldAuthorizer && _newAuthorizer == newAuthorizer, "Old Authorizer address or New Authorizer address do not match current vote.");
      require(!votedChangeAuthorizer[msg.sender], "You already voted.");
      voteAuthorizerCounter++;
      votedChangeAuthorizer[msg.sender] = true;
  }
  
  // Function that changes Authorizer if enough votes have been casted.
  function transferAuthorizer() public onlyAuthorized {
      require(voteAuthorizerCounter >= 3, "Not enough votes are collected.");
      uint indexOldAuthorizer = getIndex();
      authorized[indexOldAuthorizer] = newAuthorizer;
      isAuthorizer[oldAuthorizer] = false;
      isAuthorizer[newAuthorizer] = true;
      emit AuthorizerTransferred(oldAuthorizer, newAuthorizer);
      resetVotingAuthorizer();
  }
  
  // Function that resets the voting.
  function resetVotingAuthorizer() internal {
      for(uint i = 0; i < 5; i++){
          votedChangeAuthorizer[authorized[i]] = false;
      }
      oldAuthorizer = address(0);
      newAuthorizer = address(0);
      voteAuthorizerCounter = 0;
  }
  
  // Function that allows Authorizers to cancel vote if enough time has passed.
  function cancelVote() public onlyAuthorized {
    require(block.timestamp > voteDeadline, "Voting deadline has not passed yet.");
    resetVotingAuthorizer(); 
  }
  
  // Functions that returns index of Authorizer in Authorized array
  function getIndex() view internal returns(uint) {
      for(uint i = 0; i < 5; i++){
          if(authorized[i] == oldAuthorizer){
              return i;
          }
      }
      return 6;
  }
}