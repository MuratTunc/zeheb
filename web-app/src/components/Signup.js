// In Signup.js
import React from 'react';
import './Signup.css';

const Signup = ({ onCancel }) => {
  return (
    <div className="signup">
      <input type="text" placeholder="Username" />
      <input type="email" placeholder="Email" />
      <input type="password" placeholder="Password" />
      <button>Sign Up</button>
      <button className="cancel-btn" onClick={onCancel}>Cancel</button> {/* Cancel button */}
    </div>
  );
};

export default Signup;
