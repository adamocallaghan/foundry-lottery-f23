// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A Sample Raffle Contract
 * @author Adam O'Callaghan
 * @notice This contract is for creating a simple Raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__InsufficientEthForTicket();

    event EnteredRaffle(address indexed _player);

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee; // i_ => it's immutable, is only set in the constructor then never changes
    address payable[] public s_players; // s_ => it's a storage variable, will change
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        // have to pass vrfCoordinator address to contsturctor on inherited contract
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        // get the entranceFee
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientEthForTicket();
        }
        // push player's address to the players array
        s_players.push(payable(msg.sender));
        // emit event
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        // after a period of time has expired
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        // call Chainlink VRF to get random number (import Chainlink contract)
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // use random number to select player
        // be automatically called
        // send ETH in this contract to the winning player's address
    }

    /** Getter Functions **/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {}
}
