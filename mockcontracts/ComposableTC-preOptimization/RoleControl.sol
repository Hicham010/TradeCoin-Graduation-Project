// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleControl is AccessControl {
    bytes32 public constant TOKENIZER_ROLE = keccak256("TOKENIZER_ROLE"); // hash a MINTER_ROLE as a role constant
    bytes32 public constant TRANSFORMATION_HANDLER_ROLE =
        keccak256("TRANSFORMATION_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant
    bytes32 public constant INFORMATION_HANDLER_ROLE =
        keccak256("INFORMATION_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant

    // Constructor of the RoleControl contract
    constructor(address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin

        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > MINTER_ROLE > BURNER_ROLE > no role
        _setRoleAdmin(TOKENIZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TRANSFORMATION_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(INFORMATION_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Remove a user as a admin
    function removeAdmin(address account) external onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or Tokenizer
    function isTokenizer(address account) public view returns (bool) {
        return (hasRole(TOKENIZER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or Tokenizer
    modifier onlyTokenizer() {
        require(isTokenizer(msg.sender), "Restricted to Tokenizers and admin");
        _;
    }

    // Add a user address as a Tokenizer
    function addTokenizer(address account) external onlyAdmin {
        grantRole(TOKENIZER_ROLE, account);
    }

    // remove a user address as a Tokenizer
    function removeTokenizer(address account) external onlyAdmin {
        revokeRole(TOKENIZER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or ProductHandlers
    function isTransformationHandler(address account)
        public
        view
        returns (bool)
    {
        return (hasRole(TRANSFORMATION_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or ProductHandlers
    modifier onlyTransformationHandler() {
        require(
            isTransformationHandler(msg.sender),
            "Restricted to Transformation Handlers or admins"
        );
        _;
    }

    // Add a user address as a ProductHandlers
    function addTransformationHandler(address account) external onlyAdmin {
        grantRole(TRANSFORMATION_HANDLER_ROLE, account);
    }

    // remove a user address as a ProductHandlers
    function removeTransformationHandler(address account) external onlyAdmin {
        revokeRole(TRANSFORMATION_HANDLER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or InformationHandlers
    function isInformationHandler(address account) public view returns (bool) {
        return (hasRole(INFORMATION_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or InformationHandlers
    modifier onlyInformationHandler() {
        require(
            isInformationHandler(msg.sender),
            "Restricted to Information Handlers or admins"
        );
        _;
    }

    // Add a user address as a InformationHandlers
    function addInformationHandler(address account) external onlyAdmin {
        grantRole(INFORMATION_HANDLER_ROLE, account);
    }

    // remove a user address as a InformationHandlers
    function removeInformationHandler(address account) external onlyAdmin {
        revokeRole(INFORMATION_HANDLER_ROLE, account);
    }
}
