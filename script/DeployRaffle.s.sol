// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script,console } from "forge-std/Script.sol";
import { Raffle } from "src/Raffle.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumers } from "./Intrection.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mock get get local config
        // sepolia -> get seplia config;
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSub.createSubscription(config.vrfCoordinator);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }
        vm.startBroadcast();
        console.log("config.subscriptionId",config.subscriptionId);
        Raffle raffle = new Raffle(
            config.entraceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();
        AddConsumers addConsumers = new AddConsumers();
        addConsumers.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);
        return ( raffle, helperConfig );
    }
}