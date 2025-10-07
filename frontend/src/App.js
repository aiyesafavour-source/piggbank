import { jsx as _jsx } from "react/jsx-runtime";
import Home from './pages/Home';
import { ThemeProvider } from './lib/theme';
function App() {
    return (_jsx(ThemeProvider, { children: _jsx(Home, {}) }));
}
export default App;
