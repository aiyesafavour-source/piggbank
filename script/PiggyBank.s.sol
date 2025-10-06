// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

/**
 * @title PiggyBankScript
 * @dev Deployment script for the PiggyBank contract
 */
contract PiggyBankScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Set withdrawal limits: max 1 ETH per transaction, 5 ETH per day
        uint256 maxWithdrawal = 1 ether;
        uint256 dailyLimit = 5 ether;
        
        PiggyBank piggyBank = new PiggyBank(maxWithdrawal, dailyLimit);
        
        console.log("PiggyBank deployed to:", address(piggyBank));
        console.log("Owner:", piggyBank.owner());
        console.log("Initial balance:", piggyBank.getBalance());
        console.log("Max withdrawal amount:", piggyBank.maxWithdrawalAmount());
        console.log("Daily withdrawal limit:", piggyBank.dailyWithdrawalLimit());
        
        vm.stopBroadcast();
    }
}
