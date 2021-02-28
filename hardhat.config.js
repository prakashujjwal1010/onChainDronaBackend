require("@nomiclabs/hardhat-waffle");
//import GOERLI_PRIVATE_KEY from './privateKey';

// The next line is part of the sample project, you don't need it in your
// project. It imports a Hardhat task definition, that can be used for
// testing the frontend.
require("./tasks/faucet");

const ALCHEMY_API_KEY = "";

const GOERLI_PRIVATE_KEY = "";
const MATIC_PRIVATE_KEY = "";

module.exports = {
  solidity: "0.7.3",
  networks: {
    ropsten: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`0x${GOERLI_PRIVATE_KEY}`]
    },
    matic: {
      url: "https://rpc-mumbai.matic.today/",
      accounts: [`0x${MATIC_PRIVATE_KEY}`],
      chainId: 80001,
    }
  },
  /*solidity: {
    version: "^0.6.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },*/
};
