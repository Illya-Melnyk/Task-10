require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

const ALCHEMY_API_KEY = "dps3VGz9kkCkOWGiyx5Y5JTqbiWitnEh";

const GOERLI_PRIVATE_KEY = "17a542edba0251cb26bbce41bf427def88aed434d752656745742ad98a453772";

module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  }
};