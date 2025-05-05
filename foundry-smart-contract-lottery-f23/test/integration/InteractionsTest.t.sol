// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
//I guess we want to test that our contracts will be created successfully, funded, and added to our subscription
import {Test, console} from "lib/forge-std/src/Test.sol";
import {DeployContract} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Vm} from "forge-std/Vm.sol";

contract InteractionTest is Test {
    HelperConfig helperConfig = new HelperConfig();
    CreateSubscription createSubscription = new CreateSubscription();
    FundSubscription fundSubscription = new FundSubscription();
    AddConsumer addConsumer = new AddConsumer();
    DeployContract deployer;
    Raffle raffle;
    uint256 subId;
    address vrfCoordinator;
    address account;
    address linkToken;
    address recentlyDeployed;

    address OWNER = makeAddr("owner");
    event SubscriptionConsumerAdded(uint256 indexed subId, address consumer);

    function setUp() external {
        // subId = helperConfig.getConfig().subscriptionId;
        deployer = new DeployContract();
        // recentlyDeployed = DevOpsTools.get_most_recent_deployment(
        //     "Raffle",
        //     block.chainid
        // );
        vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        account = helperConfig.getConfig().account;
        linkToken = helperConfig.getConfig().linkToken;

        vm.deal(OWNER, 10 ether);
    }

    function testCreateSubscription() external {
        (subId, ) = createSubscription.createSubscriptionUsingConfig();
        assert(subId > 0);
        console.log("Created Subscription ID: ", subId);
    }

    function testFundSubscription() external {
        vm.recordLogs();
        fundSubscription.run();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // Access non-indexed event data (oldBalance and newBalance)
        bytes memory data = entries[5].data;
        //Got the entries index through trial and error
        // Decode the `data` correctly
        (uint96 oldBalance, uint96 newBalance) = abi.decode(
            data,
            (uint96, uint96)
        );

        console.log("Old Balance:", uint256(oldBalance));
        console.log("New Balance:", uint256(newBalance));

        // Do your assert
        assert(oldBalance < newBalance);
    }

    function testAddConsumer() external {
        recentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        // subId = createSubscription.createSubscriptionUsingConfig();
        vm.recordLogs();
        addConsumer.run();
        console.log(subId);
        console.log("Raffle address: ", address(raffle));
        // console.log("msg.sender", msg.sender);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // Access non-indexed event data (oldBalance and newBalance)
        bytes memory data = entries[5].data;

        // Decode the `data` correctly
        address consumer = abi.decode(data, (address));
        console.log("consumer added:", address(consumer));
        assert(consumer == recentlyDeployed);
    }
}
