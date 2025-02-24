// Logout.js
import React from 'react';

const Logout = ({ setAuth, setFullName }) => {
  const handleLogout = () => {
    // Reset the authentication state
    setAuth(false);
    setFullName(""); // Clear the full name when logging out
    // You could also clear any other necessary data like tokens here
  };

  return (
    <button onClick={handleLogout} className="popup-button">
      Logout
    </button>
  );
};

export default Logout;
