pragma solidity ^0.6;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


/* ---------------------------------------------------
 * This contract handles team formation and split payment
 * the team initiatior is the team captain (owner) and he is able to add and remove members. 
 * Every payment sent to the team is split equally across the participants.
 * ----------------------------------------------------
 */
contract Team is Ownable {
    using SafeMath for uint256;
    
    //Public variables
    string public name;
    uint256 public uid;
    
    address payable[] internal _members;
    
    //mapping (address => uint256) toID;
    mapping (address => bool) public isMember;
    mapping (string => address) public toAddress;
    mapping (address => string) public toName;
    mapping (address => uint8) public remainingvotes;
    mapping (address => uint256) public weight ;
    mapping (address => uint256) public rewards;
    
    uint256 public totalvotes;
    uint256 public castedvotes;
    uint256 public totalrewards;

    //Events
    event AddedMember(address member, string name);
    event RemovedMember(address member, string name);
    event ChangedName(string from, string to);
    event TeamRewarded(string name, uint256 amount);
    
    constructor( string memory _name, uint256 _uid) public {
       name = _name;
       uid = _uid;
       totalvotes = 0;
       castedvotes = 0;
    }

    function getName() public view returns (string memory){
        return name;
    }
    
    function changeName(string memory _name)
        public
        onlyOwner
    {
        emit ChangedName(name, _name);
        name = _name;
    }

    function blanketReward()
        external
        payable
    {
        uint256 memberAmount = msg.value.div(_members.length);
        for (uint256 i = 0; i < _members.length; i++) {
            _transfer(_members[i], memberAmount);
        }
        emit TeamRewarded(name, msg.value);
    }
    
    fallback  ()
        external
        payable
        
    {
        totalrewards += msg.value;
        uint256 unitReward = msg.value.div(castedvotes);
        for (uint256 i = 0; i < _members.length; i++) {
            address memberaddress = _members[i];
            uint256  amount = weight[memberaddress].mul(unitReward);
            if (amount > 0){
                _transfer(memberaddress, amount);
                rewards[memberaddress]+=amount;
            }
        }
        emit TeamRewarded(name, msg.value);
    }
    
    function voteforMember(address memberaddress, uint8 percentage) public{
        require (isMember[msg.sender], "Voter is not a team member"); // validate sender is a team member
        require (isMember[memberaddress], "Voted is not a team member"); // validate receiver is a team member
        require (memberaddress != msg.sender, "Voter cannot vote for himself"); // sender can't vote for himself.
        require (remainingvotes[msg.sender] >= percentage, "Not enough votes remaining");
        remainingvotes[msg.sender]-= percentage;
        weight[memberaddress] += percentage;
        castedvotes += percentage;
    }
    
    function resetVoting() onlyOwner public{
        castedvotes = 0;
         for (uint256 i = 0; i < _members.length; i++) {
             address memberaddress = _members[i];
             remainingvotes[memberaddress] = 100;
             weight[memberaddress] = 0;
         }
    }

    function addMember(address payable memberaddress, string memory _name)
        public
        onlyOwner
    {
        _members.push(memberaddress);
        toAddress[_name] = memberaddress;
        toName[memberaddress] = _name;
        isMember[memberaddress] =  true;
        remainingvotes[memberaddress] = 100;

        emit AddedMember(memberaddress, _name);
    }
    
    function removeMember(address payable memberaddress)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _members.length; i++) {
            if (_members[i] == memberaddress) {
               _members[i] = _members[_members.length]; //swap position with last member
               break;
            }
        }
        
        _members.pop(); // remove last member
        isMember[memberaddress] =  false;
        //NOTE: without isMember it is not necessary to override names and ID, just a waste of ether.
        
        emit RemovedMember(memberaddress,toName[memberaddress]);
        
        
    }

    function teamSize()
        public
        view
        returns (uint256)
    {
        return _members.length;
    }

    function getAllMembers()
        external
        view
        returns (address payable[] memory)
    {
        return _members;
    }

    function _transfer(address dst, uint256 amount)
        internal
    {
        (bool success, ) = dst.call.value(amount)("");
        require(success, "Transfer failed");
    }
    
    
}