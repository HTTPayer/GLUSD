// SPDX-License-Identifier: MIT
pragma solidity =0.8.30 >=0.4.16 >=0.6.2 >=0.8.4 ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}

// lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.5.0) (interfaces/draft-IERC6093.sol)

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-721.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.5.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * IMPORTANT: Deprecated. This storage-based reentrancy guard will be removed and replaced
 * by the {ReentrancyGuardTransient} variant in v6.0.
 *
 * @custom:stateless
 */
abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev A `view` only version of {nonReentrant}. Use to block view functions
     * from being called, preventing reading from inconsistent contract state.
     *
     * CAUTION: This is a "view" modifier and does not change the reentrancy
     * status. Use it only on view functions. For payable or non-payable functions,
     * use the standard {nonReentrant} modifier instead.
     */
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        _nonReentrantBeforeView();

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v5.5.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation sets the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the `transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// src/GLUSD.sol

/// @title GLUSD - Galaksio USD
/// @notice Reward-accruing stablecoin backed by USDC
/// @dev Non-rebasing ERC20 where value accrues through exchange rate appreciation
/// - Backed by USDC held in this contract
/// - Mint: deposit USDC -> mint GLUSD at current exchange rate
/// - Redeem: burn GLUSD -> receive USDC at current exchange rate
/// - Treasury deposits fees which increase the exchange rate for all holders
/// - Alpha version: capped at MAX_TOTAL_SUPPLY for risk management
contract GLUSD is ERC20, Pausable, ReentrancyGuard {
    address public admin;
    address public treasury;
    address public pauser;

    /// @notice Maximum total supply for alpha launch (1k GLUSD with 6 decimals)
    /// @dev This limit protects against excessive exposure during the alpha phase
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000e6; // 1,000 GLUSD

    /// @notice Seconds in a year for APR/APY calculations
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    IERC20 public immutable USDC;
    uint8 private immutable _decimals;

    /// @notice Snapshot of exchange rate at a specific time
    struct RateSnapshot {
        uint256 rate;       // Exchange rate (USDC per GLUSD, scaled by 1e6)
        uint256 timestamp;  // Block timestamp of snapshot
    }

    /// @notice Circular buffer of recent rate snapshots (max 90 days at 1 snapshot/hour)
    /// @dev We keep ~2160 snapshots (90 days * 24 hours) for onchain APR/APY calculations
    /// Full history can be reconstructed from RateSnapshotTaken events
    RateSnapshot[2160] public recentSnapshots;

    /// @notice Current index in the circular buffer
    uint256 public snapshotIndex;

    /// @notice Total number of snapshots taken (never decreases)
    uint256 public totalSnapshotCount;

    /// @notice Timestamp of last snapshot taken
    uint256 public lastSnapshotTime;

    /// @notice Minimum time between snapshots (30 seconds)
    uint256 public constant MIN_SNAPSHOT_INTERVAL = 30 seconds;

    /// @notice Maximum snapshots stored in circular buffer
    uint256 public constant MAX_SNAPSHOTS = 2160;

    event Mint(address indexed user, uint256 usdcDeposited, uint256 glusdMinted);
    event Redeem(address indexed user, uint256 glusdBurned, uint256 usdcReturned);
    event FeesDeposited(address indexed depositor, uint256 amount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event PauserUpdated(address indexed oldPauser, address indexed newPauser);
    event RateSnapshotTaken(uint256 rate, uint256 timestamp);

    /// @notice Constructs the GLUSD contract
    /// @param _usdc Address of the USDC token contract
    /// @param _treasury Address to be set as treasury
    constructor(IERC20 _usdc, address _treasury) ERC20("Galaksio USD", "GLUSD") {
        require(address(_usdc) != address(0), "GLUSD: zero USDC address");
        require(_treasury != address(0), "GLUSD: zero treasury address");

        USDC = _usdc;
        _decimals = 6; // Match USDC decimals

        // Set addresses
        admin = msg.sender;
        treasury = _treasury;
        pauser = msg.sender;

        // Take initial snapshot at 1:1 rate in circular buffer
        recentSnapshots[0] = RateSnapshot({
            rate: 1e6,
            timestamp: block.timestamp
        });
        snapshotIndex = 0;
        totalSnapshotCount = 1;
        lastSnapshotTime = block.timestamp;

        emit TreasuryUpdated(address(0), _treasury);
        emit RateSnapshotTaken(1e6, block.timestamp);
    }

    /// @notice Returns the number of decimals (6 to match USDC)
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice Calculates the current exchange rate (USDC per GLUSD)
    /// @dev Returns the amount of USDC per 1 GLUSD token (scaled by 1e6)
    /// @return rate Exchange rate scaled by 1e6 (6 decimals)
    function exchangeRate() public view returns (uint256 rate) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 1e6; // 1:1 when no supply exists
        }
        uint256 usdcBalance = USDC.balanceOf(address(this));
        // rate = (usdcBalance * 1e6) / supply
        // This gives us USDC per GLUSD in 6 decimal precision
        rate = (usdcBalance * 1e6) / supply;
    }

    /// @notice Mint GLUSD by depositing USDC at the current exchange rate
    /// @dev User must approve USDC to this contract before calling
    /// @param usdcAmount Amount of USDC to deposit
    /// @return glusdMinted Amount of GLUSD minted
    function mint(uint256 usdcAmount)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 glusdMinted)
    {
        require(usdcAmount > 0, "GLUSD: zero amount");

        // Transfer USDC from user
        bool success = USDC.transferFrom(msg.sender, address(this), usdcAmount);
        require(success, "GLUSD: USDC transfer failed");

        // Calculate GLUSD to mint based on current exchange rate
        // If totalSupply is 0, mint 1:1
        // Otherwise: glusdMinted = (usdcAmount * 1e6) / exchangeRate()
        uint256 supply = totalSupply();
        if (supply == 0) {
            glusdMinted = usdcAmount;
        } else {
            uint256 rate = exchangeRate();
            require(rate > 0, "GLUSD: invalid exchange rate");
            // glusdMinted = (usdcAmount * 1e6) / rate
            glusdMinted = (usdcAmount * 1e6) / rate;
        }

        require(glusdMinted > 0, "GLUSD: mint amount too small");

        // Alpha launch cap: prevent minting beyond max supply
        uint256 newTotalSupply = supply + glusdMinted;
        require(newTotalSupply <= MAX_TOTAL_SUPPLY, "GLUSD: exceeds max supply cap");

        _mint(msg.sender, glusdMinted);
        emit Mint(msg.sender, usdcAmount, glusdMinted);
    }

    /// @notice Redeem GLUSD for USDC at the current exchange rate
    /// @param glusdAmount Amount of GLUSD to burn
    /// @return usdcOut Amount of USDC returned
    function redeem(uint256 glusdAmount)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 usdcOut)
    {
        require(glusdAmount > 0, "GLUSD: zero amount");
        require(totalSupply() > 0, "GLUSD: no supply");
        require(balanceOf(msg.sender) >= glusdAmount, "GLUSD: insufficient balance");

        // Calculate USDC to return based on current exchange rate
        // usdcOut = (glusdAmount * exchangeRate()) / 1e6
        uint256 rate = exchangeRate();
        usdcOut = (glusdAmount * rate) / 1e6;
        require(usdcOut > 0, "GLUSD: redeem amount too small");

        uint256 usdcBalance = USDC.balanceOf(address(this));
        require(usdcOut <= usdcBalance, "GLUSD: insufficient USDC reserves");

        // Burn GLUSD first (checks-effects-interactions pattern)
        _burn(msg.sender, glusdAmount);

        // Transfer USDC to user
        bool success = USDC.transfer(msg.sender, usdcOut);
        require(success, "GLUSD: USDC transfer failed");

        emit Redeem(msg.sender, glusdAmount, usdcOut);
    }

    /// @notice Deposit fees into the vault (increases exchange rate for all holders)
    /// @dev Only callable by treasury. Automatically takes rate snapshot if interval has passed.
    /// @param amount Amount of USDC to deposit as fees
    function depositFees(uint256 amount)
        external
        nonReentrant
        returns (bool)
    {
        require(msg.sender == treasury, "GLUSD: only treasury");
        require(amount > 0, "GLUSD: zero amount");

        bool success = USDC.transferFrom(msg.sender, address(this), amount);
        require(success, "GLUSD: USDC transfer failed");

        emit FeesDeposited(msg.sender, amount);

        // Take a rate snapshot after fee deposit if enough time has passed
        _takeSnapshotIfNeeded();

        return true;
    }

    /// @notice Manually take a rate snapshot (callable by anyone if interval has passed)
    /// @dev Useful for updating yield calculations without depositing fees
    function takeSnapshot() external {
        _takeSnapshotIfNeeded();
    }

    /// @notice Internal function to take a rate snapshot if minimum interval has passed
    function _takeSnapshotIfNeeded() internal {
        // Only take snapshot if enough time has passed and supply exists
        if (block.timestamp >= lastSnapshotTime + MIN_SNAPSHOT_INTERVAL && totalSupply() > 0) {
            uint256 currentRate = exchangeRate();

            // Increment index in circular buffer (wraps around at MAX_SNAPSHOTS)
            snapshotIndex = (snapshotIndex + 1) % MAX_SNAPSHOTS;

            // Store snapshot in circular buffer
            recentSnapshots[snapshotIndex] = RateSnapshot({
                rate: currentRate,
                timestamp: block.timestamp
            });

            totalSnapshotCount++;
            lastSnapshotTime = block.timestamp;
            emit RateSnapshotTaken(currentRate, block.timestamp);
        }
    }

    /// @notice Returns current USDC balance and GLUSD supply
    /// @return usdcBalance Current USDC held by contract
    /// @return supply Current GLUSD total supply
    function vaultStatus() external view returns (uint256 usdcBalance, uint256 supply) {
        usdcBalance = USDC.balanceOf(address(this));
        supply = totalSupply();
    }

    /// @notice Returns remaining mintable supply for alpha cap
    /// @return remaining Amount of GLUSD that can still be minted
    function remainingMintableSupply() external view returns (uint256 remaining) {
        uint256 supply = totalSupply();
        if (supply >= MAX_TOTAL_SUPPLY) {
            return 0;
        }
        return MAX_TOTAL_SUPPLY - supply;
    }

    /// @notice Get the number of rate snapshots currently stored in buffer
    /// @return count Number of snapshots available (max 2160, or totalSnapshotCount if less)
    function getSnapshotCount() external view returns (uint256 count) {
        return totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;
    }

    /// @notice Get the most recent snapshot
    /// @return rate Exchange rate at the most recent snapshot
    /// @return timestamp Time of the most recent snapshot
    function getMostRecentSnapshot() external view returns (uint256 rate, uint256 timestamp) {
        RateSnapshot memory snapshot = recentSnapshots[snapshotIndex];
        return (snapshot.rate, snapshot.timestamp);
    }

    /// @notice Get a snapshot from N snapshots ago (0 = most recent)
    /// @param snapshotsAgo How many snapshots back to retrieve (0 to 2159)
    /// @return rate Exchange rate at that snapshot
    /// @return timestamp Time of the snapshot
    function getSnapshotFromPast(uint256 snapshotsAgo) external view returns (uint256 rate, uint256 timestamp) {
        uint256 available = totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;
        require(snapshotsAgo < available, "GLUSD: snapshot too old");

        // Calculate the circular buffer index
        uint256 targetIndex;
        if (snapshotsAgo <= snapshotIndex) {
            targetIndex = snapshotIndex - snapshotsAgo;
        } else {
            targetIndex = MAX_SNAPSHOTS - (snapshotsAgo - snapshotIndex);
        }

        RateSnapshot memory snapshot = recentSnapshots[targetIndex];
        return (snapshot.rate, snapshot.timestamp);
    }

    /// @notice Calculate APR based on rate change over a time period
    /// @param daysAgo Number of days ago to compare against (e.g., 7 for 7-day APR, max 90)
    /// @return apr Annual Percentage Rate scaled by 1e6 (e.g., 5% = 5e6)
    function calculateAPR(uint256 daysAgo) external view returns (uint256 apr) {
        require(daysAgo > 0, "GLUSD: invalid days");
        require(daysAgo <= 90, "GLUSD: max 90 days");
        require(totalSnapshotCount > 0, "GLUSD: no history");

        uint256 currentRate = exchangeRate();
        uint256 targetTimestamp = block.timestamp - (daysAgo * 1 days);

        // Find the snapshot closest to targetTimestamp in circular buffer
        uint256 oldRate;
        uint256 oldTimestamp;
        bool foundSnapshot = false;

        uint256 availableSnapshots = totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;

        // Search backwards through circular buffer
        for (uint256 i = 0; i < availableSnapshots; i++) {
            uint256 bufferIndex;
            if (i <= snapshotIndex) {
                bufferIndex = snapshotIndex - i;
            } else {
                bufferIndex = MAX_SNAPSHOTS - (i - snapshotIndex);
            }

            RateSnapshot memory snapshot = recentSnapshots[bufferIndex];
            if (snapshot.timestamp <= targetTimestamp) {
                oldRate = snapshot.rate;
                oldTimestamp = snapshot.timestamp;
                foundSnapshot = true;
                break;
            }
        }

        // If no snapshot old enough, use the oldest available
        if (!foundSnapshot) {
            uint256 oldestIndex;
            if (totalSnapshotCount > MAX_SNAPSHOTS) {
                // Buffer is full, oldest is next after current
                oldestIndex = (snapshotIndex + 1) % MAX_SNAPSHOTS;
            } else {
                // Buffer not full, oldest is at index 0
                oldestIndex = 0;
            }
            RateSnapshot memory oldestSnapshot = recentSnapshots[oldestIndex];
            oldRate = oldestSnapshot.rate;
            oldTimestamp = oldestSnapshot.timestamp;
        }

        uint256 timeElapsed = block.timestamp - oldTimestamp;
        if (timeElapsed == 0 || oldRate == 0) {
            return 0;
        }

        // Calculate rate change: (currentRate - oldRate) / oldRate
        // APR = (rateChange / timeElapsed) * SECONDS_PER_YEAR * 100
        // Scaled by 1e6 for percentage with 6 decimals
        if (currentRate <= oldRate) {
            return 0; // No yield or negative yield
        }

        uint256 rateIncrease = currentRate - oldRate;
        // apr = (rateIncrease * SECONDS_PER_YEAR * 1e8) / (oldRate * timeElapsed)
        // The 1e8 comes from: 1e6 (percentage scale) * 100 (for %) = 1e8
        apr = (rateIncrease * SECONDS_PER_YEAR * 1e8) / (oldRate * timeElapsed);
    }

    /// @notice Calculate APY (compound annual yield) based on rate change
    /// @param daysAgo Number of days ago to compare against (max 90)
    /// @return apy Annual Percentage Yield scaled by 1e6 (e.g., 5% = 5e6)
    /// @dev APY = ((1 + periodicRate)^periods - 1) * 100, approximated for small rates
    function calculateAPY(uint256 daysAgo) external view returns (uint256 apy) {
        require(daysAgo > 0, "GLUSD: invalid days");
        require(daysAgo <= 90, "GLUSD: max 90 days");
        require(totalSnapshotCount > 0, "GLUSD: no history");

        uint256 currentRate = exchangeRate();
        uint256 targetTimestamp = block.timestamp - (daysAgo * 1 days);

        // Find the snapshot closest to targetTimestamp
        uint256 oldRate;
        uint256 oldTimestamp;
        bool foundSnapshot = false;

        uint256 availableSnapshots = totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;

        for (uint256 i = 0; i < availableSnapshots; i++) {
            uint256 bufferIndex;
            if (i <= snapshotIndex) {
                bufferIndex = snapshotIndex - i;
            } else {
                bufferIndex = MAX_SNAPSHOTS - (i - snapshotIndex);
            }

            RateSnapshot memory snapshot = recentSnapshots[bufferIndex];
            if (snapshot.timestamp <= targetTimestamp) {
                oldRate = snapshot.rate;
                oldTimestamp = snapshot.timestamp;
                foundSnapshot = true;
                break;
            }
        }

        if (!foundSnapshot) {
            uint256 oldestIndex;
            if (totalSnapshotCount > MAX_SNAPSHOTS) {
                oldestIndex = (snapshotIndex + 1) % MAX_SNAPSHOTS;
            } else {
                oldestIndex = 0;
            }
            RateSnapshot memory oldestSnapshot = recentSnapshots[oldestIndex];
            oldRate = oldestSnapshot.rate;
            oldTimestamp = oldestSnapshot.timestamp;
        }

        uint256 timeElapsed = block.timestamp - oldTimestamp;
        if (timeElapsed == 0 || oldRate == 0 || currentRate <= oldRate) {
            return 0;
        }

        // For small yields, APY ≈ APR * (1 + APR/2) ≈ APR for simplicity
        // More accurate: calculate (currentRate/oldRate)^(SECONDS_PER_YEAR/timeElapsed) - 1
        // Simplified: just use the ratio and annualize
        uint256 rateRatio = (currentRate * 1e18) / oldRate; // Scale up for precision
        uint256 periodsPerYear = SECONDS_PER_YEAR / timeElapsed;

        // For small returns: APY ≈ ((rateRatio - 1e18) * periodsPerYear * 100) / 1e18
        // Scaled to 1e6 for percentage
        if (rateRatio <= 1e18) {
            return 0;
        }

        uint256 growth = rateRatio - 1e18;
        apy = (growth * periodsPerYear * 1e8) / 1e18; // 1e8 = 1e6 * 100 for percentage
    }

    /// @notice Get current 7-day and 30-day APR for easy access
    /// @return apr7d 7-day APR scaled by 1e6
    /// @return apr30d 30-day APR scaled by 1e6
    function getCurrentAPRs() external view returns (uint256 apr7d, uint256 apr30d) {
        if (totalSnapshotCount == 0) {
            return (0, 0);
        }

        // Try to calculate 7-day APR
        try this.calculateAPR(7) returns (uint256 apr7) {
            apr7d = apr7;
        } catch {
            apr7d = 0;
        }

        // Try to calculate 30-day APR
        try this.calculateAPR(30) returns (uint256 apr30) {
            apr30d = apr30;
        } catch {
            apr30d = 0;
        }
    }

    /// @notice Pause contract (stops minting and redemption)
    /// @dev Only callable by pauser
    function pause() external {
        require(msg.sender == pauser, "GLUSD: only pauser");
        _pause();
    }

    /// @notice Unpause contract
    /// @dev Only callable by pauser
    function unpause() external {
        require(msg.sender == pauser, "GLUSD: only pauser");
        _unpause();
    }

    /// @notice Update treasury address
    /// @dev Only callable by admin
    /// @param newTreasury New treasury address
    function setTreasury(address newTreasury) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(newTreasury != address(0), "GLUSD: zero treasury address");

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /// @notice Update admin address
    /// @dev Only callable by current admin
    /// @param newAdmin New admin address
    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(newAdmin != address(0), "GLUSD: zero admin address");

        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminUpdated(oldAdmin, newAdmin);
    }

    /// @notice Update pauser address
    /// @dev Only callable by admin
    /// @param newPauser New pauser address
    function setPauser(address newPauser) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(newPauser != address(0), "GLUSD: zero pauser address");

        address oldPauser = pauser;
        pauser = newPauser;

        emit PauserUpdated(oldPauser, newPauser);
    }

    /// @notice Emergency token rescue (cannot rescue USDC backing)
    /// @dev Only callable by admin
    /// @param token Token to rescue
    /// @param to Address to send tokens to
    /// @param amount Amount to rescue
    function rescueERC20(IERC20 token, address to, uint256 amount) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(address(token) != address(USDC), "GLUSD: cannot rescue USDC");
        require(to != address(0), "GLUSD: zero address");

        bool success = token.transfer(to, amount);
        require(success, "GLUSD: rescue transfer failed");
    }
}
