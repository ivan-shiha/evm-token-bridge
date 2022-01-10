// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SignatureVerifier is Ownable {
    function getEthSignedMessageHash(
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce,
        uint256 _chainId
    ) external pure returns (bytes32) {
        return
            _prefixed(
                keccak256(
                    abi.encodePacked(_tokenAddress, _amount, _nonce, _chainId)
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) external pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _prefixed(bytes32 _hash) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function _splitSignature(bytes memory _signature)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(_signature.length == 65, "invalid signature length");

        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }

        return (v, r, s);
    }
}
