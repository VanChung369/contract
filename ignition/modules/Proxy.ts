import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const proxyModule = buildModule("ProxyModule", (m) => {
  const proxy = m.contract("Proxy");

  return { proxy };
});

export default proxyModule;
