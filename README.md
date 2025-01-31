# ReserveProof Clarity Smart Contract

This Clarity smart contract manages a reserve balance and allows for authorized withdrawals. It also supports the deposit and withdrawal of fungible tokens that implement the `token-trait` trait.

## Overview

The `ReserveProof` contract provides the following functionalities:

* **Initialization:** Sets the initial authorized withdrawer and the reserve threshold.
* **Authorized Withdrawer Management:** Allows the current authorized withdrawer to change the authorized withdrawer.
* **Reserve Management:** Enables depositing and withdrawing from the reserve balance.  Withdrawals are only permitted by the authorized withdrawer.
* **Token Management:** Supports depositing and withdrawing fungible tokens. Each token must implement the `token-trait` trait.
* **Balance Checks:** Provides read-only functions to check the current reserve balance and token balances.
* **Threshold Monitoring:** Checks if the reserve balance is below the defined threshold and emits an event if it is.

## Public Functions

### `initialize(withdrawer: principal, threshold: uint)`

Initializes the contract with the specified `withdrawer` and `threshold`. The `withdrawer` will be the only principal allowed to withdraw reserves. The `threshold` represents the minimum reserve balance that should be maintained.

**Parameters:**

* `withdrawer`: The principal authorized to withdraw reserves.
* `threshold`: The minimum reserve balance.

**Errors:**

* `ERR_INVALID_INPUT`: If the `withdrawer` is the same as the transaction sender, the `threshold` is zero, or the `threshold` is outside the allowed range (1000 to 1000000000).
* `ERR_WITHDRAWER_ALREADY_SET`: If the contract has already been initialized.

### `set-authorized-withdrawer(withdrawer: principal)`

Updates the authorized withdrawer. Only the current authorized withdrawer can call this function.

**Parameters:**

* `withdrawer`: The new principal to authorize for withdrawals.

**Errors:**

* `ERR_NOT_AUTHORIZED`: If the caller is not the current authorized withdrawer.
* `ERR_INVALID_INPUT`: If the new `withdrawer` is the same as the current one.

### `deposit-reserves(amount: uint)`

Deposits the specified `amount` into the reserve balance.

**Parameters:**

* `amount`: The amount to deposit.

**Errors:**

* `ERR_INVALID_INPUT`: If the `amount` is zero.
* `ERR_OVERFLOW`: If the deposit would cause the reserve balance to exceed the maximum uint value.

### `withdraw-reserves(amount: uint)`

Withdraws the specified `amount` from the reserve balance. Only the authorized withdrawer can call this function.

**Parameters:**

* `amount`: The amount to withdraw.

**Errors:**

* `ERR_NOT_AUTHORIZED`: If the caller is not the authorized withdrawer.
* `ERR_INVALID_INPUT`: If the `amount` is zero.
* `ERR_INSUFFICIENT_BALANCE`: If the reserve balance is less than the `amount` to withdraw.

### `deposit-token(token: <token-trait>, amount: uint)`

Deposits the specified `amount` of the given `token` into the caller's balance.

**Parameters:**

* `token`: The contract principal of the fungible token.
* `amount`: The amount of tokens to deposit.

**Errors:**

* `ERR_INVALID_INPUT`: If the `amount` is zero.
* `ERR_TOKEN_NOT_FOUND`: If the provided token does not implement the `token-trait` or the `get-name` function call fails.
* `ERR_OVERFLOW`: If the deposit causes a uint overflow.


### `withdraw-token(token: <token-trait>, amount: uint)`

Withdraws the specified `amount` of the given `token` from the caller's balance.

**Parameters:**

* `token`: The contract principal of the fungible token.
* `amount`: The amount of tokens to withdraw.

**Errors:**

* `ERR_INVALID_INPUT`: If the `amount` is zero.
* `ERR_TOKEN_NOT_FOUND`: If the provided token does not implement the `token-trait` or the `get-name` function call fails.
* `ERR_INSUFFICIENT_TOKEN_BALANCE`: If the caller's token balance is less than the `amount` to withdraw.

### `get-token-balance(token: <token-trait>, owner: principal)`

Returns the balance of the specified `token` for the given `owner`.

**Parameters:**

* `token`: The contract principal of the fungible token.
* `owner`: The principal whose balance is being queried.

**Returns:**

* The token balance of the `owner`.

### `get-reserve-balance()`

Returns the current reserve balance.

**Returns:**

* The current reserve balance.

### `check-threshold()`

Checks if the reserve balance is below the threshold.

**Returns:**

* An object with the status ("below-threshold" or "above-threshold") and the current balance. Emits a "threshold-breached" event if the balance is below the threshold.

## Events

* **initialize:** Emitted when the contract is initialized.
* **set-authorized-withdrawer:** Emitted when the authorized withdrawer is updated.
* **deposit:** Emitted when reserves are deposited.
* **withdraw:** Emitted when reserves are withdrawn.
* **token-deposit:** Emitted when tokens are deposited.
* **token-withdraw:** Emitted when tokens are withdrawn.
* **threshold-breached:** Emitted when the reserve balance falls below the threshold.

## Error Codes

* `ERR_NOT_AUTHORIZED`: u100
* `ERR_INSUFFICIENT_BALANCE`: u101
* `ERR_WITHDRAWER_ALREADY_SET`: u102
* `ERR_INVALID_INPUT`: u103
* `ERR_THRESHOLD_TOO_LOW`: u104
* `ERR_THRESHOLD_TOO_HIGH`: u105
* `ERR_OVERFLOW`: u106
* `ERR_INVALID_WITHDRAWER`: u107
* `ERR_TOKEN_NOT_FOUND`: u108
* `ERR_INSUFFICIENT_TOKEN_BALANCE`: u109
