
pragma solidity ^0.6;

import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IHolonFactory.sol";

 contract Holon is Ownable {
    using SafeMath for uint256;

    IHolonFactory factory;

    //Public holon variables
    string public name;
    uint256 public uid;
    address public creator; // link back to the holonic struc
    uint256 public totallove; // max amount of love in this holon
    uint256 public castedlove; // amount of love that has been spread
    uint256 public totalrewards; // total amount of $ that has been given to this holon
    
    address payable[] internal _members;
    address payable[] internal _contributors;
    
    bool isOpen;

    //mapping (address => uint256) toID;
    mapping (address => bool) public isMember;
    mapping (string => address) public toAddress;
    mapping (address => string) public toName;
    mapping (address => uint8) public remaininglove;
    mapping (address => uint256) public love;
    mapping (address => uint256) public rewards;
    mapping (address => mapping (address => uint256)) public appreciation;
    mapping (address => uint256) sentappreciation;

    //Events
    event AddedMember(address member, string name);
    event RemovedMember(address member, string name);
    event ChangedName(string from, string to);
    event HolonRewarded(string name, uint256 amount);
    event MemberRewarded(address member, uint256 amount);
    
    constructor( address holonlead, string memory holonname, uint256 holonid)  public {
       transferOwnership( holonlead );
       name = holonname;
       uid = holonid;
       totallove = 0;
       castedlove = 0;
       totalrewards = 0;
       factory = IHolonFactory(msg.sender);
    }

    function getName() public view returns (string memory){
        return name;
    }

    function getFactory() public view returns (address){
        return address(factory);
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

        // splits reward equally across team members
     function blanketReward()
        payable
        public
    {
        if (msg.value < 1000000) return;
        uint256 memberAmount = msg.value.div(_members.length);
        for (uint256 i = 0; i < _members.length; i++) {
            _transfer(_members[i], memberAmount);
        }
        emit HolonRewarded(name, msg.value);
    }
    
    
    // same as above, but can be called explicitly
    function weightedLoveReward ()
        payable
        public
    {
        totalrewards += msg.value;
        uint256 unitReward;

        if (castedlove > 0 ) // if love was shared
            unitReward = msg.value.div(castedlove);
        else //if no love was shared, blanket approach
            unitReward = msg.value.div(_members.length);

        for (uint256 i = 0; i < _members.length; i++) {
            uint256  amount = love[_members[i]].mul(unitReward);
            if (amount > 0){
                _transfer(_members[i], amount);
                rewards[_members[i]]+=amount;
            }
        }
        emit HolonRewarded(name, msg.value);
    }

    // function createHolon(string memory name)
    //     public
    // {
    //     HolonFactory factory = HolonFactory(this.creator);
    //     factory.newHolon(name);
    // }

    function weightedReward ()
        payable
        public
    {

        uint256 activemembers = 0;
        for (uint256 i = 0; i < _members.length; i++) {
          if (sentappreciation[_members[i]] > 0)
                activemembers++;
        }

        if (activemembers > 0)
        {
            for (uint256 i = 0; i < _members.length; i++) {
                //calculate reward % for memeber i:
                //1) loop and see what flow they get
                uint256  amount = 0;
                for (uint256 j = 0; j < _members.length; j++){
                    if (appreciation[_members[j]][_members[i]] > 0)
                        amount += appreciation[_members[j]][_members[i]].mul(100).div(sentappreciation[_members[j]]);
                }
                amount = amount.div(activemembers);
                if (amount > 1 ){
                    _transfer(_members[i], msg.value.mul(amount).div( 100));
                    emit MemberRewarded(_members[i],msg.value.mul(amount).div( 100));
                }
            }
            emit HolonRewarded(name, msg.value);
        }
        else{
            blanketReward();
        }

    }

    function weightedTokenReward (address tokenaddress, uint256 tokenamount)
        payable
        public
    {
        IERC20 token = IERC20(tokenaddress);
        require (token.balanceOf(msg.sender)>= tokenamount, "not enough tokens in wallet");
        require (token.allowance(msg.sender, address(this))>= tokenamount, "not enough allowance");

        //compute currently active members;
        uint256 activemembers = 0;
        for (uint256 i = 0; i < _members.length; i++) {
          if (sentappreciation[_members[i]] > 0)
                activemembers++;
        }

        if (activemembers > 0)
        {
            for (uint256 i = 0; i < _members.length; i++) {
                //calculate reward % for memeber i:
                //1) loop and see what flow they get
                uint256  amount = 0;
                for (uint256 j = 0; j < _members.length; j++){
                    if (appreciation[_members[j]][_members[i]] > 0)
                        amount += appreciation[_members[j]][_members[i]].mul(100).div(sentappreciation[_members[j]]);
                }
                amount = amount.div(activemembers);

                if (amount > 1 ){
                    
                    //(bool success, bytes memory returnData) = _members[i].call(abi.encode("getHolonSize()"));
                    //if (success ){ //is Holon
                        if (factory.isHolon(_members[i])){
                            Holon holon = Holon(_members[i]);
                            holon.weightedTokenReward(tokenaddress, tokenamount.mul(amount).div( 100));
                        } else 
                            token.transferFrom(msg.sender,_members[i],tokenamount.mul(amount).div( 100));
                        
                    emit MemberRewarded(_members[i],tokenamount.mul(amount).div( 100));
                }
            }
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

    function appreciate(address memberaddress, uint256 amount) public{
        require (isMember[msg.sender], "Lover is not a Holon member"); // validate sender is a Holon member
        require (isMember[memberaddress], "Loved is not a Holon member"); // validate receiver is a Holon member
        require (memberaddress != msg.sender, "Lover cannot love himself.. that's selfish"); // sender can't vote for himself.
        sentappreciation[msg.sender] += amount;
        appreciation[msg.sender][memberaddress]+= amount;
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

    function addMember(address payable memberaddress, string memory membername)
        public
        onlyOwner
    {
        require(isMember[memberaddress] == false, "Member already added");
        require(toAddress[membername] == address(0), "Name is already taken");
        _members.push(memberaddress);
        toAddress[membername] = memberaddress;
        toName[memberaddress] = membername;
        isMember[memberaddress] =  true;
        remaininglove[memberaddress] = 100;

        emit AddedMember(memberaddress, name);
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