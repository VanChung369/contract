import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const implementationModule = buildModule("ImplementationModule", (m) => {
  const _proxy = m.getParameter("_proxy");

  const implementation = m.contract("ImplementationV1", [_proxy]);

  const proxy = m.contractAt("Proxy", _proxy);

  m.call(proxy, "upgradeTo", [implementation]);

  return { implementation };
});

export default implementationModule;
