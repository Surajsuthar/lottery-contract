// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "src/Raffle.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CreateSubscription } from "./Intrection.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mock get get local config
        // sepolia -> get seplia config;
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSub.createSubscription(config.vrfCoordinator);
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entraceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.callBackGasLimit,
            config.subscriptionId
        );
        vm.stopBroadcast();

        return ( raffle, helperConfig );
    }
}