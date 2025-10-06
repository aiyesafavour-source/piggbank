// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

/**
 * @title PiggyBankTest
 * @dev Test suite for the PiggyBank contract
 */
contract PiggyBankTest is Test {
    PiggyBank public piggyBank;
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    
    uint256 public constant INITIAL_DEPOSIT = 1 ether;
    uint256 public constant SECOND_DEPOSIT = 0.5 ether;
    uint256 public constant MAX_WITHDRAWAL = 1 ether;
    uint256 public constant DAILY_LIMIT = 5 ether;
    
    event Deposit(address indexed depositor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed owner, uint256 amount, uint256 timestamp);
    event EmergencyPause(address indexed owner, bool paused, uint256 timestamp);
    event WithdrawalLimitUpdated(address indexed owner, uint256 newLimit, uint256 timestamp);
    event DailyLimitUpdated(address indexed owner, uint256 newLimit, uint256 timestamp);
    
    function setUp() public {
        vm.prank(owner);
        piggyBank = new PiggyBank(MAX_WITHDRAWAL, DAILY_LIMIT);
    }
    
    function testInitialState() public {
        assertEq(piggyBank.owner(), owner);
        assertEq(piggyBank.getBalance(), 0);
        assertEq(piggyBank.totalDeposits(), 0);
        assertEq(piggyBank.totalWithdrawals(), 0);
        assertFalse(piggyBank.isPaused());
    }
    
    function testDeposit() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        assertEq(piggyBank.getBalance(), INITIAL_DEPOSIT);
        assertEq(piggyBank.totalDeposits(), INITIAL_DEPOSIT);
        assertEq(piggyBank.getNetSavings(), INITIAL_DEPOSIT);
    }
    
    function testMultipleDeposits() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        vm.deal(user2, SECOND_DEPOSIT);
        
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        vm.prank(user2);
        piggyBank.deposit{value: SECOND_DEPOSIT}();
        
        assertEq(piggyBank.getBalance(), INITIAL_DEPOSIT + SECOND_DEPOSIT);
        assertEq(piggyBank.totalDeposits(), INITIAL_DEPOSIT + SECOND_DEPOSIT);
    }
    
    function testWithdraw() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // First deposit
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        uint256 withdrawAmount = 0.3 ether;
        uint256 ownerBalanceBefore = owner.balance;
        
        // Owner withdraws
        vm.prank(owner);
        piggyBank.withdraw(withdrawAmount);
        
        assertEq(piggyBank.getBalance(), INITIAL_DEPOSIT - withdrawAmount);
        assertEq(piggyBank.totalWithdrawals(), withdrawAmount);
        assertEq(owner.balance, ownerBalanceBefore + withdrawAmount);
    }
    
    function testWithdrawAll() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // Deposit
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        uint256 ownerBalanceBefore = owner.balance;
        
        // Owner withdraws all
        vm.prank(owner);
        piggyBank.withdrawAll();
        
        assertEq(piggyBank.getBalance(), 0);
        assertEq(piggyBank.totalWithdrawals(), INITIAL_DEPOSIT);
        assertEq(owner.balance, ownerBalanceBefore + INITIAL_DEPOSIT);
    }
    
    function testNonOwnerCannotWithdraw() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // User deposits
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        // User tries to withdraw (should fail)
        vm.prank(user1);
        vm.expectRevert(PiggyBank.NotOwner.selector);
        piggyBank.withdraw(0.1 ether);
    }
    
    function testCannotDepositZero() public {
        vm.prank(user1);
        vm.expectRevert(PiggyBank.InvalidAmount.selector);
        piggyBank.deposit{value: 0}();
    }
    
    function testCannotWithdrawZero() public {
        vm.prank(owner);
        vm.expectRevert(PiggyBank.InvalidAmount.selector);
        piggyBank.withdraw(0);
    }
    
    function testCannotWithdrawMoreThanBalance() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        vm.prank(owner);
        vm.expectRevert(PiggyBank.NoFundsToWithdraw.selector);
        piggyBank.withdraw(INITIAL_DEPOSIT + 1);
    }
    
    function testPauseAndUnpause() public {
        // Owner pauses
        vm.prank(owner);
        piggyBank.setPaused(true);
        assertTrue(piggyBank.isPaused());
        
        // Owner unpauses
        vm.prank(owner);
        piggyBank.setPaused(false);
        assertFalse(piggyBank.isPaused());
    }
    
    function testNonOwnerCannotPause() public {
        vm.prank(user1);
        vm.expectRevert(PiggyBank.NotOwner.selector);
        piggyBank.setPaused(true);
    }
    
    function testCannotDepositWhenPaused() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // Owner pauses
        vm.prank(owner);
        piggyBank.setPaused(true);
        
        // User tries to deposit (should fail)
        vm.prank(user1);
        vm.expectRevert(PiggyBank.ContractPaused.selector);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
    }
    
    function testEmergencyWithdraw() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // Deposit
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        // Pause contract
        vm.prank(owner);
        piggyBank.setPaused(true);
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 withdrawAmount = 0.3 ether;
        
        // Emergency withdraw
        vm.prank(owner);
        piggyBank.emergencyWithdraw(withdrawAmount);
        
        assertEq(piggyBank.getBalance(), INITIAL_DEPOSIT - withdrawAmount);
        assertEq(piggyBank.totalWithdrawals(), withdrawAmount);
        assertEq(owner.balance, ownerBalanceBefore + withdrawAmount);
    }
    
    function testCannotEmergencyWithdrawWhenNotPaused() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        vm.prank(owner);
        vm.expectRevert(PiggyBank.ContractPaused.selector);
        piggyBank.emergencyWithdraw(0.1 ether);
    }
    
    function testReceiveFunction() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // Send ETH directly to contract
        vm.prank(user1);
        (bool success,) = address(piggyBank).call{value: INITIAL_DEPOSIT}("");
        assertTrue(success);
        
        assertEq(piggyBank.getBalance(), INITIAL_DEPOSIT);
        assertEq(piggyBank.totalDeposits(), INITIAL_DEPOSIT);
    }
    
    function testGetStats() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // Deposit
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        // Withdraw some
        uint256 withdrawAmount = 0.3 ether;
        vm.prank(owner);
        piggyBank.withdraw(withdrawAmount);
        
        (
            uint256 balance,
            uint256 deposits,
            uint256 withdrawals,
            uint256 netSavings,
            uint256 maxWithdrawal,
            uint256 dailyLimit,
            uint256 dailyWithdrawn,
            bool isPausedContract
        ) = piggyBank.getStats();
        
        assertEq(balance, INITIAL_DEPOSIT - withdrawAmount);
        assertEq(deposits, INITIAL_DEPOSIT);
        assertEq(withdrawals, withdrawAmount);
        assertEq(netSavings, INITIAL_DEPOSIT - withdrawAmount);
        assertEq(maxWithdrawal, MAX_WITHDRAWAL);
        assertEq(dailyLimit, DAILY_LIMIT);
        assertEq(dailyWithdrawn, withdrawAmount);
        assertFalse(isPausedContract);
    }
    
    function testEvents() public {
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // Test deposit event
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, INITIAL_DEPOSIT, block.timestamp);
        
        vm.prank(user1);
        piggyBank.deposit{value: INITIAL_DEPOSIT}();
        
        // Test withdrawal event
        uint256 withdrawAmount = 0.3 ether;
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(owner, withdrawAmount, block.timestamp);
        
        vm.prank(owner);
        piggyBank.withdraw(withdrawAmount);
        
        // Test pause event
        vm.expectEmit(true, false, false, true);
        emit EmergencyPause(owner, true, block.timestamp);
        
        vm.prank(owner);
        piggyBank.setPaused(true);
    }

    function testWithdrawExceedsMaxReverts() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        piggyBank.deposit{value: 2 ether}();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PiggyBank.ExceedsMaxWithdrawal.selector, MAX_WITHDRAWAL + 1, MAX_WITHDRAWAL));
        piggyBank.withdraw(MAX_WITHDRAWAL + 1);
    }

    function testDailyLimitEnforcedAndResetsNextDay() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        piggyBank.deposit{value: 10 ether}();

        // Withdraw up to limit in two txs
        vm.prank(owner);
        piggyBank.withdraw(2 ether);
        vm.prank(owner);
        piggyBank.withdraw(3 ether);

        // Next should exceed daily limit
        vm.prank(owner);
        vm.expectRevert(PiggyBank.ExceedsDailyLimit.selector);
        piggyBank.withdraw(1 wei);

        // Move to next day and withdraw again
        vm.warp(block.timestamp + piggyBank.SECONDS_PER_DAY());
        vm.prank(owner);
        piggyBank.withdraw(1 ether);
    }

    function testOnlyOwnerCanUpdateLimits() public {
        // Non-owner cannot set limits
        vm.prank(user1);
        vm.expectRevert(PiggyBank.NotOwner.selector);
        piggyBank.setMaxWithdrawalAmount(2 ether);

        vm.prank(user1);
        vm.expectRevert(PiggyBank.NotOwner.selector);
        piggyBank.setDailyWithdrawalLimit(10 ether);

        // Owner updates and events emitted
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit WithdrawalLimitUpdated(owner, 2 ether, block.timestamp);
        piggyBank.setMaxWithdrawalAmount(2 ether);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit DailyLimitUpdated(owner, 10 ether, block.timestamp);
        piggyBank.setDailyWithdrawalLimit(10 ether);

        assertEq(piggyBank.maxWithdrawalAmount(), 2 ether);
        assertEq(piggyBank.dailyWithdrawalLimit(), 10 ether);
    }

    function testReceiveRevertsWhenPaused() public {
        vm.deal(user1, 1 ether);
        vm.prank(owner);
        piggyBank.setPaused(true);

        vm.prank(user1);
        (bool success, ) = address(piggyBank).call{value: 1 ether}("");
        assertFalse(success);
    }

    function testWithdrawAllBypassesLimitsAndResetsDaily() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        piggyBank.deposit{value: 10 ether}();

        // Set tight limits
        vm.prank(owner);
        piggyBank.setMaxWithdrawalAmount(0.1 ether);
        vm.prank(owner);
        piggyBank.setDailyWithdrawalLimit(0.2 ether);

        // withdrawAll should still work
        vm.prank(owner);
        piggyBank.withdrawAll();
        assertEq(piggyBank.getBalance(), 0);

        // Daily should be reset to 0 on withdrawAll
        (, , , , , uint256 dailyLimit,,) = piggyBank.getStats();
        (uint256 currentDailyWithdrawals,,) = piggyBank.getDailyWithdrawalInfo();
        assertEq(dailyLimit, 0.2 ether);
        assertEq(currentDailyWithdrawals, 0);
    }
    function testReentrancyProtection() public {
        // Deploy malicious owner that will attempt reentrancy during receive
        ReentrantOwner attacker = new ReentrantOwner(MAX_WITHDRAWAL, DAILY_LIMIT);

        // Fund the attacker for gas accounting and fund PiggyBank via attacker
        vm.deal(address(this), 1 ether);

        // Expect the outer withdraw to revert due to nonReentrant leading to failed transfer
        vm.expectRevert(PiggyBank.TransferFailed.selector);
        attacker.fundAndAttack{value: 0.5 ether}();
    }
}

contract ReentrantOwner {
    PiggyBank public piggy;
    bool public attemptReenter;

    constructor(uint256 maxPerTx, uint256 dailyLimit) {
        // Deploy PiggyBank from this contract so it becomes the owner
        piggy = new PiggyBank(maxPerTx, dailyLimit);
        attemptReenter = true;
    }

    // Receive ETH during withdraw; attempt to reenter once
    receive() external payable {
        if (attemptReenter) {
            attemptReenter = false; // prevent infinite loop
            // This reentrant call should revert due to nonReentrant
            try piggy.withdraw(1 wei) {
            } catch {
                // Swallow to let fallback complete; but revert bubbles anyway in low-level context
            }
        }
    }

    function fundAndAttack() external payable {
        // Fund the piggy bank from caller
        piggy.deposit{value: msg.value}();
        // Attempt a withdraw which will trigger reentrancy in receive
        piggy.withdraw(0.1 ether);
    }
}
