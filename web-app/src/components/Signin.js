import React, { useState } from "react";
import "./Signin.css"; // Importing the CSS file

const Signin = ({ labels }) => {
  const [showPopup, setShowPopup] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = () => {
    console.log("Logging in with:", email, password);
  };

  return (
    <div className="signin-container">
      {/* Signin Button */}
      <button className="signin-button" onClick={() => setShowPopup(!showPopup)}>
        {labels.signin}
      </button>

      {/* Popup Form */}
      {showPopup && (
        <div className="signin-popup">
          <label className="signin-label">{labels.email}</label>
          <input
            type="email"
            className="signin-input"
            placeholder={labels.email}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />

          <label className="signin-label">{labels.password}</label>
          <input
            type="password"
            className="signin-input"
            placeholder={labels.password}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <button className="signin-submit" onClick={handleLogin}>
            {labels.login}
          </button>
        </div>
      )}
    </div>
  );
};

export default Signin;
