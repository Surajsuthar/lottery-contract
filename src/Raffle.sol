// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
* errors
 */

error Raffle__GetEnoughEthToEnterInRaffle();

/**
* @title A simple raffle contract
* @author Suraj
* @notice This is contract is for creating a sampler raffle
* @dev Implement ChainLink VRFv2.5
 */

contract Raffle {
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    /**
    * @dev after some interval winner is choosen
     */
    uint256 private immutable i_interval;
    uint256 private  s_lastTimeStamps;


    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee,uint256 interval){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamps = block.timestamp;
    }
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee,"sholf be enough Eth to enter in Raffle");
        // require(msg.value >= i_entranceFee,Raffle__GetEnoughEthToEnterInRaffle());
        if(msg.value < i_entranceFee) {
            revert Raffle__GetEnoughEthToEnterInRaffle();
        }
        emit RaffleEntered(msg.sender);
    }

    //get random number
    // use a random number to pick winner
    // autometiclally called
    function pickWinner() view external {
        if((block.timestamp - s_lastTimeStamps) < i_interval ) {
            revert();
        }
    }

    /**
    * Getter function
     */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}