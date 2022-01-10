// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./WrappedToken.sol";
import "./WrappedTokenFactory.sol";
import "./SignatureVerifier.sol";
import "./Escrow.sol";

contract TokenBridge is Ownable, ReentrancyGuard, Pausable {
    enum Status {
        None,
        Transfer,
        Claim
    }

    WrappedTokenFactory private factory;
    SignatureVerifier private verifier;
    Escrow private escrow;
    uint256 public serviceFee;
    mapping(uint256 => Status) private processedNonces;
    mapping(address => uint256) public serviceFees;
    event Transfer(address tokenAddress, uint256 amount, uint256 nonce);
    event Claim(address tokenAddress, uint256 amount, uint256 nonce);

    constructor() Ownable() ReentrancyGuard() Pausable() {
        factory = new WrappedTokenFactory();
        verifier = new SignatureVerifier();
        escrow = new Escrow();
        serviceFee = 100000000000000;
    }

    function updateServiceFee(uint256 _newServiceFee) external onlyOwner {
        serviceFee = _newServiceFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transfer(
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external payable nonReentrant whenNotPaused {
        require(msg.value >= serviceFee, "not enough ether for service fee");

        require(_amount > 0, "amount should be more than 0");

        require(
            processedNonces[_nonce] != Status.Transfer,
            "nonce already processed"
        );
        processedNonces[_nonce] = Status.Transfer;

        require(
            verifier.recoverSigner(
                _createMessage(_amount, _nonce),
                _signature
            ) == msg.sender,
            "wrong signature"
        );

        serviceFees[msg.sender] += msg.value;

        if (_isWrappedTokenAddress(_tokenAddress)) {
            _transferBack(_tokenAddress, _amount);
        } else {
            _transfer(_tokenAddress, _amount, _nonce);
        }

        emit Transfer(_tokenAddress, _amount, _nonce);
    }

    function claim(
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external whenNotPaused {
        require(_amount > 0, "amount should be more than 0");

        require(
            processedNonces[_nonce] != Status.Claim,
            "nonce already processed"
        );
        processedNonces[_nonce] = Status.Claim;

        require(
            verifier.recoverSigner(
                _createMessage(_amount, _nonce),
                _signature
            ) == msg.sender,
            "wrong signature"
        );

        if (_isDeposited(_tokenAddress)) {
            _claimBack(_tokenAddress, _nonce);
        } else {
            _claim(_tokenAddress, _amount);
        }

        emit Claim(_tokenAddress, _amount, _nonce);
    }

    function _createMessage(uint256 _amount, uint256 _nonce)
        private
        view
        returns (bytes32)
    {
        return
            verifier.getEthSignedMessageHash(
                address(escrow),
                _amount,
                _nonce,
                block.chainid
            );
    }

    function _transferBack(address _tokenAddress, uint256 _amount) private {
        factory.unwrapToken(msg.sender, _tokenAddress, _amount);
    }

    function _transfer(
        address _tokenAddress,
        uint256 _amount,
        uint256 _nonce
    ) private {
        escrow.deposit(msg.sender, _tokenAddress, _amount, _nonce);
    }

    function _claimBack(address _tokenAddress, uint256 _nonce) private {
        escrow.withdraw(msg.sender, _tokenAddress, _nonce);
    }

    function _claim(address _tokenAddress, uint256 _amount) private {
        factory.wrapToken(msg.sender, _tokenAddress, _amount);
    }

    function _isDeposited(address _tokenAddress) private view returns (bool) {
        return escrow.isDeposited(_tokenAddress);
    }

    function _isWrappedTokenAddress(address _tokenAddress)
        private
        view
        returns (bool)
    {
        return factory.isWrappedTokenAddress(_tokenAddress);
    }

    function getTokenAddress(address _tokenAddress)
        external
        view
        returns (address)
    {
        return factory.getWrappedTokenAddress(_tokenAddress);
    }

    function getEscrowAddress() external view returns (address) {
        return address(escrow);
    }
}
