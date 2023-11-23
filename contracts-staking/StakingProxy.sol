// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract StakingStorage {
    bool public constant isStakingContract = true;

    address public owner;
    address public implementation;

    address public stakeToken;

    uint public stakeCount;
    uint public unbondingPeriod;

    struct StakeType {
        uint rewardModifier;
        uint durationModifier;
        uint duration;
    }

    // list of stake types
    StakeType[] public stakeTypes;

    struct Stake {
        uint stakeId;
        uint stakeType;
        address staker;
        bool isActive;
        bool isUnbonding;

        uint stakeAmount;
        uint rewardAmount;
        uint createdTimestamp;

        uint claimedAmount;
        uint claimedTimestamp;

        uint unlockTimestamp;
        uint unbondingTimestamp;
    }

    // list of stakes
    Stake[] public stakes;
}

interface IStakingImplementation {
    function isStakingContract() external view returns (bool);
}

contract StakeProxy is StakingStorage {
    event NewImplementation(address oldImplementation, address newImplementation);
    event NewOwner(address oldOwner, address newOwner);

    constructor(IStakingImplementation newImplementation) {
        owner = msg.sender;
        implementation = address(newImplementation);

        // stakeToken = 0x9f215Fc670154c19f1cc1A08E3464304De719390; // IDRX Mumbai
        stakeToken = 0x3AdafCD334157b74A97027eE5d2faa9cc39feaDE; // IDRX BSC Testnet

        // unbondingPeriod = 432000; // 5 days
        unbondingPeriod = 360; // 6 minutes

        // setup default stake types
        stakeTypes.push(StakeType({
            // Type 0 
            // placeholder
            rewardModifier: 0,
            durationModifier: 0,
            duration: 0
        }));
        stakeTypes.push(StakeType({
            // Type 1 
            // lock 1 month; APY: 3.8%
            rewardModifier: 380,
            durationModifier: 12,
            // duration: 2630000
            duration: 600 // testing
        }));
        stakeTypes.push(StakeType({
            // Type 2 
            // lock 3 months; APY: 4%
            rewardModifier: 400,
            durationModifier: 4,
            // duration: 7890000
            duration: 1800 // testing
        }));
        stakeTypes.push(StakeType({
            // Type 3 
            // lock 6 months; APY: 4.32%
            rewardModifier: 432,
            durationModifier: 2,
            // duration: 15780000
            duration: 3600 // testing
        }));
        stakeTypes.push(StakeType({
            // Type 4 
            // lock 1 year; APY: 4.56%
            rewardModifier: 456,
            durationModifier: 1,
            // duration: 31560000
            duration: 7200 // testing
        }));

        // insert stakes index 0
        Stake memory _stake = Stake({
            stakeId: 0,
            stakeType: 0,
            staker: address(0),
            isActive: false,
            isUnbonding: false,
            stakeAmount: 0,
            rewardAmount: 0,
            createdTimestamp: 0,
            claimedAmount: 0,
            claimedTimestamp: 0,
            unlockTimestamp: 0,
            unbondingTimestamp: 0
        });
        stakes.push(_stake);

        require(newImplementation.isStakingContract() == true, "invalid implementation");

        emit NewImplementation(address(0), implementation);
    }

    function setImplementation(IStakingImplementation newImplementation) public {
        require(msg.sender == owner, "UNAUTHORIZED");
        require(newImplementation.isStakingContract() == true, "invalid implementation");

        address oldImplementation = implementation;
        implementation = address(newImplementation);

        emit NewImplementation(oldImplementation, implementation);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "UNAUTHORIZED");

        address oldOwner = owner;
        owner = newOwner;

        emit NewOwner(oldOwner, newOwner);
    }

    function _fallback(address _implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {
        _fallback(implementation);
    }

    fallback() external payable {
        _fallback(implementation);
    }

}


