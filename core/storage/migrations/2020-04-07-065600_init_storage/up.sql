CREATE TABLE operations (
    id bigserial PRIMARY KEY,
    block_number BIGINT NOT NULL,
    action_type TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    confirmed bool NOT NULL DEFAULT false
);

CREATE TABLE accounts (
    id BIGINT NOT NULL PRIMARY KEY,
    last_block BIGINT NOT NULL,
    nonce BIGINT NOT NULL,
    address bytea NOT NULL,
    pubkey_hash bytea NOT NULL
);

CREATE TABLE proofs (
    block_number bigserial PRIMARY KEY,
    proof jsonb NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE prover_runs (
    id serial PRIMARY KEY,
    block_number BIGINT NOT NULL,
    worker TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE server_config (
    -- enforce single record
    id bool PRIMARY KEY NOT NULL DEFAULT true,
    CONSTRAINT single_server_config CHECK (id),
    contract_addr TEXT,
    gov_contract_addr TEXT
);

CREATE TABLE active_provers (
    id serial PRIMARY KEY,
    worker TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    stopped_at TIMESTAMP,
    block_size BIGINT NOT NULL
);

CREATE TABLE tokens (
    id INTEGER NOT NULL PRIMARY KEY,
    address TEXT NOT NULL,
    symbol TEXT NOT NULL
);

CREATE TABLE balances (
    account_id BIGINT REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE CASCADE,
    coin_id INTEGER REFERENCES tokens(id) ON UPDATE CASCADE,
    balance NUMERIC NOT NULL DEFAULT 0,
    PRIMARY KEY (account_id, coin_id)
);

CREATE TABLE account_balance_updates (
    balance_update_id serial NOT NULL,
    account_id BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    coin_id INTEGER NOT NULL REFERENCES tokens(id) ON UPDATE CASCADE,
    old_balance NUMERIC NOT NULL,
    new_balance NUMERIC NOT NULL,
    old_nonce BIGINT NOT NULL,
    new_nonce BIGINT NOT NULL,
    update_order_id INTEGER NOT NULL,
    PRIMARY KEY (balance_update_id)
);

CREATE TABLE account_creates (
    account_id BIGINT NOT NULL,
    is_create bool NOT NULL,
    block_number BIGINT NOT NULL,
    address bytea NOT NULL,
    nonce BIGINT NOT NULL,
    update_order_id INTEGER NOT NULL,
    PRIMARY KEY (account_id, block_number)
);

CREATE TABLE mempool (
    HASH bytea PRIMARY KEY,
    primary_account_address bytea NOT NULL,
    nonce BIGINT NOT NULL,
    tx jsonb NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE executed_transactions (
    id serial PRIMARY KEY,
    block_number BIGINT NOT NULL,
    tx_hash bytea NOT NULL REFERENCES mempool(HASH),
    operation jsonb,
    success bool NOT NULL,
    fail_reason TEXT,
    block_index INT
);

CREATE TABLE data_restore_last_watched_eth_block (
    id SERIAL PRIMARY KEY,
    block_number TEXT NOT NULL
);

CREATE TABLE events_state (
    id SERIAL PRIMARY KEY,
    block_type TEXT NOT NULL,
    transaction_hash BYTEA NOT NULL,
    block_num BIGINT NOT NULL
);

CREATE TABLE rollup_ops (
    id SERIAL PRIMARY KEY,
    block_num BIGINT NOT NULL,
    operation JSONB NOT NULL,
    fee_account BIGINT NOT NULL
);

CREATE TABLE storage_state_update (
    id SERIAL PRIMARY KEY,
    storage_state TEXT NOT NULL
);

CREATE TABLE eth_operations (
    id bigserial PRIMARY KEY,
    nonce BIGINT NOT NULL,
    last_deadline_block BIGINT NOT NULL,
    last_used_gas_price NUMERIC NOT NULL,
    confirmed bool NOT NULL DEFAULT false,
    raw_tx bytea NOT NULL,
    op_type TEXT NOT NULL,
    final_hash bytea DEFAULT NULL
);

CREATE TABLE executed_priority_operations (
    id serial PRIMARY KEY,
    -- sidechain block info
    block_number BIGINT NOT NULL,
    block_index INT NOT NULL,
    -- operation data
    operation jsonb NOT NULL,
    -- operation metadata
    priority_op_serialid BIGINT NOT NULL,
    deadline_block BIGINT NOT NULL,
    eth_fee NUMERIC NOT NULL,
    eth_hash bytea NOT NULL
);

CREATE TABLE blocks (
    number BIGINT PRIMARY KEY,
    root_hash TEXT NOT NULL,
    fee_account_id BIGINT NOT NULL,
    unprocessed_prior_op_before BIGINT NOT NULL,
    unprocessed_prior_op_after BIGINT NOT NULL,
    block_size BIGINT NOT NULL
);

CREATE TABLE account_pubkey_updates (
    pubkey_update_id serial NOT NULL,
    update_order_id INTEGER NOT NULL,
    account_id BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    old_pubkey_hash bytea NOT NULL,
    new_pubkey_hash bytea NOT NULL,
    old_nonce BIGINT NOT NULL,
    new_nonce BIGINT NOT NULL,
    PRIMARY KEY (pubkey_update_id)
);

-- Your SQL goes here
-- Locally stored Ethereum nonce
CREATE TABLE eth_nonce (
    -- enforce single record
    id bool PRIMARY KEY NOT NULL DEFAULT true,
    nonce BIGINT NOT NULL
);

-- Gathered operations statistics
CREATE TABLE eth_stats (
    -- enforce single record
    id bool PRIMARY KEY NOT NULL DEFAULT true,
    commit_ops BIGINT NOT NULL,
    verify_ops BIGINT NOT NULL,
    withdraw_ops BIGINT NOT NULL
);

-- Table connection `eth_operations` and `operations` table.
-- Each entry provides a mapping between the Ethereum transaction and the ZK Sync operation.
CREATE TABLE eth_ops_binding (
    id bigserial PRIMARY KEY,
    op_id bigserial NOT NULL REFERENCES operations(id),
    eth_op_id bigserial NOT NULL REFERENCES eth_operations(id)
);

-- Table storing all the sent Ethereum transaction hashes.
CREATE TABLE eth_tx_hashes (
    id bigserial PRIMARY KEY,
    eth_op_id bigserial NOT NULL REFERENCES eth_operations(id),
    tx_hash bytea NOT NULL
);

CREATE INDEX operations_block_index ON operations (block_number);
CREATE INDEX accounts_block_index ON accounts (last_block);

-- tablefunc enables crosstab (pivot)
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Add ETH token
INSERT INTO tokens
VALUES (
    0,
    '0x0000000000000000000000000000000000000000',
    'ETH'
);
