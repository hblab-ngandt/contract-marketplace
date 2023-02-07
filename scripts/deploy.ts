import { ethers, upgrades } from "hardhat";

async function main() {
  const ImageMarketplace = await ethers.getContractFactory('ImageMarketplace');
  const deployer = await upgrades.deployProxy(ImageMarketplace);
  await deployer.deployed();
  console.log('Contract address at: ', deployer.address);
  // const deployer = await ImageMarketplace.deploy();
  // console.log('Deployer address at: ', deployer.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
