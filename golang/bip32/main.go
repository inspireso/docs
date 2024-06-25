package main

import (
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/tyler-smith/go-bip32"
	"github.com/tyler-smith/go-bip39"
	"log"
)

func main() {
	// 设置助记词和密码
	mnemonic := "range sheriff try enroll deer over ten level bring display stamp recycle"
	password := ""

	// 检查助记词是否有效
	if !bip39.IsMnemonicValid(mnemonic) {
		fmt.Println("Invalid mnemonic")
		return
	}

	// 生成种子
	seed := bip39.NewSeed(mnemonic, password)

	// 从种子获取主私钥
	masterKey, err := bip32.NewMasterKey(seed)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	// 从主私钥派生以太坊地址的密钥
	ethereumKey, err := extendKey(masterKey)

	// 从密钥获取以太坊地址
	privKey, err := crypto.ToECDSA(ethereumKey.Key)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Your account private key:", common.BigToHash(privKey.D).Hex())

	address := crypto.PubkeyToAddress(privKey.PublicKey)
	fmt.Println("Your account address:", address.Hex())

}

// extendKey 从主私钥派生以太坊地址的密钥

// 表示 m/44'/60'/0'/0/0，其中 0x80000000 是 hardened 派生的标志
func extendKey(masterKey *bip32.Key) (*bip32.Key, error) {
	//m/purpose'/cointype'/account'/change/addrIndex
	key := masterKey
	err := error(nil)
	paths := []uint32{
		//purpose
		bip32.FirstHardenedChild + 44,
		//cointype
		bip32.FirstHardenedChild + 60,
		//account
		bip32.FirstHardenedChild + 0,
		//change
		0,
		//addrIndex
		0,
	}
	for _, path := range paths {
		key, err = key.NewChildKey(path)
		if err != nil {
			return nil, err
		}

	}
	return key, err

}
