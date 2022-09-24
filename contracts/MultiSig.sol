//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDividends {
    function transfer(address to, uint256 amount) external;
    
    function balanceOf(address account) external view returns (uint256);
    
    function withdraw() external;
    
    function checkDividendsBalance() external view returns (uint256);
        
    function getHoldersNumber() external view returns(uint256);
        
    function getContributorByIndex(uint256 _index) external view returns(address);
        
    function totalSupply() external view returns(uint256);
}

contract MultiSig {
    // TASK 9
    uint256 currentBalance = address(this).balance;

    address Dividends = 0x097361C821B6EDaACA0D3d99a0F52d284051c75a;

    IDividends distributor = IDividends(Dividends);

    // function payout() external payable {
    //      for(uint i = 0; i < distributor.getHoldersNumber(); i++) {
    //         address balance = distributor.getContributorByIndex(i);
    //         uint256 payoutQuota = currentBalance / distributor.getHoldersNumber();
    //         distributor.transfer(balance, payoutQuota);
    //     }
    // }


    //TASK 7
    mapping(address => bool) public owner;
    mapping(address => uint256) balances;
    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => bool) public queue;
    mapping(bytes32 => mapping(address => bool)) public candidateConfirmations;
    mapping(bytes32 => mapping(address => bool)) public candidateDenials;
    mapping(bytes32 => mapping(address => bool)) public transactionConfirmations;
    mapping(bytes32 => mapping(address => bool)) public transactionDenials;
    uint256 public ownersNumber;
   // address public promotedCandidate;

    struct Candidate {
        address candidateAddress;
        uint256 candidatePromotions;
        uint256 candidateDenials;
    }

    struct Transaction {
        bytes32 transactionID;
        address to;
        uint256 amount;
        uint256 transactionPromotions;
        uint256 transactionDenials;
    }

    Candidate promotedCandidate;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    modifier onlyOwner() {
        require(owner[msg.sender], "Not an owner");
        require(!owner[address(0)], "wrong address constructor");
        _;
    }

    constructor() {
        owner[msg.sender] = true;
        ownersNumber ++;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function promoteCandidate(address _candidateAddress) external onlyOwner{
        require(_candidateAddress != address(0), "wrong address");
        require(!owner[_candidateAddress], "Already owner");
        require(promotedCandidate.candidateAddress != _candidateAddress, "Already candidate");
        promotedCandidate.candidateAddress = _candidateAddress;
        promotedCandidate.candidatePromotions =  0;
    }

    function voteForNewOwner(
        address _candidateAddress,
        bool _option
    ) external onlyOwner {
        require(promotedCandidate.candidateAddress != address(0), "wrong address");
        require(_candidateAddress == promotedCandidate.candidateAddress, "This address isn't candidate");
        
        
        if(_option) {

            promotedCandidate.candidatePromotions++;

        } else {
            promotedCandidate.candidateDenials++;

            if(promotedCandidate.candidateDenials > ownersNumber / 2) {
                promotedCandidate.candidatePromotions = 0;
                promotedCandidate.candidateDenials = 0;
                promotedCandidate.candidateAddress = address(0);
            }
        }
    }

    function addNewOwner() external onlyOwner {
        require(promotedCandidate.candidatePromotions > ownersNumber / 2, "Not enough votes");
        
        owner[promotedCandidate.candidateAddress] = true;
        ownersNumber ++;
        promotedCandidate.candidatePromotions = 0;
        promotedCandidate.candidateAddress = address(0);
    }

    function promoteTransaction(
        address _to,
        uint256 _amount,
        uint256 _timestamp
    ) external onlyOwner returns(bytes32){
        require(_to != address(0), "Can't be zero address");

        bytes32 txID = keccak256(abi.encode(
            _to,
            _amount,
            _timestamp
        ));

        queue[txID] = true;
        transactions[txID] = Transaction({
            transactionID: txID,
            to: _to,
            amount: _amount,
            transactionPromotions: 0,
            transactionDenials: 0
        });

        // promotedTransaction.transactionID = txID;
        // promotedTransaction.to = _to;
        // promotedTransaction.amount = _amount;
        // promotedTransaction.transactionPromotions = 0;
        // promotedTransaction.transactionDenials = 0;

        return txID;
    }

    function voteForTransaction(
        bytes32 _txID,
        bool _option
    ) external onlyOwner {
        require(queue[_txID], "Not promoted");
        require(!transactionConfirmations[_txID][msg.sender], "Already voted");
        Transaction storage promotedTransaction = transactions[_txID];
        if(_option) {

            promotedTransaction.transactionPromotions++;
            transactionConfirmations[_txID][msg.sender] = true;
            

        } else {
            promotedTransaction.transactionDenials++;
            transactionDenials[_txID][msg.sender] = true;
            if (promotedTransaction.transactionDenials > ownersNumber / 2) {
                promotedTransaction.transactionPromotions = 0;
                promotedTransaction.transactionDenials = 0;
            }
        }
    }

    function executeTransaction(
        bytes32 _txID,
        address _to,
        uint256 _amount
    ) external payable onlyOwner {

        Transaction storage promotedTransaction = transactions[_txID];

        require(promotedTransaction.transactionPromotions > ownersNumber / 2, "Not enough confirmations");
        require(queue[_txID], "Not promoted");

        promotedTransaction = transactions[_txID];
        distributor.transfer(_to, _amount);
        promotedTransaction.transactionPromotions = 0;
    }
}