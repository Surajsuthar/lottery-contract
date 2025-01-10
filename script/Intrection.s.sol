// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionConfig() public returns(uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subID,) = createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint256, address) {
        console.log("Creating subcripation id on chain Id:",block.chainid);
        vm.broadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("your subcripation id on chain Id:",subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionConfig();
    }
}

contract FundSubscription is Script {
    
    uint256 public constant FUND_AMOUNT = 3 ether

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subsripationId = helperConfig.getConfig().subscriptionId;
    }
    function run() public {}
}