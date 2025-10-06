// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title PiggyBank
 * @dev A secure piggy bank contract that allows deposits and owner-only withdrawals
 * @author Your Name
 */
contract PiggyBank {
    // State variables
    address public immutable owner;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    bool public isPaused;
    
    // Security features
    uint256 public maxWithdrawalAmount;
    uint256 public dailyWithdrawalLimit;
    uint256 public lastWithdrawalDay;
    uint256 public dailyWithdrawals;
    uint256 public constant SECONDS_PER_DAY = 86400;
    
    // Reentrancy protection
    bool private _locked;
    
    // Events
    event Deposit(address indexed depositor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed owner, uint256 amount, uint256 timestamp);
    event EmergencyPause(address indexed owner, bool paused, uint256 timestamp);
    event EmergencyWithdraw(address indexed owner, uint256 amount, uint256 timestamp);
    event WithdrawalLimitUpdated(address indexed owner, uint256 newLimit, uint256 timestamp);
    event DailyLimitUpdated(address indexed owner, uint256 newLimit, uint256 timestamp);
    
    // Errors
    error NotOwner();
    error ContractPaused();
    error NoFundsToWithdraw();
    error TransferFailed();
    error InvalidAmount();
    error ExceedsMaxWithdrawal(uint256 requested, uint256 maxAllowed);
    error ExceedsDailyLimit(uint256 requested, uint256 dailyLimit, uint256 alreadyWithdrawn);
    error ReentrancyGuard();
    error ZeroAddress();
    
    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    modifier whenNotPaused() {
        if (isPaused) revert ContractPaused();
        _;
    }
    
    modifier validAmount(uint256 amount) {
        if (amount == 0) revert InvalidAmount();
        _;
    }
    
    modifier nonReentrant() {
        if (_locked) revert ReentrancyGuard();
        _locked = true;
        _;
        _locked = false;
    }
    
    /**
     * @dev Constructor sets the owner of the piggy bank and initial limits
     * @param _maxWithdrawalAmount Maximum amount that can be withdrawn in a single transaction
     * @param _dailyWithdrawalLimit Maximum amount that can be withdrawn per day
     */
    constructor(uint256 _maxWithdrawalAmount, uint256 _dailyWithdrawalLimit) {
        if (msg.sender == address(0)) revert ZeroAddress();
        
        owner = msg.sender;
        isPaused = false;
        maxWithdrawalAmount = _maxWithdrawalAmount;
        dailyWithdrawalLimit = _dailyWithdrawalLimit;
        lastWithdrawalDay = block.timestamp / SECONDS_PER_DAY;
        dailyWithdrawals = 0;
    }
    
    /**
     * @dev Allows anyone to deposit ETH into the piggy bank
     * @notice This function is payable and accepts ETH deposits
     */
    function deposit() external payable whenNotPaused validAmount(msg.value) nonReentrant {
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Allows only the owner to withdraw a specific amount
     * @param amount The amount of ETH to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner whenNotPaused validAmount(amount) nonReentrant {
        if (address(this).balance < amount) revert NoFundsToWithdraw();
        
        // Check maximum withdrawal limit
        if (amount > maxWithdrawalAmount) {
            revert ExceedsMaxWithdrawal(amount, maxWithdrawalAmount);
        }
        
        // Check daily withdrawal limit
        _updateDailyWithdrawals(amount);
        
        totalWithdrawals += amount;
        
        (bool success, ) = payable(owner).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(owner, amount, block.timestamp);
    }
    
    /**
     * @dev Allows only the owner to withdraw all funds
     * @notice This function bypasses withdrawal limits as it's an emergency function
     */
    function withdrawAll() external onlyOwner whenNotPaused nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsToWithdraw();
        
        // Reset daily withdrawals when withdrawing all
        _resetDailyWithdrawals();
        
        totalWithdrawals += balance;
        
        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(owner, balance, block.timestamp);
    }
    
    /**
     * @dev Emergency pause function - only owner can pause/unpause
     * @param paused True to pause, false to unpause
     */
    function setPaused(bool paused) external onlyOwner {
        isPaused = paused;
        emit EmergencyPause(owner, paused, block.timestamp);
    }
    
    /**
     * @dev Emergency withdrawal function - only works when paused
     * @param amount The amount to withdraw in emergency
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner validAmount(amount) nonReentrant {
        if (!isPaused) revert ContractPaused();
        if (address(this).balance < amount) revert NoFundsToWithdraw();
        
        totalWithdrawals += amount;
        
        (bool success, ) = payable(owner).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit EmergencyWithdraw(owner, amount, block.timestamp);
    }
    
    /**
     * @dev Update the maximum withdrawal amount per transaction
     * @param newLimit The new maximum withdrawal amount
     */
    function setMaxWithdrawalAmount(uint256 newLimit) external onlyOwner {
        maxWithdrawalAmount = newLimit;
        emit WithdrawalLimitUpdated(owner, newLimit, block.timestamp);
    }
    
    /**
     * @dev Update the daily withdrawal limit
     * @param newLimit The new daily withdrawal limit
     */
    function setDailyWithdrawalLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
        emit DailyLimitUpdated(owner, newLimit, block.timestamp);
    }
    
    /**
     * @dev Internal function to update daily withdrawals tracking
     * @param amount The amount being withdrawn
     */
    function _updateDailyWithdrawals(uint256 amount) internal {
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        
        // Reset daily withdrawals if it's a new day
        if (currentDay > lastWithdrawalDay) {
            dailyWithdrawals = 0;
            lastWithdrawalDay = currentDay;
        }
        
        // Check if this withdrawal would exceed daily limit
        if (dailyWithdrawals + amount > dailyWithdrawalLimit) {
            revert ExceedsDailyLimit(amount, dailyWithdrawalLimit, dailyWithdrawals);
        }
        
        dailyWithdrawals += amount;
    }
    
    /**
     * @dev Internal function to reset daily withdrawals (used in withdrawAll)
     */
    function _resetDailyWithdrawals() internal {
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        dailyWithdrawals = 0;
        lastWithdrawalDay = currentDay;
    }
    
    /**
     * @dev Get the current balance of the piggy bank
     * @return The current ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get the net savings (total deposits - total withdrawals)
     * @return The net amount saved
     */
    function getNetSavings() external view returns (uint256) {
        return totalDeposits - totalWithdrawals;
    }
    
    /**
     * @dev Get contract statistics
     * @return balance Current balance
     * @return deposits Total deposits made
     * @return withdrawals Total withdrawals made
     * @return netSavings Net savings amount
     * @return maxWithdrawal Maximum withdrawal per transaction
     * @return dailyLimit Daily withdrawal limit
     * @return dailyWithdrawn Amount withdrawn today
     * @return isPausedContract Whether contract is paused
     */
    function getStats() external view returns (
        uint256 balance,
        uint256 deposits,
        uint256 withdrawals,
        uint256 netSavings,
        uint256 maxWithdrawal,
        uint256 dailyLimit,
        uint256 dailyWithdrawn,
        bool isPausedContract
    ) {
        balance = address(this).balance;
        deposits = totalDeposits;
        withdrawals = totalWithdrawals;
        netSavings = totalDeposits - totalWithdrawals;
        maxWithdrawal = maxWithdrawalAmount;
        dailyLimit = dailyWithdrawalLimit;
        dailyWithdrawn = dailyWithdrawals;
        isPausedContract = isPaused;
    }
    
    /**
     * @dev Get daily withdrawal information
     * @return currentDailyWithdrawals Amount withdrawn today
     * @return remainingDailyLimit Remaining amount that can be withdrawn today
     * @return lastWithdrawalDayTimestamp Timestamp of last withdrawal day
     */
    function getDailyWithdrawalInfo() external view returns (
        uint256 currentDailyWithdrawals,
        uint256 remainingDailyLimit,
        uint256 lastWithdrawalDayTimestamp
    ) {
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        
        // If it's a new day, daily withdrawals should be 0
        if (currentDay > lastWithdrawalDay) {
            currentDailyWithdrawals = 0;
            remainingDailyLimit = dailyWithdrawalLimit;
        } else {
            currentDailyWithdrawals = dailyWithdrawals;
            remainingDailyLimit = dailyWithdrawalLimit > dailyWithdrawals 
                ? dailyWithdrawalLimit - dailyWithdrawals 
                : 0;
        }
        
        lastWithdrawalDayTimestamp = lastWithdrawalDay * SECONDS_PER_DAY;
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable whenNotPaused nonReentrant {
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
}
