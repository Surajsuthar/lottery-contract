// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import { DeployRaffle } from "script/DeployRaffle.s.sol";
import { Raffle } from "src/Raffle.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    HelperConfig private helperConfig;
    Raffle public raffle;

    uint256 public entraceFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public gasLane;
    uint32 public callBackGasLimit;
    uint256 public subscriptionId;

    address public PLAYER = makeAddr("Player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;


    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        ( raffle, helperConfig ) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entraceFee = config.entraceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callBackGasLimit = config.callBackGasLimit;
        subscriptionId = config.subscriptionId;
    }

    function testRaffleIntialRaffleOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
