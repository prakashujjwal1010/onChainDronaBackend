// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {
    SuperAppBase
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract OnChainDrona is SuperAppBase{

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token
    address private owner;

    string constant private _ERR_STR_LOW_FLOW_RATE = "App: flow rate too low";

    struct Participant {
        string githubUserName;
        string githubRepoName;
        uint initialAmount;
    }

    mapping (address => Participant) private addressToParticipant;

    EnumerableSet.AddressSet private _participantsSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }


    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken) {

        require(address(host) != address(0), "host is zero address");
        require(address(cfa) != address(0), "cfa is zero address");
        require(address(acceptedToken) != address(0), "acceptedToken is zero address");

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        owner = msg.sender;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);
    }

    /**************************************************************************
     * App Logic
     *************************************************************************/


    // @dev To participate in 100daysofCode Challenge
    function participate(string memory _githubUserName, string memory _githubRepoName, uint _initialAmount) public {
        Participant memory participant;
        participant.githubUserName = _githubUserName;
        participant.githubRepoName = _githubRepoName;
        addressToParticipant[msg.sender] = participant;

        //accepting stakedAmount
        _acceptedToken.transferFrom(msg.sender, address(this), _initialAmount);

        int96 flowRate = int96(_initialAmount/100);

        _participantsSet.add(msg.sender);

        //starting stream from contract to participant
        _startStream(msg.sender,flowRate);

    }

    // @dev Ping to verify manually
    function end() public {
        //requestGithubData();
        require(_participantsSet.contains(msg.sender));
        _startStream(msg.sender,flowRate);
        _participantsSet.remove(msg.sender);

    }

    /**************************************************************************
     * Constant Flow Agreements Functions
     *************************************************************************/

    /**
     * @dev Helper function to start a stream from contract to user.
     */
    function _startStream( address receiver, int96 flowRate ) internal {
        require(receiver != address(0), "New receiver is zero address");
        // @dev because our app is registered as final, we can't take downstream apps
        require(!_host.isApp(ISuperApp(receiver)), "New receiver can not be a superApp");

        // @dev create flow to receiver
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.createFlow.selector,
                _acceptedToken,
                receiver,
                flowRate,
                new bytes(0)
            ),
            "0x"
        );

    }

    /**
     * @dev Helper function to stop a stream from contract to user.
     */
    function _endStream( address receiver) internal {
        require(receiver != address(0), "New receiver is zero address");
        // @dev because our app is registered as final, we can't take downstream apps
        require(!_host.isApp(ISuperApp(receiver)), "New receiver can not be a superApp");
        // @dev delete flow to old receiver
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.deleteFlow.selector,
                _acceptedToken,
                address(this),
                receiver,
                new bytes(0)
            ),
            "0x"
        );
    }


    // utilities
    function _isAccepted(ISuperToken _superToken) private view returns (bool) {
        return address(_superToken) == address(_acceptedToken);
    }

    function _isCFAv1(address _agreementClass) private view returns (bool) {
        return ISuperAgreement(_agreementClass).agreementType()
            == keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    }

    modifier onlyHost() {
        require(msg.sender == address(_host), "RedirectAll: support only one host");
        _;
    }

    modifier onlyExpected(ISuperToken _superToken, address _agreementClass) {
        require(_isAccepted(_superToken) , "Auction: not accepted tokens");
        require(_isCFAv1(_agreementClass), "Auction: only CFAv1 supported");
        _;
    }


}
