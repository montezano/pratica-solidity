pragma solidity ^0.4.11;

contract LegalBet {
    
    address owner = msg.sender;
    uint public creation_time = now;
    uint public bet_balance = 0;
    Stages public current_stage = Stages.NOT_INIT;
    mapping (address => uint256) bet_ammount;
    address[] public bet_number;
    uint public price = 2 ether;
    
    enum Stages {
        NOT_INIT,
        WAITING_BETS
    }
    
    modifier onlyOwner(address account) {
        require(msg.sender == account);
        _;
    }
    
    modifier correctStage(Stages stage) {
        require(stage == current_stage);
        _;
    }
    
    function initLegalBet() public
    onlyOwner(owner)
    correctStage(Stages.NOT_INIT) {
        current_stage = Stages.WAITING_BETS;
    }
    
     modifier costs(uint _price) {
        if (msg.value >= _price) {
            _;
        }
    }
    
    function () public
    payable
    costs(price)
    correctStage(Stages.WAITING_BETS) {
        bet_ammount[msg.sender] += msg.value;
        bet_number.push(msg.sender);
        bet_balance += msg.value;
    }
    
    modifier minBalance(uint256 value) {
        require(bet_balance >= value);
        _;
    }
    
    function finilizeBets(uint256 winner) public 
    onlyOwner(owner)
    correctStage(Stages.WAITING_BETS)
    minBalance(1 szabo)
    {
        address winner_addr = bet_number[winner%bet_number.length];
        uint256 prize = ((bet_balance - 1 szabo) * 95 ) / 100;
        if(winner_addr.call.gas(2000000).value(prize)()) {
            current_stage = Stages.NOT_INIT;
            bet_balance = 0;
        }
    }
}

contract ConjunctContract {
    
    address private account1;
    address private account2;
    
    struct Payment {
        address initiated_by;
        uint256 payment_value;
    }
    mapping (address => Payment) public payments;  
    
    constructor(address sec_owner) public payable {
        account1 = msg.sender;
        account2 = sec_owner;
    }   
    
    function verifyOwnership(address account) public view returns(bool) {
        if(account1 == account || account2 == account){
            return true;
        }   
    }
    
    modifier owningAccount(address account) {
        require(account == account1 || account == account2);
        _;
    }
    
    function payment(address send_address, uint256 payment_value) 
    public
    owningAccount(msg.sender)
    {   
        if(payments[send_address].initiated_by != account1 &&
            payments[send_address].initiated_by != account2) {
                payments[send_address] = Payment(msg.sender, payment_value);
        } else {
            if(payments[send_address].initiated_by != msg.sender &&
                payments[send_address].payment_value == payment_value) {
                    if(send_address.call.gas(2500000).value(payment_value)()) {
                        delete payments[send_address];
                    }
            }
        }
    }
    
    function withdraw() public owningAccount(msg.sender) {
        uint256 withdraw_value = address(this).balance - 150000; 
        if(!account1.call.gas(2500000).value(withdraw_value/2)()) {
            revert();
        }
        if(!account2.call.gas(2500000).value(withdraw_value/2)()) {
            revert();
        }
    }
    
    function () public payable {
    }
    
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
}

// wei to ether: 1000000000000000000