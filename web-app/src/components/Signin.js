// In Signin.js
import React from 'react';
import './Signin.css';

const Signin = ({ onCancel }) => {
  return (
    <div className="signin">
      <input type="text" placeholder="Username" />
      <input type="password" placeholder="Password" />
      <button>Sign In</button>
      <button className="cancel-btn" onClick={onCancel}>Cancel</button> {/* Cancel button */}
    </div>
  );
};

export default Signin;
