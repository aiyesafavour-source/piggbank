import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { wagmiConfig } from './lib/wagmi';

const queryClient = new QueryClient();

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  React.createElement(
    React.StrictMode,
    null,
    React.createElement(
      WagmiProvider as any,
      { config: wagmiConfig },
      React.createElement(
        QueryClientProvider as any,
        { client: queryClient },
        React.createElement(App, null)
      )
    )
  )
);


