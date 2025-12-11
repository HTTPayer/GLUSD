import os, json, sys, time
from dotenv import load_dotenv
from web3 import Web3
from eth_account import Account
from web3.middleware import ExtraDataToPOAMiddleware, LocalFilterMiddleware

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

print(f"BASE_DIR: {BASE_DIR}")

load_dotenv()

CLEAR_RECIPIENTS = os.getenv("CLEAR_RECIPIENTS", "false").lower() == "true"
print(f"CLEAR_RECIPIENTS: {CLEAR_RECIPIENTS}")
RPC_URL = os.getenv("RPC_URL")
EXPLORER_URL = os.getenv("EXPLORER_URL", "https://testnet.snowtrace.io/tx/")
ADMIN_PRIVATE_KEY = os.getenv("ADMIN_PRIVATE_KEY")
USDC_ADDRESS_RAW = os.getenv("USDC_ADDRESS", "0x5425890298aed601595a70ab815c96711a31bc65")
USDC_ADDRESS = Web3.to_checksum_address(USDC_ADDRESS_RAW)
MULTISIG = "0xA6C59BbE1b52C3aC5c17779910aB7b63eBD85Ed8"
BROKER_ADDRESS = "0x066e4FBb1Cb2fd7dE4fb1432a7B1C1169B4c2C8F"

w3 = Web3(Web3.HTTPProvider(RPC_URL))
w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
w3.middleware_onion.add(LocalFilterMiddleware)

admin_account = Account.from_key(ADMIN_PRIVATE_KEY)
w3.eth.default_account = admin_account.address

# breakpoint()

# Load ABI and config
GLUSD_ABI_PATH = os.path.join(BASE_DIR, "..", "contracts", "out", "GLUSD.sol", "GLUSD.json")
with open(GLUSD_ABI_PATH, 'r') as f:
    GLUSD_ABI = json.load(f)["abi"]

GLUSD_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "GLUSD.json")
with open(GLUSD_ADDRESS_PATH, 'r') as f:
    GLUSD_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

SPLITTER_ABI_PATH = os.path.join(BASE_DIR, "..", "contracts", "out", "RevenueSplitter.sol", "RevenueSplitter.json")
with open(SPLITTER_ABI_PATH, 'r') as f:
    SPLITTER_ABI = json.load(f)["abi"]

# BROKER_SPLITTER_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "BrokerRevenueSplitter.json")
# with open(BROKER_SPLITTER_ADDRESS_PATH, 'r') as f:
#     BROKER_SPLITTER_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

COMPUTE_SPLITTER_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "ComputeRevenueSplitter.json")
with open(COMPUTE_SPLITTER_ADDRESS_PATH, 'r') as f:
    COMPUTE_SPLITTER_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

STORAGE_SPLITTER_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "StorageRevenueSplitter.json")
with open(STORAGE_SPLITTER_ADDRESS_PATH, 'r') as f:
    STORAGE_SPLITTER_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

ERC20_ABI_PATH = os.path.join(BASE_DIR, "..", "contracts", "out", "ERC20.sol", "ERC20.json")
with open(ERC20_ABI_PATH, 'r') as f:
    ERC20_ABI = json.load(f)["abi"]

print(f'GLUSD_ADDRESS: {GLUSD_ADDRESS}')
print(f'RPC_URL: {RPC_URL}')

glusd_contract = w3.eth.contract(
    address=w3.to_checksum_address(GLUSD_ADDRESS),
    abi=GLUSD_ABI
)

# BROKER_RECIPIENTS = [BROKER_ADDRESS, glusd_contract.address] # Since the broker also pays for jobs, we need to include it in the recipients
COMPUTE_RECIPIENTS = [MULTISIG, glusd_contract.address] # Compute server just receives fees, doesnt pay
STORAGE_RECIPIENTS = [MULTISIG, glusd_contract.address] # Storage server just receives fees, doesnt pay

