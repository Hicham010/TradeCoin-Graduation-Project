// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

////import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

////import "../../utils/introspection/IERC165.sol";

////import "../IERC721.sol";

interface ITradeCoinTokenizer {
    event MintToken(
        uint256 indexed tokenId,
        address indexed tokenizer,
        string commodity,
        uint256 amount,
        string unit
    );

    event IncreaseCommodity(uint256 indexed tokenId, uint256 amountIncrease);

    event DecreaseCommodity(uint256 indexed tokenId, uint256 amountDecrease);

    function mintToken(
        string calldata _commodity,
        uint256 _amount,
        string calldata _unit
    ) external;

    function increaseAmount(uint256 tokenId, uint256 amountIncrease) external;

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease) external;

    function burnToken(uint256 tokenId) external;
}

////import "./IERC721.sol";
////import "./IERC721Receiver.sol";
////import "./extensions/IERC721Metadata.sol";
////import "../../utils/Address.sol";
////import "../../utils/Context.sol";
////import "../../utils/Strings.sol";
////import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165 {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface ITradeCoin {
    enum State {
        NonExistent,
        Created,
        PendingProcess,
        Processing,
        PendingTransport,
        Transporting,
        PendingStorage,
        Stored,
        EndOfLife
    }

    // Definition of Events
    event MintCommodity(
        uint256 indexed tokenId,
        address indexed tokenizer,
        uint256 tokenIdTCT,
        string commodityName,
        uint256 amount,
        string unit
    );

    event CommodityTransformation(
        uint256 indexed tokenId,
        address indexed transformer,
        string transformation
    );

    event CommodityTransformationDecrease(
        uint256 indexed tokenId,
        address indexed transformer,
        string transformation,
        uint256 amountDecrease
    );

    event SplitCommodity(
        uint256 indexed tokenId,
        address indexed splitter,
        uint256[] newTokenIds
    );

    event BatchCommodities(
        uint256 indexed batchedToken,
        address indexed batcher,
        uint256[] tokenIds
    );

    event InitializeSale(
        uint256 indexed tokenIdTCT,
        address indexed seller,
        address indexed buyer,
        uint256 priceInWei,
        bool payInFiat
    );

    event PaymentOfToken(
        uint256 indexed tokenIdTCT,
        address indexed payer,
        uint256 priceInWei
    );

    event CompleteSale(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller
    );

    event BurnCommodity(uint256 indexed tokenId, address indexed burner);

    event ChangeStateAndHandler(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address newCurrentHandler,
        State newState
    );

    event QualityCheckCommodity(
        uint256 indexed tokenId,
        address indexed checker,
        string data
    );

    event LocationOfCommodity(
        uint256 indexed tokenId,
        address indexed locationSignaler,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    );

    event AddInformation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string data
    );

    event CommodityOutOfChain(
        uint256 indexed tokenId,
        address indexed funCaller
    );

    function initializeSale(
        address owner,
        address handler,
        uint256 tokenIdOfTokenizer,
        uint256 priceInWei
    ) external;

    function paymentOfToken(uint256 tokenIdOfTokenizer) external payable;

    function mintCommodity(uint256 tokenIdOfTokenizer) external;

    function addTransformation(uint256 _tokenId, string memory transformation)
        external;

    function addTransformationDecrease(
        uint256 _tokenId,
        string memory transformation,
        uint256 amountDecrease
    ) external;

    function changeCurrentHandlerAndState(
        uint256 _tokenId,
        address newHandler,
        State newCommodityState
    ) external;

    function addInformationToCommodity(uint256 _tokenId, string memory data)
        external;

    function checkQualityOfCommodity(uint256 _tokenId, string memory data)
        external;

    function confirmCommodityLocation(
        uint256 _tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external;

    function burnCommodity(uint256 _tokenId) external;

    function batchCommodities(uint256[] memory _tokenIds) external;

    function splitCommodity(uint256 _tokenId, uint256[] memory partitions)
        external;
}

////import "@openzeppelin/contracts/access/AccessControl.sol";

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
    function removeTransformationHandler(address account) public onlyAdmin {
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
    function addInformationHandler(address account) public onlyAdmin {
        grantRole(INFORMATION_HANDLER_ROLE, account);
    }

    // remove a user address as a InformationHandlers
    function removeInformationHandler(address account) public onlyAdmin {
        revokeRole(INFORMATION_HANDLER_ROLE, account);
    }
}

////import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
////import "./TradeCoinTokenizerV2.sol";
////import "./RoleControl.sol";
////import "./interfaces/ITradeCoin.sol";

