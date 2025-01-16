// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { HelperConfig,CodeConstent } from "./HelperConfig.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "test/Mocks/LinkToken.s.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionConfig() public returns(uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subID,) = createSubscription(vrfCoordinator,account);
    }

    function createSubscription(address vrfCoordinator, address account) public returns(uint256, address) {
        console.log("Creating subcripation id on chain Id:",block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("your subcripation id on chain Id:",subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionConfig();
    }
}

contract FundSubscription is Script, CodeConstent {
    
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subsripationId = helperConfig.getConfig().subscriptionId;
        address linktoken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinator,subsripationId,linktoken,account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subsripationId, address linktoken,address account) public {
        console.log("Funding Subscription",subsripationId);
        console.log("Funding vrfCoordinator",vrfCoordinator);
        console.log("Funding linktoken",linktoken);

        if(block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subsripationId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linktoken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subsripationId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumers is Script {
    function run() external {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentDeployed);
    }

    function addConsumerUsingConfig(address mostRecentDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subsripationId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentDeployed, vrfCoordinator, subsripationId,account);
    }

    function addConsumer(address mostRecentDeployed, address vrfCoordinator, uint256 subsripationId,address account) public {
        console.log("Adding consumer contract",mostRecentDeployed);
        console.log("To vrfvontract",vrfCoordinator);
        console.log("on chainId",block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subsripationId, mostRecentDeployed);
        vm.stopBroadcast();
    } 
}