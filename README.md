Get the best ETH put option price from Hegic, Opyn, Auctus by calling a single function.

# Setup

1. create a `.env` file like below:

   ```
   INFURA_API_KEY =
   DEPLOYMENT_ACCOUNT_KEY =
   ```

   _\*ask for values to the team and pass them_

2. navigate to your repo directory and install the dependencies:

   ```
   npm install
   ```

# Deploy to a Local Ganache Instance That Mirrors the Mainnet

1. Install the [Ganache CLI](https://github.com/trufflesuite/ganache-cli)

   ```
   npm install -g ganache-cli
   ```

2. _Fork_ and mirror mainnet into your Ganache instance.
   You can fork mainnet and use each protocol's production contracts and production ERC20 tokens.
   Replace `INFURA_API_KEY` with the value in the following and run:

   ```
   ganache-cli --fork https://mainnet.infura.io/v3/INFURA_API_KEY -i 1
   ```

3. In a new terminal window in your repo directory, run:

   ```
   truffle console
   ```

4. Migrate your contracts to your instance of Ganache with:

   ```
   migrate --reset
   ```

   \*After a few minutes, your contract will be deployed.

# Deploy to the Mainnet

1. Run:

   ```
   truffle console --network mainnet
   ```

2. You are now connected to the mainnet. Now, use the migrate command to deploy your contracts:

   ```
   migrate --reset
   ```

# Interact With the Contract

Call your contract's function within the truffle console.

```

```

If your implementation is correct, then the transaction will succeed. If it fails/reverts, a reason will be given.

\*if the above operation takes an unreasonably long time or timesout, try `CTRL+C` to exit the Truffle console, run `truffle console` again, then try this step agin. You may need to wait a few blocks before your node can 'see' the deployed contract.

# EOA Address

We are using this EOA address `0xcc84e428b30ea976f932d77293df4ba8edd7307f`.

# Known issues

## No access to archive state errors

If you are using Ganache to fork a network, then you may have issues with the blockchain archive state every 30 minutes. This is due to your node provider (i.e. Infura) only allowing free users access to 30 minutes of archive state. You can either 1) upgrade to a paid plan or 2) restart your ganache instance and redploy your contracts.

# Versions

```bash
$ truffle --version
Truffle v5.1.51
$ ganache-cli --version
Ganache CLI v6.12.1 (ganache-core: 2.13.1)
```
