import React, { useState, useEffect, useRef } from "react";
import "./Signin.css";
import loginUser from "../api/user-service/loginUser";

const Signin = ({ labels, setAuth, setFullName }) => {
  const [showPopup, setShowPopup] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const popupRef = useRef(null);

  useEffect(() => {
    if (showPopup) {
      document.addEventListener("mousedown", handleClickOutside);
    } else {
      document.removeEventListener("mousedown", handleClickOutside);
    }
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [showPopup]);

  const handleClickOutside = (event) => {
    if (popupRef.current && !popupRef.current.contains(event.target)) {
      setShowPopup(false);
    }
  };

  const handleSignin = async () => {
    setMessage("Signing in...");
  
    try {
      const result = await loginUser(email, password);
      console.log("Login result:", result); // Debugging log
  
      if (result.loginStatus === "true") {
        setFullName(result.username); // Store the user's username
        setAuth(true); // Mark authentication success
  
        // Save JWT token in localStorage
        localStorage.setItem("authToken", result.token); // Save token to localStorage
  
        setShowPopup(false); // Close popup
      } else {
        setMessage("❌ Invalid email or password.");
      }
    } catch (error) {
      console.error(error);
      setMessage("❌ Error signing in.");
    }
  };

  return (
    <div className="signin-container" ref={popupRef}>
      <button className="signin-button" onClick={() => setShowPopup(!showPopup)}>
        {labels.signin}
      </button>

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

          <button className="signin-submit" onClick={handleSignin}>
            {labels.login}
          </button>

          {message && <p className="signin-message">{message}</p>}
        </div>
      )}
    </div>
  );
};

export default Signin;
