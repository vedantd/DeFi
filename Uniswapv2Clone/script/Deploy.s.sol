// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Factory.sol";
import "../src/Router.sol";

contract DeployScript is Script {
    function run() external {
        // Load the private key from the environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address feeToSetter = vm.addr(deployerPrivateKey);
        Factory factory = new Factory(feeToSetter);

        Router router = new Router(address(factory));

        vm.stopBroadcast();

        console.log("Factory deployed to:", address(factory));
        console.log("Router deployed to:", address(router));
        console.log("Fee to setter:", feeToSetter);
    }
}
