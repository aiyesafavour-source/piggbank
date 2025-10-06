declare module 'react' {
  const React: any;
  export default React;
  export * from 'react';
}

declare module 'react-dom/client' {
  export const createRoot: any;
}

declare module 'wagmi' {
  export const WagmiProvider: any;
  export function createConfig(...args: any[]): any;
}

declare module 'wagmi/chains' {
  export const mainnet: any;
  export const sepolia: any;
}

declare module 'wagmi/connectors' {
  export function injected(...args: any[]): any;
}

declare module '@tanstack/react-query' {
  export class QueryClient { constructor(...args: any[]); }
  export const QueryClientProvider: any;
}


