   pragma solidity ^0.6;
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Holon.sol";


/* ---------------------------------------------------
 * This contract handles Holon creation, tracking and listing
 * The Holon initiatior is the Holon captain (owner) and he is able to add and remove members 
 * from within the Holon contract
 * 
 * ----------------------------------------------------
 */
contract HackAlong is Ownable {
   
    mapping (string => uint256) public toId ;
    mapping (uint256 => address) public toAddress;

    address payable[] internal _holons;

    uint256 public nholons;

    event NewHolon(string name, uint256 id);
    
    constructor () public{
        nholons = 0;
    }

   function newHolon(string memory name) public returns (bool success)
    {
        uint256 id = toId[name];
        if (id > 0x0) //Holon name exists
        {
           return false;
        }
        else
        {
            nholons += 1;
            Holon newholon = new Holon(msg.sender, name, nholons);
            toAddress[nholons] = address(newholon);
            toId[name] = nholons;
            _holons.push(address(newholon));
            emit NewHolon(name, nholons);
        }
        return true;
    }

    function listHolons()
        external
        view
        returns (address payable[] memory)
    {
        return _holons;
    }
}