// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FunWithStorage} from "../../src/exampleContracts/FunWithStorage.sol";

contract DeployFunWithStorage is Script {
    uint8 constant GAS_PRICE = 1;

    function run() external returns (FunWithStorage) {
        vm.startBroadcast();
        FunWithStorage funWithStorage = new FunWithStorage();
        vm.stopBroadcast();
        printStorage(address(funWithStorage));
        return (funWithStorage);
    }

    /**
     * @param contractAddress The address the functions use to load storage data
     * @dev It calls the functions simultaneosly so that it's not in the run() function
     */
    function printStorage(address contractAddress) public {
        printStorageData(address(contractAddress));
        printStorageDataSpecial(address(contractAddress));
        printFirstArrayElement(address(contractAddress));
        printSecondElementOfArray(address(contractAddress));
    }

    /**
     * @dev These next functions print storage data
     */
    function printStorageData(address contractAddress) public view {
        // Loads each storage slot & prints them
        for (uint256 i = 0; i < 10; i++) {
            bytes32 value = vm.load(contractAddress, bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
    }

    function printFirstArrayElement(address contractAddress) public view {
        // The number of slots is 2
        bytes32 arrayStorageSlotLength = bytes32(uint256(2));
        bytes32 firstElementStorageSlot = keccak256(
            abi.encode(arrayStorageSlotLength)
        ); // They process the first element in the array by using a hashing function on the length of the array
        bytes32 value = vm.load(contractAddress, firstElementStorageSlot); // Loads the storage slot

        // Prints the first element in array
        console.log("First element in array:");
        console.logBytes32(value);
    }

    function printStorageDataSpecial(address contractAddress) public {
        // Tracks the gas used
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();

        // Loops over each storage slot in the contract address
        for (uint256 i; i < 10; i++) {
            bytes32 value = vm.load(contractAddress, bytes32(i)); // Loads the slot
            console.log("\n\n\n");

            // Prints the slots sequentially (if it's not empty)
            if (value != bytes32(0)) {
                console.log("Value at location", i, ":");
                console.logBytes32(value);
            }
        }
        // Checks gas afterwards
        uint256 gasEnd = gasleft();
        uint256 remainingGas = (gasStart - gasEnd) * tx.gasprice;

        if (gasStart - gasEnd * tx.gasprice == remainingGas) {
            console.log("Remaining Gas:", remainingGas);
            console.log("   ", gasStart - gasEnd * tx.gasprice, remainingGas);
        }
    }

    function printSecondElementOfArray(address contractAddress) public view {
        bytes32 arrayStorageSlotLength = bytes32(uint256(2));
        bytes32 secondElementOfArray = keccak256(
            abi.encode(arrayStorageSlotLength)
        );

        bytes32 value = vm.load(contractAddress, secondElementOfArray);

        if (value != bytes32(0)) {
            console.log("Second Element");
            console.logBytes32(value);
        }
    }

    // Option 1
    /*
     * cast storage ADDRESS
     */

    // Option 2
    // cast k 0x0000000000000000000000000000000000000000000000000000000000000002
    // cast storage ADDRESS <OUTPUT_OF_ABOVE>

    // Option 3:
    /*
     * curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"debug_traceTransaction","params":["0xe98bc0fd715a075b83acbbfd72b4df8bb62633daf1768e9823896bfae4758906"],"id":1}' http://127.0.0.1:8545 > debug_tx.json
     * Go through the JSON and find the storage slot you want
     */

    // You could also replay every transaction and track the `SSTORE` opcodes... but that's a lot of work
}
