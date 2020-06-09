pragma solidity ^0.6;

/*
    Copyright 2020, Roberto Valenti

    This program is free software: you can use it, redistribute it and/or modify
    it under the terms of the Peer Production License as published by
    the P2P Foundation.
    
    https://wiki.p2pfoundation.net/Peer_Production_License

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    Peer Production License for more details.
 */


import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IHolonFactory.sol";

contract Holon is Ownable {
    using SafeMath for uint256;

    IHolonFactory factory;                          //Stores the factory of this holon

     //======================== Public holon variables
    string public name;                             //The name of the holon
    string public version = "0.1";                  //Version of the holon contract
    string public IPFSManifest;                     //IPFS Hash for the JSON containing holon manifest
    address public creator;                         //Link to the holonic parent

    //======================== Indexing Stuctures
    address payable[] internal _members;            //structure containing the addresses of the members;
   
    mapping (address => bool) public isMember;      //returns true if an address is a member;
    mapping (address => bool) public isContributor; //returns true if an address is a contributor;
    mapping (string => address) public toAddress;   //maps names to addresses
    mapping (address => string) public toName;      //maps addresses to names
   
    //======================== Structures for tracking appreciation
    uint256 public totalappreciation;               // max amount of appreciation in this holon
    mapping (address => uint256) public appreciation; //appreciaton received by a member
    mapping (address => uint8) public remainingappreciation; //appreciation left to give (max=100)

    //======================== Structures for tracking ether rewards
    mapping (address => uint256) public rewards; // ether received by each member
    uint256 public totalrewards; //total amount of ether that has been given to this holon

    //======================== Structures to hold appreciation dishing information 
    mapping (address => mapping (address => uint256)) public dished;
    mapping (address => uint256) totaldished;

    //======================== Events
    event AddedMember (address member, string name);
    event RemovedMember (address member, string name);
    event ChangedName (string from, string to);
    event HolonRewarded (string name, string token, uint256 amount);
    event MemberRewarded (address member,string token, uint256 amount);
    event Appreciated (address memberfrom, address memberto, uint256 amount);
    event Joined (address _memberaddress, string _membername);
    event dishedReset ();
    
    /// @notice Constructor to create an holon
    /// @param _holonname The address of the HolonFactory contract that
    /// @param _holonfactory The address of the HolonFactory contract that
    ///  will created the Holon contract, the factory needs to be deployed first

    constructor( string memory _holonname, address _holonfactory)  
    public 
    {
       name = _holonname;
       totalappreciation = 0;
       totalrewards = 0;
       factory = IHolonFactory(_holonfactory);
    }

    //=============================================================
    //                      Reward Functions
    //=============================================================
    //these function will be called when a payment is sent to the holon

    receive() 
        external 
        payable 
    {
        reward();
    }
   
    fallback()
        external
        payable
    {
        reward();
    }

    /// @dev Splits the ether sent to the holon according to the appreciation
    /// @notice If appreciation is not shared, it splits it equally across each member
    
    function reward()
        payable
        public
    {
        totalrewards += msg.value;
        uint256 unitReward;

        //Compute % of appreciation from dished 
        for (uint256 i = 0; i < _members.length; i++) {
            if (totaldished[_members[i]] > 0 && remainingappreciation[_members[i]] == 100)// verify if  member has dished  but has not manually set any appreciation. 
            for (uint256 j = 0; j < _members.length; j++) {
                uint8 percentage =  uint8 (dished[_members[i]][_members[j]].mul(100).div(totaldished[_members[i]]));
                appreciation[_members[j]] += percentage;
                totalappreciation+= percentage;
                remainingappreciation[_members[i]] -= percentage;
            }
        }

        if (totalappreciation > 0 ) // if appreciation was shared
            unitReward = msg.value.div(totalappreciation);
        else //if no appreciation was shared, blanket approach
            unitReward = msg.value.div(_members.length);

        for (uint256 i = 0; i < _members.length; i++) {
            uint256  amount = appreciation[_members[i]].mul(unitReward);
            if (amount > 0){
                _transfer(_members[i], amount);
                rewards[_members[i]]+=amount;
            }
        }
        emit HolonRewarded(name, "ETHER", msg.value);
    }


    /// @dev Splits the ERC20 token amount sent to the holon according to the appreciation
    /// @notice If appreciation is not shared, it splits it equally across each member (calling BlanketReward)
    function tokenReward(address _tokenaddress, uint256 _tokenamount)
        public
    {
        uint256 unitReward;
        //Load ERC20 token
        IERC20 token = IERC20(_tokenaddress);
        require (token.balanceOf(msg.sender)>= _tokenamount, "Not enough tokens in wallet");
        require (token.allowance(msg.sender, address(this))>= _tokenamount, "Not enough allowance");

        //Compute % of appreciation from dished 
        for (uint256 i = 0; i < _members.length; i++) {
            if (totaldished[_members[i]] > 0 && remainingappreciation[_members[i]] == 100)// verify if  member has dished  but has not manually set any appreciation. 
            for (uint256 j = 0; j < _members.length; j++) {
                uint8 percentage =  uint8 (dished[_members[i]][_members[j]].mul(100).div(totaldished[_members[i]]));
                appreciation[_members[j]] += percentage;
                totalappreciation+= percentage;
                remainingappreciation[_members[i]] -= percentage;
            }
        }

        if (totalappreciation > 0 ) // if appreciation was shared
            unitReward = _tokenamount.div(totalappreciation);
        else //if no appreciation was shared, blanket approach
            unitReward = _tokenamount.div(_members.length);

        for (uint256 i = 0; i < _members.length; i++) {
            uint256  amount = appreciation[_members[i]].mul(unitReward);
            if (amount > 1 ){
                if (factory.isHolon(_members[i])){
                    //Holon holon = Holon(_members[i]);
                    //holon.tokenReward(_tokenaddress, _tokenamount.mul(amount).div( 100));
                } else 
                    token.transferFrom(msg.sender,_members[i],_tokenamount.mul(amount).div( 100));
            } 
        }
        emit HolonRewarded(name, "ERC20", _tokenamount);
    }
   
    //=============================================================
    //                      Appreciative Functions
    //=============================================================
    //  these function are called to signal appreciation to others

    /// @dev Gives a percentage of appreciation to a specific member
    /// @notice Only the holon members (not contributors) can call this function
    /// @notice A member cannot send appreciation to himself
    /// @notice Sender should have enough appreciation left to give
    /// @param _memberaddress The address of the receiving member
    /// @param _percentage The amount of the appreciation to give in percentage. 

    function setAppreciation(address _memberaddress, uint8 _percentage)
        public
    {
        require (isMember[msg.sender], "Sender is not a Holon member"); // validate sender is a Holon member
        require (isMember[_memberaddress], "Reciever is not a Holon member"); // validate receiver is a Holon member
        require (_memberaddress != msg.sender, "Sender cannot appreciate himself.. that's selfish"); // sender can't vote for himself.
        require (remainingappreciation[msg.sender] >= _percentage, "Not enough appreciation remaining");
        remainingappreciation[msg.sender] -= _percentage;
        appreciation[_memberaddress] += _percentage;
        totalappreciation += _percentage;
    }

    /// @dev Dishes appreciation to other members. The appreciation of the total % will be computed based on total amount shared upon rewards
    /// @notice Only  holon members (not contributors) can call this function
    /// @notice A member cannot send appreciation to himself
    /// @param _memberaddress The address of the receiving member
    /// @param _amount The amount of the appreciation to give. This is of arbitrary scale 

    function dish(address _memberaddress, uint256 _amount) 
        public
    {
        require (isMember[msg.sender]||isContributor[msg.sender], "Sender is not a Holon member"); // validate sender is a Holon member
        require (isMember[_memberaddress], "Receiver is not a Holon member"); // validate receiver is a Holon member
        require (_memberaddress != msg.sender, "Sender cannot appreciate himself.. that's selfish"); // sender can't vote for himself.
        dished[msg.sender][_memberaddress]+= _amount;
        totaldished[msg.sender] += _amount;
    }
    
    /// @dev Gives a percentage of appreciation to a specific member on behalf of a specific holon
    /// @notice Only the sending holon lead can call this function
    /// @notice A member cannot send appreciation to himself
    /// @notice Sender should have enough appreciation left to give
    /// @param _holonaddress The address of the sending holon
    /// @param _memberaddress The address of the receiving member
    /// @param _percentage The amount of the appreciation to give in percentage. 
    
    function sendHolonAppreciationTo(address payable _holonaddress, address _memberaddress, uint8 _percentage) 
        public
    {    
        require (isMember[_holonaddress], "Sender is not a Holon member"); // validate sender is a Holon member
        require (isMember[_memberaddress], "Receiver is not a Holon member"); // validate receiver is a Holon member
        require (_memberaddress != _holonaddress, "Sender cannot appreciate himself.. that's selfish"); // sender can't vote for himself.
        require (remainingappreciation[_holonaddress] >= _percentage, "Not enough appreciation remaining");
        require (Holon(_holonaddress).owner() == msg.sender, "Only the Holon Lead can send appreciation on behalf of his Holon!");
        
        remainingappreciation[_holonaddress]-= _percentage;
        appreciation[_memberaddress] += _percentage;
        totalappreciation += _percentage;
    }
    

    /// @dev Resets appreciation of the caller
    /// @notice This is the only way to change already assigned appreciation
    function resetAppreciation() 
        public
        onlyOwner
    {
        totalappreciation = 0;
         for (uint256 i = 0; i < _members.length; i++) {
             address _memberaddress = _members[i];
             remainingappreciation[_memberaddress] = 100;
             appreciation[_memberaddress] = 0;
         }
    }

    //=============================================================
    //                      Member Management Functions
    //=============================================================
    // these function will be used by the holon lead to mantain the holon members

    function addMember(address payable _memberaddress, string memory _membername)
        public
    {
        require(isMember[_memberaddress] == false, "Member already added");
        require(toAddress[_membername] == address(0), "Name is already taken");
        _members.push(_memberaddress);
        toAddress[_membername] = _memberaddress;
        toName[_memberaddress] = _membername;
        isMember[_memberaddress] =  true;
        remainingappreciation[_memberaddress] = 100;
        transferOwnership(_memberaddress); //Yes, you heard that right. This is not a bug, it is called "Passing the crown". Any new member becomes the owner, and he is going to be the only one allowed to bring in new members, and so on. Make sure you don't add members you don't trust.

        emit AddedMember(_memberaddress, name);
    }
    
    function removeMember(address payable _memberaddress)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _members.length; i++) {
            if (_members[i] == _memberaddress) {
               _members[i] = _members[_members.length]; //swap position with last member
               break;
            }
        }
        
        _members.pop(); // remove last member
        isMember[_memberaddress] =  false;
        isContributor[_memberaddress] =  false;
        toAddress[toName[_memberaddress]] = address(0);
        
        emit RemovedMember(_memberaddress,toName[_memberaddress]);
    }


    function upgradeToMember(address _memberaddress)
        public
        onlyOwner
    {
        isContributor[_memberaddress] =  false;
        isMember[_memberaddress] =  true;
    }

    //=============================================================
    //                      Holon Merge and Fork Functions
    //=============================================================
    // these function will be used by the holon lead to mantain the holon members


    function joinHolon(address payable _memberaddress, string memory _membername)
        public
    {
        require(isMember[_memberaddress] == false, "Member was already added");
        require(toAddress[_membername] == address(0), "Name is already taken");
        _members.push(_memberaddress);
        toAddress[_membername] = _memberaddress;
        toName[_memberaddress] = _membername;
        isContributor[_memberaddress] =  true;

        emit Joined(_memberaddress, name);
    }

    // This function should be called to respect the holonic peer production license.
    function forkHolon(string memory _holonname)
         public
    {
         Holon newholon = Holon(address(uint160(factory.newHolon(_holonname))));
         newholon.addMember(address(this),"Initiators"); //Link back to origin
         this.joinHolon(address(newholon), "Fork" );// Link to fork
    }

    //=============================================================
    //                      Getters & Setters
    //=============================================================
    // these functions will be used to set and retrieve information about the holon

    // @dev Retrieves the address of the factory that created this Holon.
    /// @return The address of the factory
    
    function getFactory() 
        public 
        view 
        returns (address)
    {
        return address(factory);
    }
    
    /// @dev Changes the name of the Holon
    /// @notice only the holon lead (owner) can call this function
    /// @param _name The new name of the holon

    function changeName(string memory _name)
        public
        onlyOwner
    { 
        name = _name;
        emit ChangedName(name, _name);
    }

    /// @dev Retrieves the size of the holon in terms of members
    /// @notice contributors are included in this number
    /// @return number of members and contributors in the holon

    function getHolonSize()
        public
        view
        returns (uint256)
    {
        return _members.length;
    }

    /// @dev Retrieves the index of holon members
    /// @notice contributors are included in this list
    /// @return list with themembers and contributors of the holon

    function listMembers()
        external
        view
        returns (address payable[] memory)
    {
        return _members;
    }

    /// @dev Sets the hash of the latest IPFS manifest for the holon
    /// @notice Only the holon lead can change this!
    /// @param _IPFSHash The hash of the IPFS manifest

    function setManifest(string memory _IPFSHash)
        public
        onlyOwner
    {
       IPFSManifest = _IPFSHash;
    }

    /// @dev Internal function for transferring ether
    /// @param _dst The address of the receiver holon or member
    /// @param _amount  The amount of the ether to transfer

    function _transfer(address _dst, uint256 _amount)
        internal
    {
        (bool success, ) = _dst.call.value(_amount)("");
        require(success, "Transfer failed");
        
    }


    
    
    
}