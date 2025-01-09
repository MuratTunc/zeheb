import React from 'react';
import './Header.css';
import Login from './Login'; // Import Login component

const Header = ({ loggedIn, username, onLogout, onLogin }) => {
  return (
    <header className="header">
      <h1 className="logo">ZEHEB</h1>
      <nav className="nav">
        {loggedIn ? (
          <div>
            <span className="username">{username}</span>
            <button className="logout-button" onClick={onLogout}>
              Logout
            </button>
          </div>
        ) : (
          <Login onLogin={onLogin} />
        )}
      </nav>
    </header>
  );
};

export default Header;
