import React, { useState, useEffect, useRef } from "react";
import "./Signup.css";
import sendAuthCode from "../api/mail-service/sendAuthCode";
import registerNewUser from "../api/user-service/registerNewUser"; // Import registerNewUser.js

const Signup = ({ labels, setAuth, setFullName }) => {
  const [showPopup, setShowPopup] = useState(false);
  const [fullName, setLocalFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authCode, setAuthCode] = useState(""); // Store received auth code
  const [enteredCode, setEnteredCode] = useState(["", "", "", "", "", ""]); // 6-digit code array
  const [verifyButtonText, setVerifyButtonText] = useState(labels.verifyButton); // For verification button text
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

  const handleSignup = async () => {
    setMessage("Sending authentication code...");
    try {
      const result = await sendAuthCode(fullName, email);
      if (result?.authCode) {
        setMessage("Verification code sent to your email.");
        setAuthCode(result.authCode);
      } else {
        setMessage("Failed to send authentication code.");
      }
    } catch (error) {
      console.error("❌ Error sending authentication code:", error); // Full error log
      console.error("🔹 Error Message:", error.message); // Error message
      console.error("🔹 Error Response:", error.response); // API response (if available)
      console.error("🔹 Error Stack:", error.stack); // Error stack trace
      
      setMessage(`Error: ${error.message || "Failed to send authentication code."}`);
    }
  };
  

  const handleVerify = async () => {
    setVerifyButtonText("Verifying...");
    const code = enteredCode.join("");

    if (code === authCode) {
      try {
        const result = await registerNewUser(fullName, email, password);
        if (result?.success) {
          setVerifyButtonText("Verified!");
          setFullName(fullName); // Set full name in Header.js
          setAuth(true); // Hide Signin/Signup in Header.js
          setTimeout(() => setShowPopup(false), 1000);
        } else {
          setMessage("Registration failed. Try again.");
          setVerifyButtonText(labels.verifyButton);
        }
      } catch (error) {
        setMessage("Registration error.");
        setVerifyButtonText(labels.verifyButton);
      }
    } else {
      setMessage("Incorrect code. Try again.");
      setVerifyButtonText(labels.verifyButton);
      setEnteredCode(["", "", "", "", "", ""]);
    }
  };

  return (
    <div className="signup-container" ref={popupRef}>
      <button className="signup-button" onClick={() => setShowPopup(true)}>
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
            onChange={(e) => setLocalFullName(e.target.value)}
          />

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

          <button className="signup-submit" onClick={handleSignup}>
            {labels.signupButton}
          </button>

          {message && <p className="signup-message">{message}</p>}

          {authCode && (
            <>
              <label className="auth-code-label">Enter 6-digit Code</label>
              <div className="auth-code-inputs">
                {enteredCode.map((digit, index) => (
                  <input
                    key={index}
                    type="text"
                    maxLength="1"
                    value={digit}
                    onChange={(e) => {
                      const newCode = [...enteredCode];
                      newCode[index] = e.target.value.slice(0, 1);
                      setEnteredCode(newCode);
                    }}
                  />
                ))}
              </div>
              <button className="verify-button" onClick={handleVerify}>
                {verifyButtonText}
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default Signup;
