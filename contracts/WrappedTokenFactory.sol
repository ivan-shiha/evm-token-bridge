// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./WrappedToken.sol";

contract WrappedTokenFactory is Ownable {
    mapping(address => WrappedToken) public tokens;
    mapping(address => address) public nativeAddressToWrappedAddress;
    uint256 private tokenId = 0;

    function wrapToken(
        address _sender,
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        require(
            !isWrappedTokenAddress(_tokenAddress),
            "should not be wrapped address"
        );
        WrappedToken token = _createWrappedToken(_tokenAddress);
        token.wrap(_sender, _amount);
    }

    function unwrapToken(
        address _sender,
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        require(
            isWrappedTokenAddress(_tokenAddress),
            "not wrapped token address"
        );
        WrappedToken token = WrappedToken(_tokenAddress);
        token.unwrap(_sender, _amount);
    }

    function _createWrappedToken(address _tokenAddress)
        private
        returns (WrappedToken)
    {
        WrappedToken token;
        address wrappedTokenAddress = getWrappedTokenAddress(_tokenAddress);
        if (wrappedTokenAddress != address(0)) {
            token = WrappedToken(wrappedTokenAddress);
        } else {
            token = new WrappedToken(
                _tokenAddress,
                _generateName(),
                _generateSymbol()
            );
            wrappedTokenAddress = address(token);
        }
        tokens[wrappedTokenAddress] = token;
        nativeAddressToWrappedAddress[_tokenAddress] = wrappedTokenAddress;
        tokenId++;
        return token;
    }

    function isWrappedTokenAddress(address _tokenAddress)
        public
        view
        returns (bool)
    {
        return address(tokens[_tokenAddress]) != address(0);
    }

    function getWrappedTokenAddress(address _tokenAddress)
        public
        view
        returns (address)
    {
        return nativeAddressToWrappedAddress[_tokenAddress];
    }

    function _generateName() private view returns (string memory) {
        return
            string(abi.encodePacked("WrappedToken", Strings.toString(tokenId)));
    }

    function _generateSymbol() private view returns (string memory) {
        return string(abi.encodePacked("w", Strings.toString(tokenId)));
    }
}
