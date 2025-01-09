import React, { useState } from 'react';
import './Login.css';

const Login = ({ onLogin }) => {
  const [showLogin, setShowLogin] = useState(false);
  const [isNewUser, setIsNewUser] = useState(true); // Manage Sign Up / Sign In mode
  const [username, setUsername] = useState(''); // Temporary username input

  const toggleLogin = () => {
    setShowLogin(!showLogin);
  };

  const handleSubmit = () => {
    if (username) {
      onLogin(username); // Pass username to App.js
      setShowLogin(false); // Close dropdown
    } else {
      alert('Please enter a username'); // Basic validation
    }
  };

  const handleCancel = () => {
    setShowLogin(false);
  };

  const handleSwitch = () => {
    setIsNewUser(!isNewUser);
  };

  return (
    <div className="login-container">
      <button className="login-button" onClick={toggleLogin}>
        Login
      </button>
      {showLogin && (
        <div className="login-dropdown">
          <h3>{isNewUser ? 'Sign Up' : 'Sign In'}</h3>
          <form>
            <label htmlFor="username">Username</label>
            <input
              type="text"
              id="username"
              placeholder="Username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
            <label htmlFor="password">Password</label>
            <input type="password" id="password" placeholder="Password" required />
            <button type="button" className="submit-button" onClick={handleSubmit}>
              {isNewUser ? 'Sign Up' : 'Sign In'}
            </button>
          </form>
          <button className="cancel-button" onClick={handleCancel}>
            Cancel
          </button>
          <p className="switch" onClick={handleSwitch}>
            {isNewUser ? 'Already have an account? Sign In' : 'New here? Sign Up'}
          </p>
        </div>
      )}
    </div>
  );
};

export default Login;
