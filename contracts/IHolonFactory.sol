pragma solidity ^0.6;


/* ---------------------------------------------------
 * This contract handles Holon creation, tracking and listing
 * The Holon initiatior is the Holon lead (owner) and he is able to add and remove members 
 * from within the Holon contract
 * 
 * ----------------------------------------------------
 */
contract IHolonFactory {
   
    mapping (address => bool) public isHolon;

    uint256 public nholons;

   function newHolon(string memory name) public returns (address holon)
    {}

    function listHolons()
        external
        view
        returns (address payable[] memory)
    {}

    function listHolonsOf(address member)
        external
        view
        returns (address[] memory)
    {}

    function getHolon(uint256 holonid) public view returns (address){
    }

}