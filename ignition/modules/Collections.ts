import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const collectionModule = buildModule("CollectionModule", (m) => {
  const _proxy = m.getParameter("_proxy");

  const collection721 = m.contract("Collection721", [_proxy, ""]);

  const collection1155 = m.contract("Collection1155", [_proxy, ""]);

  return { collection721, collection1155 };
});

export default collectionModule;
