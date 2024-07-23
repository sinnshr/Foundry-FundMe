// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3} from "../test/mocks/MockV3.sol";

// deploy mocks when we are on a local anvil chain
// keep track of adresses across diffrent chains

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address
    }

    NetworkConfig public activeNetwork;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetwork = getSepoliaEthConfig();
        } else {
            activeNetwork = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory SepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return SepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // 1.deploy the mock
        // 2.Return the mock addresses
        if (activeNetwork.priceFeed != address(0)) {
            return activeNetwork;
        }
        vm.startBroadcast();

        MockV3 mockPriceFeed = new MockV3(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
