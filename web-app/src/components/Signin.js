import React, { useState, useEffect, useRef } from "react";
import "./Signin.css";

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
      // Simulate API call (Replace with actual API request)
      const result = await fakeSigninAPI(email, password);

      if (result.success) {
        setFullName(result.fullName); // Store the user's full name
        setAuth(true); // Mark authentication success
        setShowPopup(false); // Close popup
      } else {
        setMessage("❌ Invalid email or password.");
      }
    } catch (error) {
      setMessage("❌ Error signing in.");
    }
  };

  // Fake API for testing (replace with real API call)
  const fakeSigninAPI = async (email, password) => {
    return new Promise((resolve) => {
      setTimeout(() => {
        if (email === "murat.tunc8558@gmail.com" && password === "12345678") {
          resolve({ success: true, fullName: "Murat Tunç" });
        } else {
          resolve({ success: false });
        }
      }, 1000);
    });
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
