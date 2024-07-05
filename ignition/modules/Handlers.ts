import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const handlerModule = buildModule("HandlerModule", (m) => {
  const _proxy = m.getParameter("_proxy");
  const signatureUtils = m.library("SignatureUtils");

  const mintHandler = m.contract("MintHandler", [_proxy], {
    libraries: {
      SignatureUtils: signatureUtils,
    },
  });

  const buyHandler = m.contract("BuyHandler", [_proxy], {
    libraries: {
      SignatureUtils: signatureUtils,
    },
  });

  const cancelHandler = m.contract("CancelHandler", [_proxy], {
    libraries: {
      SignatureUtils: signatureUtils,
    },
  });

  const adminMintHandler = m.contract("AdminMintHandler", [_proxy]);

  return { mintHandler, buyHandler, cancelHandler, adminMintHandler };
});

export default handlerModule;
