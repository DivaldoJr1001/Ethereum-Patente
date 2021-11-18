// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

function append3(string memory a, string memory b, string memory c) pure returns (string memory) {
    return string(abi.encodePacked(a, b, c));
}