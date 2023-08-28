// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract Extra {
     function removeArrayElement(address[] memory _arr, address _elem) public pure returns (address[] memory) {
        uint length = _arr.length;
        address[] memory newArr = new address[](length - 1);
        uint newIndex = 0;

        for (uint i = 0; i < length; i++) {
            if (_arr[i] != _elem) {
                newArr[newIndex] = _arr[i];
                newIndex++;
            }
        }

        return newArr;
    }
}