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

    // list of locked stake types
    mapping(uint => bool) public lockedTypes;
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
    event stakeUnbonded(
        uint stakeId,
        uint unbondingTimestamp
    );
    event withdrawPrincipalUnbonded(
        uint stakeId,
        address staker,
        uint principalAmount,
        uint claimedTimestamp
    );
    event stakeTypeModified(
        uint index,
        uint rewardModifier,
        uint durationModifier,
        uint duration
    );
    event newUnbondingPeriod(uint p);
    event newStakeType(
        uint rewardModifier,
        uint durationModifier,
        uint duration
    );

    // getters
    function getStake(uint[] memory stakeId) external view returns (Stake[] memory) {
        Stake[] memory _stakes = new Stake[](stakeId.length);
        for ( uint i = 0; i < stakeId.length; i++ ) {
            _stakes[i] = stakes[stakeId[i]];
        }
        return _stakes;
    }
    function getLockedTypes(uint index) external view returns (bool) {
        return lockedTypes[index];
    }

    // setters
    function setUnbondingPeriod(uint p) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        unbondingPeriod = p;
        emit newUnbondingPeriod(p);
    }
    function setStakeType(uint index, uint rewardModifier, uint durationModifier, uint duration) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        stakeTypes[index] = StakeType({
            rewardModifier: rewardModifier,
            durationModifier: durationModifier,
            duration: duration
        });
        emit stakeTypeModified(index, rewardModifier, durationModifier, duration);
    }
    function setLockedTypes(uint index, bool val) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        lockedTypes[index] = val;
    }
    function addStakeType(uint rewardModifier, uint durationModifier, uint duration) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        stakeTypes.push(StakeType({
            rewardModifier: rewardModifier,
            durationModifier: durationModifier,
            duration: duration
        }));
        emit newStakeType(rewardModifier, durationModifier, duration);
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
        // validate
        require(stakeTypes[stakeType].duration != 0, "invalid stake type");
        require(amount > 10000, "invalid amount");

        // transfer amount in
        IERC20 _stakingToken = IERC20(stakeToken);
        _stakingToken.transferFrom(msg.sender, address(this), amount);

        // calculate stake reward & duration
        StakeType memory _stakeType = stakeTypes[stakeType];
        uint _rewardAmount = amount * _stakeType.rewardModifier / 10000 / _stakeType.durationModifier;
        uint _unlockTimestamp = block.timestamp + _stakeType.duration;

        // insert new stake
        Stake memory _stake = Stake({
            stakeId: stakeCount+1,
            stakeType: stakeType,
            staker: msg.sender,
            isActive: true,
            isUnbonding: false,

            stakeAmount: amount,
            rewardAmount: _rewardAmount,
            createdTimestamp: block.timestamp,

            claimedAmount: 0,
            claimedTimestamp: 0,

            unlockTimestamp: _unlockTimestamp,
            unbondingTimestamp: 0
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
        require(_stake.staker == msg.sender, "invalid staker");
        require(_stake.isActive == true, "stake is not active");
        require(_stake.isUnbonding == false, "stake is already unbonding");

        // calculate claim amount
        uint _timestamp = block.timestamp;
        uint _fullDuration = _stake.unlockTimestamp - _stake.createdTimestamp;
        uint _progressDuration = _timestamp - _stake.createdTimestamp;
        if ( _progressDuration > _fullDuration ) {
            _progressDuration = _fullDuration;
        }
        uint _claimAmount = _stake.rewardAmount * _progressDuration / _fullDuration;
        _claimAmount = _claimAmount - _stake.claimedAmount;

        if ( _claimAmount > 0 ) {
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
    }

    function unbondStake(uint stakeId) public {
        Stake memory _stake = stakes[stakeId];
        uint _timestamp = block.timestamp;

        // validate
        require(!lockedTypes[_stake.stakeType], "locked stake type");
        require(_stake.staker == msg.sender, "invalid staker");
        require(_stake.isActive == true, "stake is not active");
        require(_stake.isUnbonding == false, "stake is already unbonding");

        // update stakes
        stakes[stakeId].isUnbonding = true;
        stakes[stakeId].unbondingTimestamp = _timestamp + unbondingPeriod;

        emit stakeUnbonded(stakeId, stakes[stakeId].unbondingTimestamp);
    }

    function claimStakePrincipalUnbonded(uint stakeId) public {
        Stake memory _stake = stakes[stakeId];
        uint _timestamp = block.timestamp;

        // validate
        require(!lockedTypes[_stake.stakeType], "locked stake type");
        require(_stake.staker == msg.sender, "invalid staker");
        require(_stake.isActive == true, "stake is not active");
        require(_stake.isUnbonding == true, "stake is not unbonding");
        require(_timestamp > _stake.unbondingTimestamp, "stake is still unbonding");

        // calculate claim amount
        uint _claimAmount = _stake.stakeAmount - _stake.claimedAmount;
        require(_claimAmount > 0, "principal is already withdrawn");

        // update stakes
        stakes[stakeId].isActive = false;
        stakes[stakeId].isUnbonding = false;
        stakes[stakeId].claimedTimestamp = _timestamp;

        // transfer principal to staker
        IERC20 _stakingToken = IERC20(stakeToken);
        _stakingToken.transfer(_stake.staker, _claimAmount);

        emit withdrawPrincipalUnbonded(
            stakeId,
            _stake.staker,
            _claimAmount,
            _timestamp
        );
    }

    function claimStakePrincipal(uint stakeId) public {
        Stake memory _stake = stakes[stakeId];
        uint _timestamp = block.timestamp;

        // validate
        require(_stake.staker == msg.sender, "invalid staker");
        require(_stake.isActive == true, "stake is not active");
        require(_stake.isUnbonding == false, "stake is already unbonding");
        require(_timestamp > _stake.unlockTimestamp, "stake is still locked");

        // withdraw remaining reward
        claimStakeReward(stakeId);

        // calculate claim amount
        uint _claimAmount = _stake.stakeAmount;

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

}


