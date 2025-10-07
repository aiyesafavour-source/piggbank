import { createConfig, http } from 'wagmi';
import { mainnet, sepolia } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

// TODO: Replace with your own WalletConnect project ID
const projectId = 'YOUR_PROJECT_ID';

export const wagmiConfig = createConfig({
  chains: [sepolia, mainnet],
  connectors: [
    injected(),
    walletConnect({ projectId, showQrModal: true }),
  ],
  transports: {
    [sepolia.id]: http(),
    [mainnet.id]: http(),
  },
});


