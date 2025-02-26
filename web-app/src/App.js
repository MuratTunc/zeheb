import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Header from "./components/Header";

function App() {
  return (
    <Router>
      <Header />
      <Routes>
        <Route path="/signin" element={<h2>Signin Page</h2>} />
        <Route path="/signup" element={<h2>Signup Page</h2>} />
        <Route path="/" element={<h2>Home</h2>} />
      </Routes>
    </Router>
  );
}

export default App;
