import hre from "hardhat";
import proxyModule from "../ignition/modules/Proxy";
import implementationModule from "../ignition/modules/Implementation";
import handlerModule from "../ignition/modules/Handlers";
import collectionModule from "../ignition/modules/Collections";
const fs = require("fs");
require("dotenv").config();

async function main() {
  const { proxy } = await hre.ignition.deploy(proxyModule);

  console.log(`Proxy contract address: ${proxy.target}`);

  const _proxy = await proxy.getAddress();

  const { implementation } = await hre.ignition.deploy(implementationModule, {
    parameters: {
      ImplementationModule: {
        _proxy: _proxy,
      },
    },
  });

  console.log(`Implementation contract address: ${implementation.target}`);
  console.log(`Upgraded: ${await proxy.implementation()}`);

  const { mintHandler, buyHandler, cancelHandler, adminMintHandler } =
    await hre.ignition.deploy(handlerModule, {
      parameters: {
        HandlerModule: {
          _proxy: _proxy,
        },
      },
    });

  console.log(`Mint handler contract address: ${mintHandler.target}`);
  console.log(`Buy handler contract address: ${buyHandler.target}`);
  console.log(`Cancel handler contract address: ${cancelHandler.target}`);
  console.log(
    `Admin mint handler contract address: ${adminMintHandler.target}`
  );

  const { collection721, collection1155 } = await hre.ignition.deploy(
    collectionModule,
    {
      parameters: {
        CollectionModule: {
          _proxy: _proxy,
        },
      },
    }
  );

  console.log(`Collection721 contract address: ${collection721.target}`);
  console.log(`Collection1155 contract address: ${collection1155.target}`);

  const contracts = {
    proxy: proxy.target,
    implementation: implementation.target,
    mintHandler: mintHandler.target,
    adminMintHandler: adminMintHandler.target,
    buyHandler: buyHandler.target,
    cancelHandler: cancelHandler.target,
    collection1155: collection1155.target,
    collection721: collection721.target,
  };

  fs.writeFileSync("./data/contracts.json", JSON.stringify(contracts));

  (await implementation.setMintHandler(mintHandler)).wait();
  (await implementation.setBuyHandler(buyHandler)).wait();
  (await implementation.setCancelHandler(cancelHandler)).wait();
  (await implementation.setSigner(process.env.SIGNER)).wait();
  (await implementation.setCollection721(collection721)).wait();
  (await implementation.setCollection1155(collection1155)).wait();

  // await hre.run("verify:verify", {
  //   address: proxy.target,
  // });

  // await hre.run("verify:verify", {
  //   address: implementation.target,
  //   constructorArguments: [proxy.target],
  // });
}

main().catch(console.error);
