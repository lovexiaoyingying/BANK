// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

contract Bank {
    address public owner;  // 管理员地址
    mapping(address => uint) public deposits;  // 记录每个地址的存款金额
    struct Depositor {
        address depositorAddress;
        uint depositAmount;
    }
    Depositor[3] public topDepositors;  // 存款金额前 3 名的用户信息（地址和金额）

    // 事件，用于记录存款和提款操作
    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed receiver, uint amount);

    // 构造函数，设置合约的管理员为部署者
    constructor() {
        owner = msg.sender;
    }

    // 仅管理员修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 接收 ETH 的回退函数，用户通过直接向合约地址发送 ETH 存款
    receive() external payable {
        deposits[msg.sender] += msg.value;  // 更新用户的存款记录
        updateTopDepositors(msg.sender);  // 更新前 3 名存款用户
        emit Deposit(msg.sender, msg.value);  // 触发存款事件
    }

    // 管理员提取资金的方法
    function withdraw(uint amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance in contract");
        payable(owner).transfer(amount);
        emit Withdraw(owner, amount);  // 触发提款事件
    }

    // 获取合约的余额
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 更新存款金额前 3 名的用户
    function updateTopDepositors(address user) internal {
        uint userDeposit = deposits[user];

        // 检查用户是否已经在前 3 名中
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i].depositorAddress == user) {
                topDepositors[i].depositAmount = userDeposit; // 更新该用户的存款金额
                sortTopDepositors();  // 排序
                return;
            }
        }

        // 如果用户不在前 3 名中，检查是否有资格进入前 3 名
        if (userDeposit > topDepositors[2].depositAmount) {
            // 插入新的存款人
            topDepositors[2] = Depositor(user, userDeposit);
            sortTopDepositors();  // 排序
        }
    }

    // 对 topDepositors 进行排序，确保第 1 名存款最多
    function sortTopDepositors() internal {
        // 简单的排序算法，把存款最多的用户排到前面
        for (uint i = 0; i < 3; i++) {
            for (uint j = i + 1; j < 3; j++) {
                if (topDepositors[j].depositAmount > topDepositors[i].depositAmount) {
                    Depositor memory temp = topDepositors[i];
                    topDepositors[i] = topDepositors[j];
                    topDepositors[j] = temp;
                }
            }
        }
    }

    // 获取存款金额前 3 名的用户地址和金额
    function getTopDepositors() public view returns(address[3] memory, uint[3] memory) {
        address[3] memory addresses;
        uint[3] memory amounts;

        for (uint i = 0; i < 3; i++) {
            addresses[i] = topDepositors[i].depositorAddress;
            amounts[i] = topDepositors[i].depositAmount;
        }

        return (addresses, amounts);
    }
}
