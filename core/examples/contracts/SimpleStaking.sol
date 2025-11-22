// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleStaking
 * @dev Basic staking contract for AxionAX Testnet
 * @notice Stake tokens and earn rewards over time
 */
contract SimpleStaking {
    // Staking token (could be AXX or any ERC-20)
    address public stakingToken;
    
    // Reward rate: tokens per second per staked token (in wei)
    uint256 public rewardRate = 1e15; // 0.001 tokens per second
    
    // Total staked amount
    uint256 public totalStaked;
    
    // Staker information
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
    }
    
    mapping(address => Stake) public stakes;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    
    /**
     * @dev Constructor
     * @param _stakingToken Address of the token to stake (use address(0) for native AXX)
     */
    constructor(address _stakingToken) {
        stakingToken = _stakingToken;
    }
    
    /**
     * @dev Stake tokens (or native AXX if stakingToken is address(0))
     */
    function stake() public payable {
        require(msg.value > 0, "Must stake some amount");
        require(stakingToken == address(0), "Use stakeTokens for ERC-20");
        
        // Claim pending rewards before updating stake
        if (stakes[msg.sender].amount > 0) {
            _claimRewards();
        }
        
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].lastClaimTime = block.timestamp;
        
        totalStaked += msg.value;
        
        emit Staked(msg.sender, msg.value);
    }
    
    /**
     * @dev Unstake all tokens
     */
    function unstake() public {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");
        
        // Claim rewards first
        _claimRewards();
        
        uint256 amount = userStake.amount;
        
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].startTime = 0;
        stakes[msg.sender].lastClaimTime = 0;
        
        totalStaked -= amount;
        
        // Transfer tokens back
        if (stakingToken == address(0)) {
            payable(msg.sender).transfer(amount);
        }
        
        emit Unstaked(msg.sender, amount);
    }
    
    /**
     * @dev Calculate pending rewards for a user
     */
    function pendingRewards(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        
        if (userStake.amount == 0) {
            return 0;
        }
        
        uint256 stakingDuration = block.timestamp - userStake.lastClaimTime;
        uint256 reward = (userStake.amount * rewardRate * stakingDuration) / 1e18;
        
        return reward;
    }
    
    /**
     * @dev Claim accumulated rewards
     */
    function claimRewards() public {
        require(stakes[msg.sender].amount > 0, "No stake found");
        _claimRewards();
    }
    
    /**
     * @dev Internal function to claim rewards
     */
    function _claimRewards() private {
        uint256 reward = pendingRewards(msg.sender);
        
        if (reward > 0) {
            stakes[msg.sender].lastClaimTime = block.timestamp;
            
            // Transfer rewards (in real implementation, would come from rewards pool)
            if (stakingToken == address(0) && address(this).balance >= reward) {
                payable(msg.sender).transfer(reward);
            }
            
            emit RewardClaimed(msg.sender, reward);
        }
    }
    
    /**
     * @dev Get stake information for a user
     */
    function getStakeInfo(address user) public view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lastClaimTime,
        uint256 pending
    ) {
        Stake memory userStake = stakes[user];
        return (
            userStake.amount,
            userStake.startTime,
            userStake.lastClaimTime,
            pendingRewards(user)
        );
    }
    
    /**
     * @dev Update reward rate (for testing purposes)
     */
    function setRewardRate(uint256 newRate) public {
        require(newRate > 0, "Rate must be positive");
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    /**
     * @dev Get contract statistics
     */
    function getStats() public view returns (
        uint256 _totalStaked,
        uint256 _rewardRate,
        uint256 contractBalance
    ) {
        return (
            totalStaked,
            rewardRate,
            address(this).balance
        );
    }
    
    /**
     * @dev Allow contract to receive AXX
     */
    receive() external payable {}
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
