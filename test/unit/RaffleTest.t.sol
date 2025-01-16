// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test,console2 } from "forge-std/Test.sol";
import { DeployRaffle } from "script/DeployRaffle.s.sol";
import { Raffle } from "src/Raffle.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { Vm } from "forge-std/Vm.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { CodeConstent } from "script/HelperConfig.s.sol";


contract RaffleTest is CodeConstent,Test {
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

    function testCheckUpKeep() public {
        // arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // act 
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReutrnFalseIfRaffleNotOpen() public {
        // arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        //assert
        assert(!upKeepNeeded);
    }

    function testPerfromUpKeepanOnlyCanRunIfCheckUpKeepTrue() public {
        // arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp);
        vm.roll(block.number + 1);
       
        // act
        raffle.performUpkeep("");
    }

    function testPerformUpkeepReverIfCheckUpkeepIsFalse() public {
        // arrange
        uint256 currentbalnece = 0;
        uint256 numPlayer = 0;
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entraceFee}();
        Raffle.RaffleState rStart = raffle.getRaffleState();
        currentbalnece+=entraceFee;
        numPlayer=1;
        // act-ssert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__upKeepNotNeeded.selector,currentbalnece, numPlayer, rStart)
        );
    }

    //what if we need data from emmitted event.?
    function testPerfromUpkeepUpdateStateAndEmitEvents() public raffleEnterd {
        // arrang
        //act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requsetId = entries[1].topics[1];

        //assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requsetId) > 0);
        assert(uint256(raffleState) == 1);
    }

    modifier raffleEnterd() {
        // arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
    /**
    * @dev fuzz test
     */
    function testFullFillRandomWordsCanOnlyBeCalledAfterPerFormUpKeep(uint256 requsetID) public raffleEnterd {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnterd skipFork {
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: entraceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console2.logBytes32(entries[1].topics[1]);
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entraceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
