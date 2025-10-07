import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import { useAccount, useConnect, useDisconnect } from 'wagmi';
export function WalletConnect() {
    const { address, isConnected } = useAccount();
    const { connect, connectors, status, error } = useConnect();
    const { disconnect } = useDisconnect();
    if (isConnected) {
        return (_jsxs("div", { style: { display: 'flex', gap: 12, alignItems: 'center' }, children: [_jsxs("span", { children: ["Connected: ", address] }), _jsx("button", { onClick: () => disconnect(), children: "Disconnect" })] }));
    }
    return (_jsxs("div", { style: { display: 'flex', gap: 12, alignItems: 'center' }, children: [connectors.map((c) => (_jsxs("button", { onClick: () => connect({ connector: c }), disabled: !c.ready, children: ["Connect ", c.name] }, c.uid))), status === 'connecting' && _jsx("span", { children: "Connecting..." }), error && _jsx("span", { style: { color: 'red' }, children: error.message })] }));
}
