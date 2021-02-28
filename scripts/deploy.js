// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  /*const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy();
  await token.deployed();

  console.log("Token address:", token.address);*/

  const OnChainDrona = await ethers.getContractFactory("OnChainDrona");
  const onChainDrona = await OnChainDrona.deploy("0xEB796bdb90fFA0f28255275e16936D25d3418603","0x49e565Ed1bdc17F3d220f72DF0857C26FA83F873", "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f");
  await onChainDrona.deployed();

  console.log("OnChainDrona address:", onChainDrona.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(onChainDrona);
}

function saveFrontendFiles(onChainDrona) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../frontend/src/contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    JSON.stringify({ OnChainDrona: onChainDrona.address }, undefined, 2)
  );

  const OnChainDronaArtifact = artifacts.readArtifactSync("OnChainDrona");

  fs.writeFileSync(
    contractsDir + "/OnChainDrona.json",
    JSON.stringify(OnChainDronaArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
