// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstent {
    /** VRF mock values
     */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    uint256 public MOCK_WEI_PER_UNIT_LINK = 4e15;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

error HelperConfig__InvalidChainID();

contract HelperConfig is CodeConstent, Script {
    struct NetworkConfig {
        uint256 entraceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes gasLane;
        uint32 callBackGasLimit;
        uint256 subscriptionId;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainID(uint256 ChainId) public returns(NetworkConfig memory) {
       if( networkConfig[ChainId].vrfCoordinator!=address(0)){
        return networkConfig[ChainId];
       } else if(ChainId==LOCAL_CHAIN_ID ) {
         return getAnvilEthConfig();
       } else {
        revert HelperConfig__InvalidChainID();
       }
    }

    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChainID(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            entraceFee: 0.01 ether,
            interval: 30, // sec
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callBackGasLimit: 500000,
            subscriptionId: 0
        });
    }

    function getAnvilEthConfig()  public returns(NetworkConfig memory)  {
        if(localNetworkConfig.vrfCoordinator!=address(0)){
            return localNetworkConfig;
        }
        //deploy mock and stuffl
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock( MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK );
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entraceFee: 0.01 ether,
            interval: 30, // sec
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callBackGasLimit: 500000,
            subscriptionId: 0
        });

        return localNetworkConfig;
    }
}