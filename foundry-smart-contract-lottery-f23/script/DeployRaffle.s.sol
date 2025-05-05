//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployContract is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        //This gets the network config contract
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create subscription ID
            CreateSubscription subscriptionCreator = new CreateSubscription();
            (config.subscriptionId, ) = subscriptionCreator.createSubscription(
                config.vrfCoordinator,
                config.account
            );

            console.log(
                "This is in config.subscriptionId now: ",
                config.subscriptionId
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.linkToken,
                config.account
            );
            console.log("subId: ", config.subscriptionId);
            console.log("funded subId: ", config.subscriptionId);
        }
        // we add the consumer(contract) to the subscription after we have deployed the contract
        vm.startBroadcast(config.account);
        console.log(
            "This is in config.subscriptionId deployed: ",
            config.subscriptionId
        );
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.gasLane,
            config.vrfCoordinator,
            config.subscriptionId,
            config.callbackGasLimit
        );
        console.log("subId after deploy: ", config.subscriptionId);
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );

        console.log("subId returned: ", config.subscriptionId);
        return (raffle, helperConfig);
    }
}
