# Ethereum Smart Contract

## IDE For Ethereum Smart Contract

1. Remix Ethereum IDE
1. The JetBrains tools, like android studio, support the solidity language, but the Remix allows us to test it on the fly

## Programming in Solidity

1. File Extension: .sol or .solidity
1. On https://remix.ethereum.org/ delete initial files
1. add a unique fil called Token/CoinName.sol
1. Check the compiler on the second tab on left to add it current version on the pragma of the .sol file
1. Add the smart contract code
1. Click to compile it
1. **Settings on the Remix Ethereum**:
    1. Account (third icon on the left menu):
        1. Environment = injected web3 (will connect to MetaMask)
    1. Click on deploy and it will generate a new transaction to deploy the contract on the blockchain
    1. After the deploy the "Deployed Contracts" will show up the functions implemented on the smart contract

The image on ./app/smart_contracts/ethereum/CodingSmartContractEthereumIDE.png shows the deployed contract showing the implemented clauses (methods) interactable on the left side 

Clicking on the output (on the bottom console) it shows the transactions created for each button click (deposit, withdraw...)

Clicking on the Getbalance button it shows the balance bottom it button

# Running personal blockchain instead infura

https://trufflesuite.com/ganache/

# Get ABI to know how to interact with the smart contract

1. ABI on RemixEthereum: Compile Tab (second action on the left) > ABI
1. Create an abi.json to store it (use the name of the coin or get it automatically from the network - TODO: need to do a research about it)