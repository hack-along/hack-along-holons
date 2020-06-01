pragma solidity ^0.6;
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Holon.sol";


/* ---------------------------------------------------
 * This contract handles Holon creation, tracking and listing
 * The Holon initiatior is the Holon lead (owner) and he is able to add and remove members 
 * from within the Holon contract
 * 
 * ----------------------------------------------------
 */
contract HolonFactory is Ownable {
   
    mapping (string => address) public toAddress;
    mapping (address => address[]) public holons;

    mapping (address => bool) public isHolon;

    address payable[] internal _holons;

    uint256 public nholons;

    event NewHolon(string name, uint256 id);
    
    constructor () public{
        nholons = 0;
    }

   function newHolon(string memory name) public returns (address holon)
    {
        if (toAddress[name] > address(0x0)) return toAddress[name];
    
        nholons += 1;
        Holon newholon = new Holon(msg.sender, name, nholons);
        _holons.push(address(newholon));

        holons[msg.sender].push(address(newholon));
        toAddress[name] = address(newholon);
        isHolon[address(newholon)] = true;

        emit NewHolon(name, nholons);
      
        return toAddress[name];
    }



    function listHolons()
        external
        view
        returns (address payable[] memory)
    {
        return _holons;
    }

    function listHolonsOf(address member)
        external
        view
        returns (address[] memory)
    {
        return holons[member];
    }

    function getHolon(uint256 holonid) public view returns (address){
        return _holons[holonid];
    }

}