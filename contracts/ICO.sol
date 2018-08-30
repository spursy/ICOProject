pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowsale {
    address public beneficiary; //募资的收款方
    uint public fundingGoal;  // 募资额度
    uint public amountRaised; // 参与数量
    uint public deadline; // 截止时间

    uint public price; // token的汇率
    token public tokenReward; // 要卖的token

    mapping(address => uint256) public balanceOf;

    bool fundingGoalReached = false; // 众筹是否达标
    bool crowsaleClosed = false; // 众筹是否结束

    /**
    跟踪信息
    */
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribute);
    
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint finneyCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;    
        price = finneyCostOfEachToken * 1 finney;
        tokenReward = token(addressOfTokenUsedAsReward); // 传入已发布的合约地址来创建实例
    }

    /**
        Fallback function
        无论何时当向合约转账时都会触发Fallback function
     */
    function () public payable {
        require(!crowsaleClosed, "sale closed is not");
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline()  {
        if (now >= deadline) _;
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowsaleClosed = true;
    }

    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
}