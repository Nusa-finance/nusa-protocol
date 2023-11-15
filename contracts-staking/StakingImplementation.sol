// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract StakingStorage {
    bool public constant isStakingContract = true;

    address public owner;
    address public implementation;

    address public stakeToken;

    uint public stakeCount;

    struct Stake {
        uint stakeId;
        uint stakeType;
        address staker;
        bool isActive;

        uint stakeAmount;
        uint rewardAmount;
        uint createdTimestamp;

        uint claimedAmount;
        uint claimedTimestamp;

        uint unlockTimestamp;
    }

    // list of stakes
    Stake[] public stakes;
}

contract StakingImplementation is StakingStorage {

    receive() external payable {}

    // events
    event addNewStake(
        uint stakeId,
        uint stakeType,
        address staker,
        uint stakeAmount,
        uint rewardAmount,
        uint createdTimestamp,
        uint unlockTimestamp
    );
    event claimReward(
        uint stakeId,
        address staker,
        uint claimedAmount,
        uint claimedTimestamp
    );
    event withdrawPrincipal(
        uint stakeId,
        address staker,
        uint principalAmount,
        uint claimedTimestamp
    );

    // getters
    function getStake(uint[] memory stakeId) external view returns (Stake[] memory) {
        Stake[] memory _stakes = new Stake[](stakeId.length);
        for ( uint i = 0; i < stakeId.length; i++ ) {
            _stakes[i] = stakes[stakeId[i]];
        }
        return _stakes;
    }

    // withdraw
    function withdraw(address payable to) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        if (address(this).balance > 0) {
            to.transfer(address(this).balance);
        }
    }
    function withdrawToken(address tokenAddress, address to, uint256 amount) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amount);
    }

    // staking
    function newStake(uint amount, uint stakeType) external {
        uint _rewardAmount;
        uint _unlockTimestamp;

        // transfer amount in
        IERC20 _stakingToken = IERC20(stakeToken);
        _stakingToken.transferFrom(msg.sender, address(this), amount);

        // // staking types
        // if ( stakeType == 1 ) { // lock 1 month; APY: 4%
        //     _rewardAmount = amount * 400 / 10000 / 12;
        //     _unlockTimestamp = block.timestamp + 2630000; // 1 month

        // } else if ( stakeType == 2 ) { // lock 3 months; APY: 4.5%
        //     _rewardAmount = amount * 450 / 10000 / 4;
        //     _unlockTimestamp = block.timestamp + 7890000; // 3 months

        // } else if ( stakeType == 3 ) { // lock 6 months; APY: 5%
        //     _rewardAmount = amount * 500 / 10000 / 2;
        //     _unlockTimestamp = block.timestamp + 15780000; // 6 months

        // } else if ( stakeType == 4 ) { // lock 1 year; APY: 6%
        //     _rewardAmount = amount * 600 / 10000;
        //     _unlockTimestamp = block.timestamp + 31560000; // 1 year
        // }

        // staking types testing
        if ( stakeType == 1 ) { // lock 10 minutes; APY: 4%
            _rewardAmount = amount * 400 / 10000 / 12;
            _unlockTimestamp = block.timestamp + 600; // 10 minutes

        } else if ( stakeType == 2 ) { // lock 30 minutes; APY: 4.5%
            _rewardAmount = amount * 450 / 10000 / 4;
            _unlockTimestamp = block.timestamp + 1800; // 30 minutes

        } else if ( stakeType == 3 ) { // lock 60 minutes; APY: 5%
            _rewardAmount = amount * 500 / 10000 / 2;
            _unlockTimestamp = block.timestamp + 3600; // 60 minutes

        } else if ( stakeType == 4 ) { // lock 120 minutes; APY: 6%
            _rewardAmount = amount * 600 / 10000;
            _unlockTimestamp = block.timestamp + 7200; // 120 minutes
        }

        // insert new stake
        Stake memory _stake = Stake({
            stakeId: stakeCount+1,
            stakeType: stakeType,
            staker: msg.sender,
            isActive: true,

            stakeAmount: amount,
            rewardAmount: _rewardAmount,
            createdTimestamp: block.timestamp,

            claimedAmount: 0,
            claimedTimestamp: 0,

            unlockTimestamp: _unlockTimestamp
        });
        stakes.push(_stake);

        // track stake count
        stakeCount++;

        emit addNewStake(
            _stake.stakeId,
            stakeType,
            msg.sender,
            amount,
            _rewardAmount,
            _stake.createdTimestamp,
            _stake.unlockTimestamp
        );
    }

    function claimStakeReward(uint stakeId) public {
        Stake memory _stake = stakes[stakeId];

        // validate
        require(_stake.isActive == true, "stake is not active");
        require(_stake.staker == msg.sender, "invalid staker");

        // calculate claim amount
        uint _timestamp = block.timestamp;
        uint _fullDuration = _stake.unlockTimestamp - _stake.createdTimestamp;
        uint _progressDuration = _timestamp - _stake.createdTimestamp;
        if ( _progressDuration > _fullDuration ) {
            _progressDuration = _fullDuration;
        }
        uint _claimAmount = _stake.rewardAmount * _progressDuration / _fullDuration;
        _claimAmount = _claimAmount - _stake.claimedAmount;

        require(_claimAmount > 0, "reward is fully claimed");

        // update stakes
        stakes[stakeId].claimedAmount = stakes[stakeId].claimedAmount + _claimAmount;
        stakes[stakeId].claimedTimestamp = _timestamp;

        // transfer reward to staker
        IERC20 _stakingToken = IERC20(stakeToken);
        _stakingToken.transfer(_stake.staker, _claimAmount);

        emit claimReward(
            stakeId,
            _stake.staker,
            _claimAmount,
            _timestamp
        );
    }

    function claimStakePrincipal(uint stakeId) public {
        Stake memory _stake = stakes[stakeId];

        // validate
        require(_stake.isActive == true, "stake is not active");
        require(_stake.staker == msg.sender, "invalid staker");

        // calculate claim amount
        uint _timestamp = block.timestamp;
        uint _claimAmount = _stake.stakeAmount;
        if ( _timestamp < _stake.unlockTimestamp ) {
            _claimAmount = _stake.stakeAmount - _stake.claimedAmount;
        }

        require(_claimAmount > 0, "principal is already withdrawn");

        // update stakes
        stakes[stakeId].isActive = false;
        stakes[stakeId].claimedTimestamp = _timestamp;

        // transfer principal to staker
        IERC20 _stakingToken = IERC20(stakeToken);
        _stakingToken.transfer(_stake.staker, _claimAmount);

        emit withdrawPrincipal(
            stakeId,
            _stake.staker,
            _claimAmount,
            _timestamp
        );
    }

    function claimAll(uint stakeId) external {
        claimStakeReward(stakeId);
        claimStakePrincipal(stakeId);
    }

}


