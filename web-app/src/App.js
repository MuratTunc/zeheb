import React, { useState } from 'react';
import Header from './components/Header.js';
import './App.css';

function App() {
  const [loggedIn, setLoggedIn] = useState(false); // Track login state
  const [username, setUsername] = useState(''); // Store username

  // Handle login
  const handleLogin = (user) => {
    setLoggedIn(true);
    setUsername(user);
  };

  // Handle logout
  const handleLogout = () => {
    setLoggedIn(false);
    setUsername('');
  };

  return (
    <div>
      <Header loggedIn={loggedIn} username={username} onLogout={handleLogout} onLogin={handleLogin} />
      <main>
        {/* Other components or content */}
      </main>
    </div>
  );
}

export default App;