import React, { useState } from 'react';
import './Header.css';
import Signin from './Signin';
import Signup from './Signup';

const Header = () => {
  const [showSignin, setShowSignin] = useState(false);
  const [showSignup, setShowSignup] = useState(false);

  const handleClosePopup = () => {
    setShowSignin(false);
    setShowSignup(false);
  };

  return (
    <>
      <header className="header">
        <div className="header-left">
          <h1>MyApp</h1>
        </div>
        <div className="header-right">
          <button onClick={() => setShowSignin(true)}>SIGN IN</button>
          <button onClick={() => setShowSignup(true)}>SIGN UP</button>
        </div>
      </header>

      {showSignin && (
        <div className="popup">
          <div className="popup-content">
            {/* Removed the close "×" button */}
            <Signin onCancel={handleClosePopup} /> {/* Signin component with cancel button */}
          </div>
        </div>
      )}

      {showSignup && (
        <div className="popup">
          <div className="popup-content">
            {/* Removed the close "×" button */}
            <Signup onCancel={handleClosePopup} /> {/* Signup component with cancel button */}
          </div>
        </div>
      )}
    </>
  );
};

export default Header;
