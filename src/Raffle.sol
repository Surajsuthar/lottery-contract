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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * errors
 */

error Raffle__GetEnoughEthToEnterInRaffle();
error Raffle__TranferFaild();
error Raffle__raffelNotOpen();

/**
 * @title A simple raffle contract
 * @author Suraj
 * @notice This is contract is for creating a sampler raffle
 * @dev Implement ChainLink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {

    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    address private s_recentWinner;
    /**
     * @dev after some interval winner is choosen
     */
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamps;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    RaffleState private s_raffleState;

    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
        )
     VRFConsumerBaseV2Plus(_vrfCoordinator)   {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamps = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee,"sholf be enough Eth to enter in Raffle");
        // require(msg.value >= i_entranceFee,Raffle__GetEnoughEthToEnterInRaffle());
        if(s_raffleState!=RaffleState.OPEN) {
            revert Raffle__raffelNotOpen();
        }

        if (msg.value < i_entranceFee) {
            revert Raffle__GetEnoughEthToEnterInRaffle();
        }
        emit RaffleEntered(msg.sender);
    }

    //get random number
    // use a random number to pick winner
    // autometiclally called
    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamps) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING

        //vrf2.5
        // get a request-rnf
        // get rnf
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );
    }

    /**
     * Getter function
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        uint256 randomIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[randomIndex];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TranferFaild();
        }
    }
}
