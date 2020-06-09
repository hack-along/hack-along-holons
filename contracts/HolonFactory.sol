pragma solidity ^0.6;

import "./Holon.sol";


/* ---------------------------------------------------
 * This contract handles Holon creation, tracking and listing
 * The Holon initiatior is the Holon lead (owner) and he is able to add and remove members 
 * from within the Holon contract
 * 
 * ----------------------------------------------------
 */
contract HolonFactory{
   

    mapping (address => bool) public isHolon;
    mapping (string => address) public toAddress;
    mapping (address => string) public toName;
    mapping (address => address[]) public holons;

    address[] internal _holons;

    uint256 public nholons;

    event NewHolon(string name, address addr);

    constructor () 
    public
    {
        nholons = 0;
    }

   function newHolon(string memory name) public returns (address holon)
    {
        if (toAddress[name] > address(0x0)) return toAddress[name];

        nholons += 1;
        Holon newholon = new Holon(name, address(this));
        newholon.transferOwnership(msg.sender);
        address addr = address(newholon);
        _holons.push(addr);
   
        holons[msg.sender].push(addr);
        toAddress[name] = addr;
        toName[addr] = name;
        isHolon[addr] = true;

        emit NewHolon(name, addr);
      
        return addr;
    }

    function listHolons()
        external
        view
        returns (address[] memory)
    {
        return _holons;
    }

    function listHolonsOf(address owner)
        public
        view
        returns (address[] memory)
    {
        return holons[owner];
    }

}
