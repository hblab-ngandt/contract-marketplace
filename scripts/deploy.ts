const { ethers } = require("hardhat");

async function main() {
  const ImageMarketplace = await ethers.getContractFactory("ImageMarketplace");
  const imageMarketplace = await ImageMarketplace.deploy();

  console.log("Marketplace deployed to:", imageMarketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});