# BROKER_BASIS_POINTS = [8000, 2000]  # 80%, 20%
COMPUTE_BASIS_POINTS = [7500, 2500]  # 75%, 25%
STORAGE_BASIS_POINTS = [7500, 2500]  # 75%, 25%

glusd_decimals = glusd_contract.functions.decimals().call()
print(f"GLUSD Decimals: {glusd_decimals}")

# broker_splitter_contract = w3.eth.contract(
#     address=w3.to_checksum_address(BROKER_SPLITTER_ADDRESS),
#     abi=SPLITTER_ABI
# )

compute_splitter_contract = w3.eth.contract(
    address=w3.to_checksum_address(COMPUTE_SPLITTER_ADDRESS),
    abi=SPLITTER_ABI
)

storage_splitter_contract = w3.eth.contract(
    address=w3.to_checksum_address(STORAGE_SPLITTER_ADDRESS),
    abi=SPLITTER_ABI
)

usdc_contract = w3.eth.contract(
    address=USDC_ADDRESS,
    abi=ERC20_ABI
)

usdc_decimals = usdc_contract.functions.decimals().call()
print(f"USDC Decimals: {usdc_decimals}")

splitter_contracts = [
    compute_splitter_contract,
    storage_splitter_contract
]

print(f"GLUSD Contract Address: {glusd_contract.address}")

for contract in splitter_contracts:
    print(f"Revenue Splitter Contract Address: {contract.address}")

print(f"USDC Contract Address: {usdc_contract.address}")

admin_usdc_balance = usdc_contract.functions.balanceOf(admin_account.address).call()
print(f"Admin USDC Balance: {admin_usdc_balance / 10 ** usdc_decimals}")

# Check GLUSD total supply
glusd_total_supply = glusd_contract.functions.totalSupply().call()
print(f"GLUSD Total Supply: {glusd_total_supply / 10 ** glusd_decimals}")  # Assuming GLUSD has 18 decimals

# Check Revenue Splitter USDC balance
for contract in splitter_contracts:
    splitter_usdc_balance = usdc_contract.functions.balanceOf(contract.address).call() 
    print(f"Revenue Splitter ({contract.address}) USDC Balance: {splitter_usdc_balance / 10 ** usdc_decimals}")  # Assuming USDC has 6 decimals

