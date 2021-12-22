// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Escrow is Ownable {
    enum Status {
        NONE,
        DEPOSITED,
        WITHDRAWN
    }
    struct DepositInfo {
        address owner;
        uint256 amount;
        uint256 chainId;
        Status status;
    }

    using EnumerableSet for EnumerableSet.UintSet;
    mapping(address => EnumerableSet.UintSet) private tokenAddressToDepositId;
    mapping(uint256 => DepositInfo) private deposits;

    function deposit(
        address _sender,
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce
    ) external onlyOwner {
        require(
            !_depositExists(_tokenAddress, _nonce),
            "deposit already exists"
        );

        tokenAddressToDepositId[_tokenAddress].add(_nonce);
        deposits[_nonce] = DepositInfo(
            _sender,
            _amount,
            block.chainid,
            Status.DEPOSITED
        );

        ERC20 token = ERC20(_tokenAddress);
        token.transferFrom(_sender, address(this), _amount);
    }

    function withdraw(
        address _sender,
        address _tokenAddress,
        uint256 _nonce
    ) external onlyOwner {
        require(
            _depositExists(_tokenAddress, _nonce),
            "deposit does not exist"
        );

        DepositInfo memory depositInfo = deposits[_nonce];

        require(depositInfo.chainId == block.chainid, "wrong chain id");
        require(depositInfo.owner == _sender, "not the owner of deposit");
        require(
            depositInfo.status == Status.DEPOSITED,
            "deposit already withdrawn"
        );

        depositInfo.status = Status.WITHDRAWN;
        deposits[_nonce] = depositInfo;

        ERC20 token = ERC20(_tokenAddress);
        token.transfer(_sender, depositInfo.amount);
    }

    function _depositExists(address _tokenAddress, uint256 _nonce)
        private
        view
        onlyOwner
        returns (bool)
    {
        return tokenAddressToDepositId[_tokenAddress].contains(_nonce);
    }

    function isDeposited(address _tokenAddress)
        external
        view
        onlyOwner
        returns (bool)
    {
        return tokenAddressToDepositId[_tokenAddress].length() != 0;
    }
}
