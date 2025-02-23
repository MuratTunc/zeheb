import React, { useState, useEffect, useRef } from "react";
import "./Signup.css";
import sendAuthCode from "../api/mail-service/sendAuthCode";

const Signup = ({ labels }) => {
  const [showPopup, setShowPopup] = useState(false);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isEmailTouched, setIsEmailTouched] = useState(false);
  const [isPasswordTouched, setIsPasswordTouched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [authCode, setAuthCode] = useState(""); // Store received auth code
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

  const handlePopupToggle = () => {
    if (!showPopup) {
      setFullName("");
      setEmail("");
      setPassword("");
      setAuthCode(""); // Reset auth code when reopening
      setIsEmailTouched(false);
      setIsPasswordTouched(false);
      setMessage(""); // Clear message on new popup open
    }
    setShowPopup(!showPopup);
  };

  const isSignupEnabled = email.trim().length > 0 && password.trim().length > 0;

  const handleSignup = async () => {
    if (!fullName || !email || !password) return;
  
    try {
      await sendAuthCode(fullName, email);
      console.log("Authentication code sent successfully!");
      // TODO: Open the authentication code entry popup here
    } catch (error) {
      console.error("Error sending authentication code:", error);
    }
  };

  return (
    <div className="signup-container" ref={popupRef}>
      <button className="signup-button" onClick={handlePopupToggle}>
        {labels.signup}
      </button>

      {showPopup && (
        <div className="signup-popup">
          <label className="signup-label">{labels.fullName}</label>
          <input
            type="text"
            className="signup-input"
            placeholder={labels.fullName}
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
          />

          <label className="signup-label">{labels.email}</label>
          <input
            type="email"
            className={`signup-input ${isEmailTouched && email.trim() === "" ? "error-border" : ""}`}
            placeholder={labels.email}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onBlur={() => setIsEmailTouched(true)}
          />

          <label className="signup-label">{labels.password}</label>
          <input
            type="password"
            className={`signup-input ${isPasswordTouched && password.trim() === "" ? "error-border" : ""}`}
            placeholder={labels.password}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onBlur={() => setIsPasswordTouched(true)}
          />

          <button
            className={`signup-submit ${!isSignupEnabled ? "disabled" : ""}`}
            onClick={handleSignup}
            disabled={!isSignupEnabled || loading}
          >
            {loading ? "Sending..." : labels.signupButton}
          </button>

          {message && <p className="signup-message">{message}</p>}

          {/* Show authentication code if received */}
          {authCode && (
            <p className="auth-code-display">
              ✅ Your Authentication Code: <strong>{authCode}</strong>
            </p>
          )}
        </div>
      )}
    </div>
  );
};

export default Signup;
