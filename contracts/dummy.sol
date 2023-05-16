//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


contract dummy {
    uint256 public value1 = 1;
    uint256 public value2 = 2;
    uint256 public value3 = 3;
    uint256 public value4 = 4;

    function getValue1() public view returns(uint256 val) {
       return(value1);
    }
    function getValue2() public view returns(uint256 val) {
       return(value2);
    }
    function getValue3() public view returns(uint256 val) {
       return(value3);
    }
    function getValue4() public view returns(uint256 val) {
       return(value4);
    }
}

