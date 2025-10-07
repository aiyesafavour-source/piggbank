
declare module 'react-dom/client' {
  export const createRoot: any;
}


declare module '@tanstack/react-query' {
  export class QueryClient { constructor(...args: any[]); }
  export const QueryClientProvider: any;
}


