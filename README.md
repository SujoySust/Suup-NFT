# SUUPNFT Smart Contract and Test Suite

This repository contains a Solidity smart contract named `SUUPNFT` that implements an ERC721-based NFT (Non-Fungible Token) contract with additional functionality. The smart contract allows for the management of administrators, minting of NFTs, and more.

## Smart Contract

The `SUUPNFT` contract extends ERC721URIStorage and includes features such as:

- Adding and deleting administrators.
- Managing the list of administrators.
- Minting NFTs with associated URIs.
- Withdrawing native currency.

## Getting Started

### Prerequisites

- Node.js and npm: Make sure you have Node.js and npm (Node Package Manager) installed on your machine.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   ```

2. Install the dependencies:
   ```bash
   npm install
   ```
3. Running Tests
- To run the tests for the smart contract, you can use Truffle and its built-in test runner:
   ```bash
   truffle test
   ```
- Make sure you have a development blockchain running (e.g., using Ganache) or are connected to a testnet to execute the tests.

4. Smart Contract Usage

- The SUUPNFT contract provides functions for administrators to manage the contract and mint NFTs. You can interact with the contract through a web3-enabled interface or using Truffle console.

- Please refer to the smart contract's source code for details about the available functions and their usage.

### License
- This project is licensed under the MIT License. See the LICENSE file for details.
    ```bash
    Remember to customize the placeholders such as `your-username`, `your-repo`, and `LICENSE` with your actual information.
    ```