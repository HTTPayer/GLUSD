import os, json, sys, time
from dotenv import load_dotenv
from web3 import Web3
from eth_account import Account
from web3.middleware import ExtraDataToPOAMiddleware, LocalFilterMiddleware
from apscheduler.schedulers.blocking import BlockingScheduler

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

print(f"BASE_DIR: {BASE_DIR}")

load_dotenv()

RPC_URL = os.getenv("RPC_URL")
EXPLORER_URL = os.getenv("EXPLORER_URL", "https://testnet.snowtrace.io/tx/")
ADMIN_PRIVATE_KEY = os.getenv("ADMIN_PRIVATE_KEY")

global MIN_DISTRIBUTE_USDC

MIN_DISTRIBUTE_USDC = os.getenv("MIN_DISTRIBUTE_USDC", None)

USDC_ADDRESS_RAW = os.getenv("USDC_ADDRESS", "0x5425890298aed601595a70ab815c96711a31bc65")
USDC_ADDRESS = Web3.to_checksum_address(USDC_ADDRESS_RAW)

w3 = Web3(Web3.HTTPProvider(RPC_URL))
w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
w3.middleware_onion.add(LocalFilterMiddleware)

admin_account = Account.from_key(ADMIN_PRIVATE_KEY)
w3.eth.default_account = admin_account.address

GLUSD_ABI_PATH = os.path.join(BASE_DIR, "..", "contracts", "out", "GLUSD.sol", "GLUSD.json")
with open(GLUSD_ABI_PATH, 'r') as f:
    GLUSD_ABI = json.load(f)["abi"]

GLUSD_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "GLUSD.json")
with open(GLUSD_ADDRESS_PATH, 'r') as f:
    GLUSD_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

ERC20_ABI_PATH = os.path.join(BASE_DIR, "..", "contracts", "out", "ERC20.sol", "ERC20.json")
with open(ERC20_ABI_PATH, 'r') as f:
    ERC20_ABI = json.load(f)["abi"]

SPLITTER_ABI_PATH = os.path.join(BASE_DIR, "..", "contracts", "out", "RevenueSplitter.sol", "RevenueSplitter.json")
with open(SPLITTER_ABI_PATH, 'r') as f:
    SPLITTER_ABI = json.load(f)["abi"]

COMPUTE_SPLITTER_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "ComputeRevenueSplitter.json")
with open(COMPUTE_SPLITTER_ADDRESS_PATH, 'r') as f:
    COMPUTE_SPLITTER_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

STORAGE_SPLITTER_ADDRESS_PATH = os.path.join(BASE_DIR, "..", "contracts", "deployments", "StorageRevenueSplitter.json")
with open(STORAGE_SPLITTER_ADDRESS_PATH, 'r') as f:
    STORAGE_SPLITTER_ADDRESS = w3.to_checksum_address(json.load(f)['deployedTo'])

glusd_contract = w3.eth.contract(
    address=w3.to_checksum_address(GLUSD_ADDRESS),
    abi=GLUSD_ABI
) 

glusd_decimals = glusd_contract.functions.decimals().call()


usdc_contract = w3.eth.contract(
    address=USDC_ADDRESS,
    abi=ERC20_ABI
)

usdc_decimals = usdc_contract.functions.decimals().call()

compute_splitter_contract = w3.eth.contract(
    address=w3.to_checksum_address(COMPUTE_SPLITTER_ADDRESS),
    abi=SPLITTER_ABI
)

storage_splitter_contract = w3.eth.contract(
    address=w3.to_checksum_address(STORAGE_SPLITTER_ADDRESS),
    abi=SPLITTER_ABI
)

splitter_contracts = [compute_splitter_contract, storage_splitter_contract]

def take_snapshot():
    print("---")
    print(f"Checking if GLUSD snapshot is needed at {time.ctime()}...")
    try:
        last_snapshot_time = glusd_contract.functions.lastSnapshotTime().call()
        min_snapshot_interval = glusd_contract.functions.MIN_SNAPSHOT_INTERVAL().call()

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

            return "0x" + snapshot_tx_hash.hex()
        else:
            print("Snapshot interval not reached yet. Skipping snapshot.")
            return None
    except Exception as e:
        print(f"Error taking snapshot: {e}")
        return None
    
def distribute_revenue():
    print("---")
    print(f"Checking revenue distribution at {time.ctime()}...")
    global MIN_DISTRIBUTE_USDC

    min_balance_to_distribute = compute_splitter_contract.functions.minBalanceToDistribute().call()

    for splitter_contract in splitter_contracts:
        splitter_usdc_balance = usdc_contract.functions.balanceOf(splitter_contract.address).call() 
        print(f"Revenue Splitter ({splitter_contract.address}) USDC Balance before distribution: {splitter_usdc_balance / 10 ** usdc_decimals}") 

        if MIN_DISTRIBUTE_USDC:
            MIN_DISTRIBUTE_USDC_RAW = int(float(MIN_DISTRIBUTE_USDC) * (10 ** usdc_decimals))
            print(f"Overriding minBalanceToDistribute to {MIN_DISTRIBUTE_USDC} USDC ({MIN_DISTRIBUTE_USDC_RAW} raw)")
        else:
            MIN_DISTRIBUTE_USDC_RAW = 0

        if splitter_usdc_balance >= max(MIN_DISTRIBUTE_USDC_RAW, min_balance_to_distribute):

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

            native_balance = w3.eth.get_balance(admin_account.address)
            print(f"Admin Gas Balance: {w3.from_wei(native_balance, 'ether')} AVAX")

            required_fee = max_fee * gas_estimate
            if native_balance < required_fee:
                print(f"[{admin_account.address}] Insufficient native balance for gas. "
                    f"Required: {w3.from_wei(required_fee, 'ether')} AVAX, "
                    f"Available: {w3.from_wei(native_balance, 'ether')} AVAX")
                return

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
            # print(f"Distribute transaction receipt: {distribute_receipt}")

            time.sleep(5)  # Wait for a few seconds to ensure the state is updated
            splitter_usdc_balance_after = usdc_contract.functions.balanceOf(splitter_contract.address).call() 
            print(f"Revenue Splitter USDC Balance after distribution: {splitter_usdc_balance_after / 10 ** usdc_decimals}")
        else:
            print(f"Revenue Splitter ({splitter_contract.address}) USDC Balance below minimum threshold. Skipping distribution.")
        
scheduler = BlockingScheduler()
scheduler.add_job(take_snapshot, 'interval', minutes=30)
scheduler.add_job(distribute_revenue, 'interval', minutes=15)


if __name__ == "__main__":
    take_snapshot()
    distribute_revenue()
    print("Starting background job scheduler...")

    scheduler.start()