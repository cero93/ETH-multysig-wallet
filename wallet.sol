pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {
    address[] public owners;
    uint limit;
    
    struct Transfer{
        uint amount;
        address payable receiver;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }
    
    Transfer[] transferRequests;
    
    //events to be logged to check (with emit command) what is happening through executions 
    event transferRequestCreated(uint _id, uint _amount, address _initiator, address _receiver);
    event Approvalreceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);
    
    mapping(address => mapping(uint => bool)) approvals;
    
     //Should initialize the owners list and the number of approvals-at the deploy state
    constructor(address[] memory _owners, uint _limit) {
        owners=_owners;
        limit=_limit;//num of approvals
    }
    
    //Empty function-anyone can deposit
    function deposit() public payable {}
    
    //Should only allow people in the owners list to continue the execution.
    //It should be pasted like this:
    //different addresses, separated with comas and each in double quotations, all of them in arrays
    //["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c"]
    modifier onlyOwners(){
        //necessarry to set to false at the beginning, can be anything:
        bool owner=false;
        //after that try to find if it is in the list of owners:
        for (uint i=0;i<owners.length;i++){
            //if msg.sender is anyone adress from the owners list
           if (owners[i]==msg.sender){
               owner=true;
           } 
        }
        //out of the loop we reqire the condition is true
        require(owner==true);
        _;//in oreder to continue to execution
    }
    
    //Create an instance of the Transfer struct and add it to the transferRequests array
    //the right condition is made by "modifier onlyOwners"
    function createTransfer(uint _amount, address payable _receiver) public onlyOwners {
        emit transferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);
        //importing in transferRequests array (struct)
        //first 'transferRequests.length' is zero when you start and 1,2,3... later on which is id 
        transferRequests.push(
            Transfer(_amount,_receiver,0,false,transferRequests.length));
    }
    
    //input transfer id you want to approve-is saved in approvals in double mapping
    function approve(uint _id) public onlyOwners {
        //double mapping priciple: approvals:[address]->[mapping]==true/false
        //make sure msg.sender did not voted for this _id yet and not twice
        require(approvals[msg.sender][_id]==false);
        //transferRequests is boolean, number id means which number of existing booleans it is
        //An owner should not be able to vote on a transfer request that has already been sent.
        require(transferRequests[_id].hasBeenSent==false);
        //now we finally set, after requirements, that condition is true, msg.sender approved this transfer id
        approvals[msg.sender][_id]=true;
        //increasing approvals from 0 to 1
        transferRequests[_id].approvals++;
        
        emit Approvalreceived(_id, transferRequests[_id].approvals, msg.sender);
        //chech if we reach the number of approvals (defined in state variable "limit")
        if(transferRequests[_id].approvals>=limit){
            //set to true
            transferRequests[_id].hasBeenSent=true;
            //now make a transfer for the specified amount
            transferRequests[_id].receiver.transfer(transferRequests[_id].amount);
            emit TransferApproved(_id);
        }
    }
    
    //Should return all transfer requests
    function getTransferRequests() public view returns (Transfer[] memory){
        return transferRequests;
    }
    
    //current contract balance
    function getContractBalance() public view returns (uint){
        return address(this).balance;
    }
}
