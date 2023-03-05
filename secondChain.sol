//SPDX-License-Identifier:MIT
pragma solidity >0.8.7;
//Send this as value for gas 11366420000000000
//0x51de79b453d6cfb413a4E904121273787Ab20Dd2
interface IInterchainQueryRouter {
    /**
     * @param _destinationDomain Domain of destination chain
     * @param target The address of the contract to query on destination chain.
     * @param queryData The calldata of the view call to make on the destination
     * chain.
     * @param callback Callback function selector on `msg.sender` and optionally
     * abi-encoded prefix arguments.
     * @return messageId The ID of the Hyperlane message encoding the query.
     */
    function query(
        uint32 _destinationDomain,
        address target,
        bytes calldata queryData,
        bytes calldata callback
    ) external returns (bytes32);
}
interface queryOwner {
    struct addr {
        address a1;
        address a2;
        bool sts1;
        bool sts2;
        uint256 balance;
        uint256[] timestamps;
    }
    function returnOwner(uint256 _safeId) external view returns (address);
}
interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;
    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}
contract call {
    uint32 constant ethereumDomain = 5;
    // consistent across all chains
    address constant iqsRouter = 0xF782C6C4A02f2c71BB8a1Db0166FAB40ea956818;
    // The address of the ENS contract on Ethereum
    struct safe {
        address owner;
        bool status;
    }
    mapping(uint256 => safe) safeOwner;

    function setStatus(uint256 _safeId) public {
        require(msg.sender == safeOwner[_safeId].owner, "Intruder spotted");
        safeOwner[_safeId].status = true;
    }

    function getStatus(uint256 _safeId) public view returns (bool) {
        return safeOwner[_safeId].status;
    }

    /// @notice Only allow this function to be called via an IQS callback.
    modifier onlyCallback() {
        require(msg.sender == iqsRouter);
        _;
    }

    function getOwner(uint256 _safeId)
        public view
        returns (address _owner2, uint256 _safeIdd)
    {
        return (safeOwner[_safeId].owner,_safeId);
    }

    function writeOwner(uint256 _safeId, address _owner) onlyCallback external {
        safeOwner[_safeId].owner = _owner;
    }

    function queryOwner(uint256 _safeId, address _contractAddress)
        external payable
        returns (bytes32)
    {
        // uint256 _label = uint256(keccak256(_labelStr));
        bytes memory _ownerCall = abi.encodeWithSignature("returnOwner(uint256)", (_safeId));
        // The return value of ownerOf() will be automatically appended when
        // making this callback
        bytes memory _callback = abi.encodePacked(
            this.writeOwner.selector,
            _safeId
        );
        // Dispatch the call. Will result in a view call of ENS.ownerOf() on Ethereum,
        // and a callback to this.writeOwner(_label, _owner).
        bytes32 messageId =
            IInterchainQueryRouter(iqsRouter).query(
                ethereumDomain,
                _contractAddress,
                _ownerCall,
                _callback
            );
 
        IInterchainGasPaymaster igp = IInterchainGasPaymaster(
        0xF90cB82a76492614D07B82a7658917f3aC811Ac1
    );
    // Pay with the msg.value
    igp.payForGas{ value: msg.value }(
         // The ID of the message
         messageId,
         // Destination domain
         ethereumDomain,
         // The total gas amount. This should be the
         // overhead gas amount (80,000 gas) + gas used by the query being made
         80000 + 100000,
         // Refund the msg.sender
         msg.sender
     );
 
        return(messageId);
    }
}