////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinV4 is ERC721, RoleControl, ITradeCoin {
    uint256 public tokenCounter;
    TradeCoinTokenizerV2 public tradeCoinTokenizer;

    struct TradeCoinCommodity {
        uint256 amount;
        State state;
        bytes4 hashOfProperties;
        address currentHandler;
    }

    struct CommoditySale {
        address seller;
        address owner;
        address handler;
        bool isPaid;
        uint256 priceInWei;
    }

    mapping(uint256 => TradeCoinCommodity) public tradeCoinCommodity;
    mapping(uint256 => CommoditySale) public commoditySaleQueue;

    modifier isCurrentHandler(uint256 tokenId) {
        require(
            tradeCoinCommodity[tokenId].currentHandler == msg.sender,
            "Caller is not the current handler"
        );
        _;
    }

    constructor(address _tradeCoinTokenizer)
        ERC721("TradeCoinV4", "TCT4")
        RoleControl(msg.sender)
    {
        tradeCoinTokenizer = TradeCoinTokenizerV2(_tradeCoinTokenizer);
    }

    function initializeSale(
        address owner,
        address handler,
        uint256 tokenIdOfTokenizer,
        uint256 priceInWei
    ) external override onlyTokenizer {
        require(
            tradeCoinTokenizer.ownerOf(tokenIdOfTokenizer) == msg.sender,
            "Not the owner"
        );
        tradeCoinTokenizer.transferFrom(
            msg.sender,
            address(this),
            tokenIdOfTokenizer
        );

        commoditySaleQueue[tokenIdOfTokenizer] = CommoditySale(
            msg.sender,
            owner,
            handler,
            priceInWei == 0,
            priceInWei
        );

        emit InitializeSale(
            tokenIdOfTokenizer,
            msg.sender,
            owner,
            priceInWei,
            priceInWei == 0
        );
    }

    function paymentOfToken(uint256 tokenIdOfTokenizer)
        external
        payable
        override
    {
        require(
            commoditySaleQueue[tokenIdOfTokenizer].priceInWei == msg.value,
            "Not enough Ether"
        );
        require(
            !commoditySaleQueue[tokenIdOfTokenizer].isPaid,
            "Token is already paid for"
        );
        commoditySaleQueue[tokenIdOfTokenizer].isPaid = true;

        emit PaymentOfToken(tokenIdOfTokenizer, msg.sender, msg.value);
    }

    function mintCommodity(uint256 tokenIdOfTokenizer)
        external
        override
        onlyTransformationHandler
        nonReentrant
    {
        CommoditySale memory _sale = commoditySaleQueue[tokenIdOfTokenizer];
        require(_sale.isPaid, "Not payed for yet");
        require(_sale.handler == msg.sender, "Not a handler");

        if (!(_sale.priceInWei == 0)) {
            payable(_sale.seller).transfer(_sale.priceInWei);
        }
        _mint(_sale.owner, tokenCounter);

        (bytes4 hashOfProperties, uint256 amount) = emitTokenData(
            tokenIdOfTokenizer
        );

        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            amount,
            State.Created,
            hashOfProperties,
            msg.sender
        );

        tradeCoinTokenizer.burnToken(tokenIdOfTokenizer);

        emit CompleteSale(tokenCounter, _sale.seller, msg.sender);

        // delete commoditySaleQueue[tokenIdOfTokenizer];
        unchecked {
            tokenCounter += 1;
        }
    }

    function emitTokenData(uint256 tokenIdOfTokenizer)
        internal
        returns (bytes4, uint256)
    {
        (
            string memory commodity,
            uint256 amount,
            string memory unit
        ) = tradeCoinTokenizer.tradeCoinToken(tokenIdOfTokenizer);

        emit MintCommodity(
            tokenCounter,
            msg.sender,
            tokenIdOfTokenizer,
            commodity,
            amount,
            unit
        );

        emit CommodityTransformation(tokenCounter, msg.sender, "raw");

        return (
            bytes4(keccak256(abi.encodePacked(commodity, unit, "raw"))),
            amount
        );
    }

    function addTransformation(uint256 _tokenId, string calldata transformation)
        external
        override
        onlyTransformationHandler
        isCurrentHandler(_tokenId)
    {
        tradeCoinCommodity[_tokenId].hashOfProperties =
            tradeCoinCommodity[_tokenId].hashOfProperties ^
            bytes4(keccak256(abi.encodePacked(transformation)));

        emit CommodityTransformation(_tokenId, msg.sender, transformation);
    }

    function addTransformationDecrease(
        uint256 _tokenId,
        string calldata transformation,
        uint256 amountDecrease
    ) external override onlyTransformationHandler isCurrentHandler(_tokenId) {
        tradeCoinCommodity[_tokenId].amount -= amountDecrease;

        tradeCoinCommodity[_tokenId].hashOfProperties =
            tradeCoinCommodity[_tokenId].hashOfProperties ^
            bytes4(keccak256(abi.encodePacked(transformation)));

        emit CommodityTransformationDecrease(
            _tokenId,
            msg.sender,
            transformation,
            amountDecrease
        );
    }

    function changeCurrentHandlerAndState(
        uint256 _tokenId,
        address newHandler,
        State newCommodityState
    ) external override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        tradeCoinCommodity[_tokenId].currentHandler = newHandler;
        tradeCoinCommodity[_tokenId].state = newCommodityState;

        emit ChangeStateAndHandler(
            _tokenId,
            msg.sender,
            newHandler,
            newCommodityState
        );
    }

    function addInformationToCommodity(uint256 _tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit AddInformation(_tokenId, msg.sender, data);
    }

    function checkQualityOfCommodity(uint256 _tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit QualityCheckCommodity(_tokenId, msg.sender, data);
    }

    function confirmCommodityLocation(
        uint256 _tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external override onlyInformationHandler isCurrentHandler(_tokenId) {
        emit LocationOfCommodity(
            _tokenId,
            msg.sender,
            latitude,
            longitude,
            radius
        );
    }

    function batchCommodities(uint256[] calldata _tokenIds) external override {
        require(ownerOf(_tokenIds[0]) == msg.sender, "Not the owner");
        require(_tokenIds.length > 1, "Length of array must be greater than 1");
        bytes32 hashOfCommodity = keccak256(
            abi.encodePacked(
                tradeCoinCommodity[_tokenIds[0]].state,
                tradeCoinCommodity[_tokenIds[0]].hashOfProperties
            )
        );

        uint256 cumulativeAmount = tradeCoinCommodity[_tokenIds[0]].amount;

        for (uint256 i = 1; i < _tokenIds.length; ) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not the owner");
            bytes32 hashOfiProduct = keccak256(
                abi.encodePacked(
                    tradeCoinCommodity[_tokenIds[i]].state,
                    tradeCoinCommodity[_tokenIds[i]].hashOfProperties
                )
            );
            require(
                hashOfiProduct == hashOfCommodity,
                "Properties don't match"
            );
            _burn(_tokenIds[i]);
            // delete tradeCoinCommodity[_tokenIds[i]];
            unchecked {
                cumulativeAmount += tradeCoinCommodity[_tokenIds[i]].amount;
                ++i;
            }
        }

        _mint(msg.sender, tokenCounter);
        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            cumulativeAmount,
            State.Created,
            tradeCoinCommodity[_tokenIds[0]].hashOfProperties,
            tradeCoinCommodity[_tokenIds[0]].currentHandler
        );

        _burn(_tokenIds[0]);
        // delete tradeCoinCommodity[_tokenIds[0]];

        emit BatchCommodities(tokenCounter, msg.sender, _tokenIds);

        tokenCounter += 1;
    }

    function splitCommodity(uint256 _tokenId, uint256[] calldata partitions)
        external
        override
    {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(partitions.length > 1, "Length of array must be bigger than 1");
        uint256 cumulativeAmountPartitions;
        for (uint256 i; i < partitions.length; ) {
            require(partitions[i] != 0, "Partition can't be 0");
            cumulativeAmountPartitions += partitions[i];
            unchecked {
                ++i;
            }
        }
        require(
            tradeCoinCommodity[_tokenId].amount == cumulativeAmountPartitions,
            "The amounts don't add up"
        );

        _burn(_tokenId);

        uint256[] memory newTokens = new uint256[](partitions.length);
        bytes4 _hashOfProperties = tradeCoinCommodity[_tokenId]
            .hashOfProperties;
        address _currentHandler = tradeCoinCommodity[_tokenId].currentHandler;
        uint256 _tokenCounter = tokenCounter;

        for (uint256 i; i < partitions.length; ) {
            _mint(msg.sender, _tokenCounter);
            tradeCoinCommodity[_tokenCounter] = TradeCoinCommodity(
                partitions[i],
                State.Created,
                _hashOfProperties,
                _currentHandler
            );
            newTokens[i] = _tokenCounter;
            unchecked {
                ++i;
                _tokenCounter += 1;
            }
        }
        tokenCounter = _tokenCounter;
        // delete tradeCoinCommodity[_tokenId];

        emit SplitCommodity(_tokenId, msg.sender, newTokens);
    }

    function burnCommodity(uint256 _tokenId) external override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");

        _burn(_tokenId);

        emit CommodityOutOfChain(_tokenId, msg.sender);
    }

    // Function must be overridden as ERC721 and AccesControl are conflicting
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            type(ITradeCoin).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
