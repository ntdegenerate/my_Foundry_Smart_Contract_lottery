//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Script, console2} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/linkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();

        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        console2.log("Creating SubscriptionId on chain id: ", block.chainid);
        vm.startBroadcast(account);
        // vm.roll(block.number);
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(
            vrfCoordinator
        );
        uint256 subId = coordinator.createSubscription();
        vm.stopBroadcast();
        console2.log("Your Subscription Id is: ", subId);
        console2.log(
            "Please update the subscriptionId in the HelperConfig file"
        );
        return (subId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator;
        uint256 subId;
        if (helperConfig.getConfig().subscriptionId != 0) {
            subId = helperConfig.getConfig().subscriptionId;
            vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        } else {
            CreateSubscription subscriptionCreator = new CreateSubscription();
            (subId, vrfCoordinator) = subscriptionCreator.run();
        }

        address linkToken = helperConfig.getConfig().linkToken;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinator, subId, linkToken, account);
        console2.log("fund subscription: ", subId);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address linkToken,
        address account
    ) public {
        console2.log("Funding subscription: ", subId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On chainId: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            console2.log(LinkToken(linkToken).balanceOf(msg.sender));
            console2.log(msg.sender);
            console2.log(LinkToken(linkToken).balanceOf(address(this)));
            console2.log(address(this));
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        address recentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(recentlyDeployed);
    }

    function addConsumerUsingConfig(address recentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator;
        uint256 subId;
        address account = helperConfig.getConfig().account;
        if (helperConfig.getConfig().subscriptionId != 0) {
            subId = helperConfig.getConfig().subscriptionId;
            vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        } else {
            CreateSubscription subscriptionCreator = new CreateSubscription();
            (subId, vrfCoordinator) = subscriptionCreator.run();
        }
        addConsumer(recentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(
        address recentlyDeployedRaffle,
        address vrfCoordinator,
        uint256 subId,
        address account
    ) public {
        console2.log("Adding consumer contract: ", recentlyDeployedRaffle);
        console2.log("Using VRFCoordinator: ", vrfCoordinator);
        console2.log("On chain id: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            recentlyDeployedRaffle
        );
        vm.stopBroadcast();
    }
}
