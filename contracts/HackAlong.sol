   pragma solidity ^0.6;
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Team.sol";


/* ---------------------------------------------------
 * This contract handles team creation and removal and listing
 * the team initiatior is the team captain (owner) and he is able to add and remove members 
 * from within the team contract
 * 
 * ----------------------------------------------------
 */
contract HackAlong is Ownable {
   
    mapping (string => uint256) public toId ;
    mapping (uint256 => address) public toAddress;

    address payable[] internal _teams;

    uint256 public nteams;

    event NewTeam(string name, uint256 id);

   function newTeam(string memory name) public returns (bool success)
    {
        uint256 id = toId[name];
        if (id > 0x0) //team name exists
        {
           return false;
        }
        else
        {
            nteams += 1;
            Team newteam = new Team(name, nteams);
            toAddress[nteams] = address(newteam);
            toId[name] = nteams;
            emit NewTeam(name, nteams);
        }
        return true;
    }

    function listTeams()
        external
        view
        returns (address payable[] memory)
    {
        return _teams;
    }
}