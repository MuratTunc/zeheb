import React, { useState } from "react";
import "./Signup.css"; // Importing the CSS file

const Signup = ({ labels }) => {
  const [showPopup, setShowPopup] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const handleSignup = () => {
    console.log("Signing up with:", email, password, confirmPassword);
  };

  return (
    <div className="signup-container">
      {/* Signup Button */}
      <button className="signup-button" onClick={() => setShowPopup(!showPopup)}>
        {labels.signup}
      </button>

      {/* Popup Form */}
      {showPopup && (
        <div className="signup-popup">
          <label className="signup-label">{labels.email}</label>
          <input
            type="email"
            className="signup-input"
            placeholder={labels.email}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />

          <label className="signup-label">{labels.password}</label>
          <input
            type="password"
            className="signup-input"
            placeholder={labels.password}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <label className="signup-label">{labels.confirmPassword}</label>
          <input
            type="password"
            className="signup-input"
            placeholder={labels.confirmPassword}
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
          />

          <button className="signup-submit" onClick={handleSignup}>
            {labels.signup}
          </button>
        </div>
      )}
    </div>
  );
};

export default Signup;
