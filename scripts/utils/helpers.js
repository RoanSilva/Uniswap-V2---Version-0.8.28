//# Funções auxiliares (por exemplo: wait, logging, format)

const waitForTx = async (tx) => {
  const receipt = await tx.wait();
  console.log(`Tx confirmed in block ${receipt.blockNumber}`);
};
