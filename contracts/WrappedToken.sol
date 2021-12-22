// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WrappedToken is ERC20 {
    address public immutable nativeTokenAddress;
    address private factory;

    modifier onlyFactory() {
        require(msg.sender == factory, "not the factory");
        _;
    }

    constructor(
        address _nativeTokenAddress,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        require(_nativeTokenAddress != address(0), "not existing token");
        nativeTokenAddress = _nativeTokenAddress;
        factory = msg.sender;
    }

    function wrap(address _receiver, uint256 _amount) external onlyFactory {
        _mint(_receiver, _amount);
    }

    function unwrap(address _sender, uint256 _amount) external onlyFactory {
        _burn(_sender, _amount);
    }
}
