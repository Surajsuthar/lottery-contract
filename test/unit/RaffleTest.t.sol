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

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

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
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleIntialRaffleOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenNotEnoughEth() public {
        //Arrange,act/asset/
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__GetEnoughEthToEnterInRaffle.selector);
        raffle.enterRaffle();
    }

    function testEnterIntoRaffle() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value : entraceFee }();
        address playerRecord = raffle.getPlayer(0);
        assert(playerRecord == PLAYER);
    }

    function testEnteringRaffleEmitsEvents() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entraceFee}();
    }

    function testDontAllowWhileRaffleStateIsCalCulating() public {
        // arrange,
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //act/asset
        vm.expectRevert(Raffle.Raffle__raffelNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value : entraceFee}();
    }
}
