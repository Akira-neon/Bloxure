pragma solidity 0.8.3;

import "./Ownable.sol";

contract AXA is Ownable {
    // Initialize variables
    uint public claimAmount;
    address payable public claimReceiver;
    uint public voteClaimCounter;
    uint private claimTimer;

    event claimTransferred(address payable indexed _claimReceiver, uint indexed _claimAmount);
    event premiumCollected(address indexed _premiumPayer, uint indexed _premiumAmount);
    mapping(address => bool) public votedPayClaim;
    
    
    // Constructor that assigns five authorizer
    constructor (address[5] memory _authorizers) {
        for(uint i = 0; i < 5; i++){
            authorized[i] =  _authorizers[i];
            isAuthorizer[_authorizers[i]] = true;
            emit AuthorizerTransferred(address(0), _authorizers[i]);
        }
    }
    
    
    // Function that allows premiums to be paid to the Smart Contract
    function collectPremium() public payable {
        emit premiumCollected(msg.sender, msg.value);
    }

    // Function that pays out a claim, utilizes a multisig method and is timelocked for one day
    // Has additional functionaly to check whether payment is in Ether or wei
    function payClaim() public onlyAuthorized {
        require(voteClaimCounter >= 3, "Not enough votes are collected");
        require(block.timestamp > claimTimer, "Time lock is still active (could still take max 24h)");
        claimReceiver.transfer(claimAmount);
        emit claimTransferred(claimReceiver, claimAmount);
        resetVotingClaim();
    }

    // Authorizing function that serves as the multisig, transfer functionality is unlocked after 3 authorizations
    function votePayClaim(uint _claimAmount, address payable _claimReceiver) public onlyAuthorized {
        if(claimAmount == 0 && claimReceiver == address(0)){
            claimAmount = _claimAmount;
            claimReceiver = _claimReceiver;
        }
        require(claimAmount == _claimAmount && claimReceiver == _claimReceiver, "Claim Amount or Claim Target do not match current vote.");
        require(!votedPayClaim[msg.sender], "You already voted.");
        voteClaimCounter++;
        votedPayClaim[msg.sender] = true;
        if(voteClaimCounter == 3){
            claimTimer = block.timestamp + 2 minutes;
        }
    }

    // Allows owner to cancel a transfer authorization
    function cancelTransfer() public onlyAuthorized {
        resetVotingClaim();
    }

  // Function that resets the voting.
  function resetVotingClaim() internal {
      for(uint i = 0; i < 5; i++){
          votedPayClaim[authorized[i]] = false;
      }
      claimReceiver = payable(address(0));
      claimAmount = 0;
      voteClaimCounter = 0;
  }

}