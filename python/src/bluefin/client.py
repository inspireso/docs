import asyncio
from pprint import pprint

from bluefin_v2_client import MARKET_SYMBOLS, BluefinClient, Networks, SuiWallet

# from config import TEST_ACCT_KEY, TEST_NETWORK


# async def main():

#     # Initialize using seed phrase
#     ed25519_wallet_seed_phrase = "seminar doll town blanket custom camera muscle lottery wood believe cigar lounge"

#     wallet = SuiWallet(seed=ed25519_wallet_seed_phrase)
#     print(wallet.getUserAddress())

#     client = BluefinClient(True, Networks["SUI_STAGING"], ed25519_wallet_seed_phrase)
#     await client.init(True)

#     exchange_info = await client.get_exchange_info(MARKET_SYMBOLS.ETH)
#     pprint(exchange_info)

#     await client.close_connections()


if __name__ == "__main__":
    import bip_utils

    ed25519_wallet_seed_phrase = "seminar doll town blanket custom camera muscle lottery wood believe cigar lounge"

    bip39_seed = bip_utils.Bip39SeedGenerator(ed25519_wallet_seed_phrase).Generate()
    bip32_ctx = bip_utils.Bip32Slip10Ed25519.FromSeed(bip39_seed)

    print(f"masterKey: {bip32_ctx.PrivateKey().Raw().ToHex()}")

    derivation_path = "m/44'/784'/0'/0'/0'"
    bip32_der_ctx = bip32_ctx.DerivePath(derivation_path)
    private_key: str = bip32_der_ctx.PrivateKey().Raw().ToHex()

    print(f"privateKey: {private_key}")

    wallet = SuiWallet(seed=ed25519_wallet_seed_phrase)
    print(wallet.publicKey)
    print(wallet.getUserAddress())

    # loop = asyncio.new_event_loop()
    # loop.run_until_complete(main())
    # loop.close()
    # 0xbb375cfe711248d3a5a6450aff4f889bbcd57420ff9508ef75ddbc2c6f1ee94b
    # 0xbb375cfe711248d3a5a6450aff4f889bbcd57420ff9508ef75ddbc2c6f1ee94b

    # b0fc74d925b8161ac430faa40f0e230dbf4ab0b044d6fe33762927ff3b4a83c70d1dcdf4219e26241e844a7f2c866a979e8b55f3f774a361de0ac494f3872a4b
    # b0fc74d925b8161ac430faa40f0e230dbf4ab0b044d6fe33762927ff3b4a83c70d1dcdf4219e26241e844a7f2c866a979e8b55f3f774a361de0ac494f3872a4b