# Update glusd treasury address to revenue splitters
for contract in splitter_contracts:
    if not glusd_contract.functions.isTreasury(contract.address).call():
        print(f"Adding {contract.address} as GLUSD treasury...")
        nonce = w3.eth.get_transaction_count(admin_account.address)
        txn = glusd_contract.functions.addTreasury(contract.address).build_transaction({
            'from': admin_account.address,
            'nonce': nonce,
            'gas': 200000,
            'gasPrice': w3.to_wei('10', 'gwei')
        })
        signed_txn = w3.eth.account.sign_transaction(txn, private_key=ADMIN_PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        print(f"Transaction sent: {EXPLORER_URL}{"0x"+tx_hash.hex()}")
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print(f"Transaction receipt: {receipt}")

        time.sleep(5)  # Wait for a few seconds to ensure the state is updated

        if glusd_contract.functions.isTreasury(contract.address).call():
            print(f"{contract.address} successfully added as GLUSD treasury.")
        else:
            print(f"Failed to add {contract.address} as GLUSD treasury.")
            sys.exit(1)

if glusd_contract.functions.isTreasury(admin_account.address).call():
    print("Removing admin as GLUSD treasury...")
    nonce = w3.eth.get_transaction_count(admin_account.address)
    txn = glusd_contract.functions.removeTreasury(admin_account.address).build_transaction({
        'from': admin_account.address,
        'nonce': nonce,
        'gas': 200000,
        'gasPrice': w3.to_wei('10', 'gwei')
    })
    signed_txn = w3.eth.account.sign_transaction(txn, private_key=ADMIN_PRIVATE_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    print(f"Transaction sent: {EXPLORER_URL}{"0x"+tx_hash.hex()}")
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transaction receipt: {receipt}")

    time.sleep(5)  # Wait for a few seconds to ensure the state is updated

    if not glusd_contract.functions.isTreasury(admin_account.address).call():
        print("Admin successfully removed as GLUSD treasury.")
    else:
        print("Failed to remove admin as GLUSD treasury.")
        sys.exit(1)

# current_treasury = glusd_contract.functions.treasury().call()
# print(f"Current GLUSD Treasury Address: {current_treasury}")

# Excahnge Rate
exchange_rate = glusd_contract.functions.exchangeRate().call()
print(f"GLUSD/USDC Exchange Rate: {exchange_rate / 10 ** glusd_decimals}")

vault_usdc_balance, glusd_supply = glusd_contract.functions.vaultStatus().call()
print(f"GLUSD Vault USDC Balance: {vault_usdc_balance / 10 ** usdc_decimals}")
print(f"GLUSD Supply from Vault Status: {glusd_supply / 10 ** glusd_decimals}")

last_snapshot_time = glusd_contract.functions.lastSnapshotTime().call()
print(f"GLUSD Last Snapshot Time: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(last_snapshot_time))}")

min_snapshot_interval = glusd_contract.functions.MIN_SNAPSHOT_INTERVAL().call()
print(f"GLUSD Min Snapshot Interval: {min_snapshot_interval} seconds")

if time.time() - last_snapshot_time >= min_snapshot_interval:
    print("Taking GLUSD snapshot...")

    snapshot_tx = glusd_contract.functions.takeSnapshot().build_transaction({
        'from': admin_account.address,
        'nonce': w3.eth.get_transaction_count(admin_account.address),
    })

    try:
        gas_estimate = w3.eth.estimate_gas(snapshot_tx)
        print(f"Estimated gas for takeSnapshot: {gas_estimate}")
    except Exception as e:
        print(f"Gas estimation failed: {e}")
        snapshot_tx['gas'] = 200000  # Fallback gas limit

    latest_block = w3.eth.get_block("latest")
    base_fee = latest_block.get("baseFeePerGas", w3.to_wei(15, "gwei"))
    priority_fee = w3.to_wei(2, "gwei")
    max_fee = base_fee + priority_fee

    snapshot_tx.update({
        'gas': int(gas_estimate * 1.5),
        'maxFeePerGas': max_fee,
        'maxPriorityFeePerGas': priority_fee,
        'type': 2
    })

    signed_snapshot_tx = w3.eth.account.sign_transaction(snapshot_tx, private_key=ADMIN_PRIVATE_KEY)
    snapshot_tx_hash = w3.eth.send_raw_transaction(signed_snapshot_tx.raw_transaction)
    print(f"Snapshot transaction sent: {EXPLORER_URL}{"0x"+snapshot_tx_hash.hex()}")
    snapshot_receipt = w3.eth.wait_for_transaction_receipt(snapshot_tx_hash)
    print(f"Snapshot transaction receipt: {snapshot_receipt}")
    time.sleep(5)  # Wait for a few seconds to ensure the state is updated

apr = glusd_contract.functions.calculateAPR(7).call()
print(f"7-Day GLUSD APR: {apr / 100}%")

apy = glusd_contract.functions.calculateAPY(7).call()
print(f"7-Day GLUSD APY: {apy / 100}%")

apr_7_d, apr_30_d = glusd_contract.functions.getCurrentAPRs().call()
print(f"GLUSD Current APRs: 7-day: {apr_7_d / 100}%, 30-day: {apr_30_d / 100}%")

# breakpoint()

# if current_treasury.lower() != splitter_contract.address.lower():
#     print("Updating GLUSD treasury address to Revenue Splitter...")
#     nonce = w3.eth.get_transaction_count(admin_account.address)
#     txn = glusd_contract.functions.setTreasury(splitter_contract.address).build_transaction({
#         'from': admin_account.address,
#         'nonce': nonce,
#         'gas': 200000,
#         'gasPrice': w3.to_wei('10', 'gwei')
#     })
#     signed_txn = w3.eth.account.sign_transaction(txn, private_key=ADMIN_PRIVATE_KEY)
#     tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
#     print(f"Transaction sent: {EXPLORER_URL}{"0x"+tx_hash.hex()}")
#     receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
#     print(f"Transaction receipt: {receipt}")

#     time.sleep(5)  # Wait for a few seconds to ensure the state is updated

#     current_treasury = glusd_contract.functions.treasury().call()

#     print(f"Updated GLUSD Treasury Address: {current_treasury}")

#     if current_treasury.lower() == splitter_contract.address.lower():
#         print("GLUSD treasury address successfully updated to Revenue Splitter.")
#     else:
#         print("Failed to update GLUSD treasury address.")
#         sys.exit(1)


if glusd_total_supply == 0:
    mint_amount = 1 * 10 ** glusd_decimals # Mint 1 GLUSD for testing
    print(f"Minting {mint_amount / 10 ** glusd_decimals} GLUSD to admin...")

    if admin_usdc_balance < mint_amount:
        missing_amount = mint_amount - admin_usdc_balance
        print(f"Insufficient USDC balance to mint GLUSD, need {missing_amount / 10 ** usdc_decimals} more USDC.")
        sys.exit(1)

    approved_amount = usdc_contract.functions.allowance(
        admin_account.address,
        glusd_contract.address
    ).call()
    print(f"Approved USDC amount for GLUSD contract before minting: {approved_amount / 10 ** usdc_decimals}")
    
    if approved_amount < mint_amount:
        amount_to_approve = mint_amount - approved_amount
        print(f"Need to approve additional {amount_to_approve / 10 ** usdc_decimals} USDC for GLUSD contract.")
        print(f"Approving {amount_to_approve / 10 ** usdc_decimals} USDC for GLUSD contract...")
        nonce = w3.eth.get_transaction_count(admin_account.address)
        approve_txn = usdc_contract.functions.approve(
            glusd_contract.address,
            amount_to_approve
        ).build_transaction({
            'from': admin_account.address,
            'nonce': nonce,
            'gas': 100000,
            'gasPrice': w3.to_wei('10', 'gwei')
        })
        signed_approve_txn = w3.eth.account.sign_transaction(approve_txn, private_key=ADMIN_PRIVATE_KEY)
        approve_tx_hash = w3.eth.send_raw_transaction(signed_approve_txn.raw_transaction)
        print(f"Approve transaction sent: {EXPLORER_URL}{"0x"+approve_tx_hash.hex()}")
        approve_receipt = w3.eth.wait_for_transaction_receipt(approve_tx_hash)
        print(f"Approve transaction receipt: {approve_receipt}")

        new_approved_amount = usdc_contract.functions.allowance(
            admin_account.address,
            glusd_contract.address
        ).call()

        print(f"New approved USDC amount for GLUSD contract: {new_approved_amount / 10 ** usdc_decimals}")

        if new_approved_amount < mint_amount:
            print("Failed to approve sufficient USDC for GLUSD contract.")
            sys.exit(1)

        mint_tx = glusd_contract.functions.mint(
            mint_amount
        ).build_transaction({
            'from': admin_account.address,
            'nonce': w3.eth.get_transaction_count(admin_account.address),
            'gas': 200000,
            'gasPrice': w3.to_wei('10', 'gwei')
        })
        signed_mint_tx = w3.eth.account.sign_transaction(mint_tx, private_key=ADMIN_PRIVATE_KEY)
        mint_tx_hash = w3.eth.send_raw_transaction(signed_mint_tx.raw_transaction)
        print(f"Mint transaction sent: {EXPLORER_URL}{"0x"+mint_tx_hash.hex()}")
        mint_receipt = w3.eth.wait_for_transaction_receipt(mint_tx_hash)
        print(f"Mint transaction receipt: {mint_receipt}")

        time.sleep(5)  # Wait for a few seconds to ensure the state is updated

        glusd_total_supply = glusd_contract.functions.totalSupply().call()
        print(f"GLUSD Total Supply after minting: {glusd_total_supply / 10 ** glusd_decimals}")

admin_glusd_balance = glusd_contract.functions.balanceOf(admin_account.address).call()
print(f"Admin GLUSD Balance: {admin_glusd_balance / 10 ** glusd_decimals}")

# Revenue Splitter variables
BP_SCALE = compute_splitter_contract.functions.BP_SCALE().call()
print(f"Revenue Splitter BP_SCALE: {BP_SCALE}")

min_balance_to_distribute = compute_splitter_contract.functions.minBalanceToDistribute().call()
print(f"Revenue Splitter minBalanceToDistribute: {min_balance_to_distribute / 10 ** usdc_decimals}")

if CLEAR_RECIPIENTS:
    for splitter_contract in splitter_contracts:
        print(f"Clearing recipients in Revenue Splitter at address: {splitter_contract.address}...")

        clear_recipients_tx = splitter_contract.functions.clearRecipients().build_transaction({
            'from': admin_account.address,
            'nonce': w3.eth.get_transaction_count(admin_account.address),
        })

        try:
            gas_estimate = w3.eth.estimate_gas(clear_recipients_tx)
            print(f"Estimated gas for clearRecipients: {gas_estimate}")
        except Exception as e:
            print(f"Gas estimation failed: {e}")
            clear_recipients_tx['gas'] = 200000  # Fallback gas limit

        latest_block = w3.eth.get_block("latest")
        base_fee = latest_block.get("baseFeePerGas", w3.to_wei(15, "gwei"))
        priority_fee = w3.to_wei(2, "gwei")
        max_fee = base_fee + priority_fee

        clear_recipients_tx.update({
            'gas': int(gas_estimate * 1.5),
            'maxFeePerGas': max_fee,
            'maxPriorityFeePerGas': priority_fee,
            'type': 2
        })

        signed_clear_recipients_tx = w3.eth.account.sign_transaction(clear_recipients_tx, private_key=ADMIN_PRIVATE_KEY)
        clear_recipients_tx_hash = w3.eth.send_raw_transaction(signed_clear_recipients_tx.raw_transaction)
        print(f"Clear Recipients transaction sent: {EXPLORER_URL}{"0x"+clear_recipients_tx_hash.hex()}")
        clear_recipients_receipt = w3.eth.wait_for_transaction_receipt(clear_recipients_tx_hash)
        print(f"Clear Recipients transaction receipt: {clear_recipients_receipt}")

        time.sleep(5)  # Wait for a few seconds to ensure the state is updated

        after_clear_recipients = splitter_contract.functions.getRecipients().call()
        print(f"Recipients after clearing: {after_clear_recipients}")

        if len(after_clear_recipients) != 0:
            print("Failed to clear recipients in Revenue Splitter.")
            sys.exit(1)

for splitter_contract in splitter_contracts:
    splitter_recipients = splitter_contract.functions.getRecipients().call()
    print(f"contract: {splitter_contract.address}, splitter_recipients: {splitter_recipients}")

for splitter_contract in splitter_contracts:
    if splitter_contract.address == compute_splitter_contract.address:
        RECIPIENTS = COMPUTE_RECIPIENTS
        BASIS_POINTS = COMPUTE_BASIS_POINTS
    elif splitter_contract.address == storage_splitter_contract.address:
        RECIPIENTS = STORAGE_RECIPIENTS
        BASIS_POINTS = STORAGE_BASIS_POINTS

    if len(splitter_recipients) == 0:
        print("No recipients found in Revenue Splitter.")

        set_recipients_tx = splitter_contract.functions.setRecipients(RECIPIENTS, BASIS_POINTS).build_transaction({
            'from': admin_account.address,
            'nonce': w3.eth.get_transaction_count(admin_account.address),
        })
        try:
            gas_estimate = w3.eth.estimate_gas(set_recipients_tx)
            print(f"Estimated gas for setRecipients: {gas_estimate}")
        except Exception as e:
            print(f"Gas estimation failed: {e}")
            set_recipients_tx['gas'] = 200000  # Fallback gas limit

        latest_block = w3.eth.get_block("latest")
        base_fee = latest_block.get("baseFeePerGas", w3.to_wei(15, "gwei"))
        priority_fee = w3.to_wei(2, "gwei")
        max_fee = base_fee + priority_fee

        set_recipients_tx.update({
            'gas': int(gas_estimate * 1.5),
            'maxFeePerGas': max_fee,
            'maxPriorityFeePerGas': priority_fee,
            'type': 2
        })

        signed_set_recipients_tx = w3.eth.account.sign_transaction(set_recipients_tx, private_key=ADMIN_PRIVATE_KEY)
        set_recipients_tx_hash = w3.eth.send_raw_transaction(signed_set_recipients_tx.raw_transaction)
        print(f"Set Recipients transaction sent: {EXPLORER_URL}{"0x"+set_recipients_tx_hash.hex()}")
        set_recipients_receipt = w3.eth.wait_for_transaction_receipt(set_recipients_tx_hash)
        print(f"Set Recipients transaction receipt: {set_recipients_receipt}")

        time.sleep(5)  # Wait for a few seconds to ensure the state is updated

        new_splitter_recipients = splitter_contract.functions.getRecipients().call()
        print(f"New splitter_recipients: {new_splitter_recipients}")

        if len(new_splitter_recipients) == 0:
            print("Failed to set recipients in Revenue Splitter.")
            sys.exit(1)

for splitter_contract in splitter_contracts:
    for recipient in splitter_recipients:
        bps = splitter_contract.functions.getBpsForRecipient(recipient).call()
        print(f"Recipient: {recipient}, Basis Points: {(bps / BP_SCALE)*100}%")

for splitter_contract in splitter_contracts:
    splitter_usdc_balance = usdc_contract.functions.balanceOf(splitter_contract.address).call() 
    print(f"Revenue Splitter ({splitter_contract.address}) USDC Balance before distribution: {splitter_usdc_balance / 10 ** usdc_decimals}")  # Assuming USDC has 6 decimals

    if splitter_usdc_balance >= min_balance_to_distribute:

        # Distribute fees
        distribute_tx = splitter_contract.functions.distribute().build_transaction({
            'from': admin_account.address,  
            'nonce': w3.eth.get_transaction_count(admin_account.address),
        })

        try:
            gas_estimate = w3.eth.estimate_gas(distribute_tx)
            print(f"Estimated gas for distribute: {gas_estimate}")
        except Exception as e:
            print(f"Gas estimation failed: {e}")
            distribute_tx['gas'] = 200000  # Fallback gas limit

        latest_block = w3.eth.get_block("latest")
        base_fee = latest_block.get("baseFeePerGas", w3.to_wei(15, "gwei"))
        priority_fee = w3.to_wei(2, "gwei")
        max_fee = base_fee + priority_fee

        distribute_tx.update({
            'gas': int(gas_estimate * 1.5),
            'maxFeePerGas': max_fee,
            'maxPriorityFeePerGas': priority_fee,
            'type': 2
        })
        signed_distribute_tx = w3.eth.account.sign_transaction(distribute_tx, private_key=ADMIN_PRIVATE_KEY)
        distribute_tx_hash = w3.eth.send_raw_transaction(signed_distribute_tx.raw_transaction)
        print(f"Distribute transaction sent: {EXPLORER_URL}{"0x"+distribute_tx_hash.hex()}")
        distribute_receipt = w3.eth.wait_for_transaction_receipt(distribute_tx_hash)
        print(f"Distribute transaction receipt: {distribute_receipt}")

        time.sleep(5)  # Wait for a few seconds to ensure the state is updated
        splitter_usdc_balance_after = usdc_contract.functions.balanceOf(splitter_contract.address).call() 
        print(f"Revenue Splitter USDC Balance after distribution: {splitter_usdc_balance_after / 10 ** usdc_decimals}")  # Assuming USDC has 6 decimals



