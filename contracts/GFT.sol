/*
Requirements:
· total 100,000,000.00, 8 decimal,
· white list: only people in white list can transfer or receive GFT
· admin functions: move token, manage white list
.*/


pragma solidity >=0.4.22 <0.6.0;

import "./EIP20Interface.sol";

contract GFT is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    mapping (address => bool) public whitelisted; //Addresses that are allowed to transfer or receive GFT
    address[] whitelistAddresses; //keep track of addresses in the whitelist
    address public admin;

    event Whitelisted(address indexed whitelistedAddress);
    event RemovedFromWhitelist(address indexed whitelistedAddress);


    modifier isOnWhiteList(address user) {
        require(whitelisted[user] == true || user == admin);
        _;
    }

    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

    constructor(
        uint _totalSupply,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        address _admin
    ) public {
        totalSupply = _totalSupply;
        balances[_admin] = totalSupply;                  // Give the creator all initial tokens
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        admin = _admin;
    }

    function addToWhiteList(address approvedAddress) public adminOnly {
        require(!whitelisted[approvedAddress]);
        whitelistAddresses.push(approvedAddress);
        whitelisted[approvedAddress] = true;
        emit Whitelisted(approvedAddress);
    }

    function getWhiteListedAddresses() public view returns(address[] memory) {
        return whitelistAddresses;
    }

    function removeFromWhiteList(address removalAddress) public adminOnly {
        whitelisted[removalAddress] = false;
        for(uint i = 0; i < whitelistAddresses.length; i++) {
            if(removalAddress == whitelistAddresses[i]) {
                delete whitelistAddresses[i];
                emit RemovedFromWhitelist(whitelistAddresses[i]);
                return;
            }
        }
    }

    function transfer(address _to, uint256 _value) public isOnWhiteList(_to) returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public isOnWhiteList(_to) returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        //must have the allowance to move the tokens or be the admin
        require(balances[_from] >= _value && (allowance >= _value || msg.sender == admin));
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public isOnWhiteList(_spender) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}