pragma solidity ^0.6;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Holon is Ownable {
    using SafeMath for uint256;

    //Public holon variables
    string public name;
    uint256 public uid;
    address public creator; // link back to the holonic struc
    uint256 public totallove; // max amount of love in this holon
    uint256 public castedlove; // amount of love that has been spread
    uint256 public totalrewards; // total amount of $ that has been given to this holon
    
    address payable[] internal _members;
    
    //mapping (address => uint256) toID;
    mapping (address => bool) public isMember;
    mapping (string => address) public toAddress;
    mapping (address => string) public toName;
    mapping (address => uint8) public remaininglove;
    mapping (address => uint256) public love;
    mapping (address => uint256) public rewards;
    


    //Events
    event AddedMember(address member, string name);
    event RemovedMember(address member, string name);
    event ChangedName(string from, string to);
    event HolonRewarded(string name, uint256 amount);
    
    constructor( address holonlead, string memory holonname, uint256 holonid) public {
       creator = msg.sender;
       transferOwnership( holonlead );
       name = holonname;
       uid = holonid;
       totallove = 0;
       castedlove = 0;
       totalrewards = 0;
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

    receive() external payable {
        weightedReward();
    }
   
    // this function will be called when a payment is sent to the holon
    fallback  ()
        external
        payable
        
    {
        weightedReward();
    }
    
    // same as above, but can be called explicitly
    function weightedReward ()
        payable
        public
    {
        totalrewards += msg.value;
        uint256 unitReward = msg.value.div(castedlove);
        for (uint256 i = 0; i < _members.length; i++) {
            address memberaddress = _members[i];
            uint256  amount = love[memberaddress].mul(unitReward);
            if (amount > 0){
                _transfer(memberaddress, amount);
                rewards[memberaddress]+=amount;
            }
        }
        emit HolonRewarded(name, msg.value);
    }
    
    // splits reward equally across team members
     function blanketReward()
        external
        payable
    {
        uint256 memberAmount = msg.value.div(_members.length);
        for (uint256 i = 0; i < _members.length; i++) {
            _transfer(_members[i], memberAmount);
        }
        emit HolonRewarded(name, msg.value);
    }
    
    //this function is called by members to send love to others. It builds up the weight for the reward.
    
    function sendLoveTo(address memberaddress, uint8 percentage) public{
        require (isMember[msg.sender], "Lover is not a Holon member"); // validate sender is a Holon member
        require (isMember[memberaddress], "Loved is not a Holon member"); // validate receiver is a Holon member
        require (memberaddress != msg.sender, "Lover cannot love himself.. that's selfish"); // sender can't vote for himself.
        require (remaininglove[msg.sender] >= percentage, "Not enough love remaining");
        remaininglove[msg.sender]-= percentage;
        love[memberaddress] += percentage;
        castedlove += percentage;
    }
    
    //This function must be called when the member is a holon, and can only be called by the holon lead on behalf of the entire holon
    
     function sendHolonLoveTo(address payable holonaddress, address memberaddress, uint8 percentage) public{
        
        require (isMember[holonaddress], "Lover is not a Holon member"); // validate sender is a Holon member
        require (isMember[memberaddress], "Loved is not a Holon member"); // validate receiver is a Holon member
        require (memberaddress != holonaddress, "Lover cannot love himself.. that's selfish"); // sender can't vote for himself.
        require (remaininglove[holonaddress] >= percentage, "Not enough love remaining");
        require (Holon(holonaddress).owner() == msg.sender, "Only the Holon Lead can send love on behalf of his Holon!");
        
        remaininglove[holonaddress]-= percentage;
        love[memberaddress] += percentage;
        castedlove += percentage;
    }
    
    function resetLove() onlyOwner public{
        castedlove = 0;
         for (uint256 i = 0; i < _members.length; i++) {
             address memberaddress = _members[i];
             remaininglove[memberaddress] = 100;
             love[memberaddress] = 0;
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
        remaininglove[memberaddress] = 100;

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

    function getHolonSize()
        public
        view
        returns (uint256)
    {
        return _members.length;
    }

    function listMembers()
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