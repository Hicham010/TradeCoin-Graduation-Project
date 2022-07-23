// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleControl is AccessControl {
    // We use keccak256 to create a hash that identifies this constant in the contract
    bytes32 public constant TOKENIZER_ROLE = keccak256("TOKENIZER_ROLE"); // hash a MINTER_ROLE as a role constant
    bytes32 public constant PRODUCT_HANDLER_ROLE = keccak256("PRODUCT_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant
    bytes32 public constant INFORMATION_HANDLER_ROLE = keccak256("INFORMATION_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant

    // Constructor of the RoleControl contract
    constructor (address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin

        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > MINTER_ROLE > BURNER_ROLE > no role
        _setRoleAdmin(TOKENIZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCT_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(INFORMATION_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Remove a user as a admin
    function removeAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or Tokenizer
    function isTokenizerOrAdmin(address account) public virtual view returns(bool) {
        return (hasRole(TOKENIZER_ROLE, account) || hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or Tokenizer
    modifier onlyTokenizerOrAdmin() {
        require(isTokenizerOrAdmin(msg.sender), "Restricted to FTokenizer or admins.");
        _;
    }

    // Add a user address as a Tokenizer
    function addTokenizer(address account) public virtual onlyAdmin {
        grantRole(TOKENIZER_ROLE, account);
    }
    // remove a user address as a Tokenizer
    function removeTokenizer(address account) public virtual onlyAdmin {
        revokeRole(TOKENIZER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or ProductHandlers
    function isProductHandlerOrAdmin(address account) public virtual view returns(bool) {
        return (hasRole(PRODUCT_HANDLER_ROLE, account) || hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or ProductHandlers
    modifier onlyProductHandlerOrAdmin() {
        require(isProductHandlerOrAdmin(msg.sender), "Restricted to ProductHandlers or admins.");
        _;
    }

    // Add a user address as a ProductHandlers
    function addProductHandler(address account) public virtual onlyAdmin {
        grantRole(PRODUCT_HANDLER_ROLE, account);
    }
    // remove a user address as a ProductHandlers
    function removeProductHandler(address account) public virtual onlyAdmin {
        revokeRole(PRODUCT_HANDLER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or InformationHandlers
    function isInformationHandlerOrAdmin(address account) public virtual view returns(bool) {
        return (hasRole(INFORMATION_HANDLER_ROLE, account) || hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or InformationHandlers
    modifier onlyInformationHandlerOrAdmin() {
        require(isInformationHandlerOrAdmin(msg.sender), "Restricted to InformationHandlers or admins.");
        _;
    }

    // Add a user address as a InformationHandlers
    function addInformationHandler(address account) public virtual onlyAdmin {
        grantRole(INFORMATION_HANDLER_ROLE, account);
    }
    // remove a user address as a InformationHandlers
    function removeInformationHandler(address account) public virtual onlyAdmin {
        revokeRole(INFORMATION_HANDLER_ROLE, account);
    }
}