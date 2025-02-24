import React, { useState, useEffect, useRef } from "react";
import "./Signup.css";
import sendAuthCode from "../api/mail-service/sendAuthCode";
import registerNewUser from "../api/user-service/registerNewUser"; // Import registerNewUser.js

const Signup = ({ labels, setAuth }) => {
  const [showPopup, setShowPopup] = useState(false);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isEmailTouched, setIsEmailTouched] = useState(false);
  const [isPasswordTouched, setIsPasswordTouched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [authCode, setAuthCode] = useState(""); // Store received auth code
  const [enteredCode, setEnteredCode] = useState(["", "", "", "", "", ""]); // 6 digit code array
  const [verifyButtonText, setVerifyButtonText] = useState(labels.verifyButton); // For the verify button text
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
      setEnteredCode(["", "", "", "", "", ""]); // Reset the entered 6-digit code
    }
    setShowPopup(!showPopup);
  };

  const isSignupEnabled = email.trim().length > 0 && password.trim().length > 0;

  const handleSignup = async () => {
    if (!isSignupEnabled) return;
  
    setLoading(true);
    setMessage("");
  
    try {
      setMessage("Sending 6-digit code to your email address...");
      // Call sendAuthCode and handle the response
      const result = await sendAuthCode(fullName, email);
      // Log the result for debugging
      console.log("Auth code response:", result);
  
      // Check if the response contains an auth code
      if (result?.authCode) {
        setMessage("6-digit verification code has been sent to your email address.");
        setAuthCode(result.authCode); // Store received auth code in state
      } else {
        setMessage("Authentication code not received from the server.");
      }
    } catch (error) {
      console.error("Error sending authentication code:", error);
  
      // Check if the error has a message from the backend
      setMessage(`❌ ${error.message || "Failed to send authentication code."}`);
    } finally {
      setLoading(false);
    }
  };
  

  const handleCodeInputChange = (e, index) => {
    const newCode = [...enteredCode];
    newCode[index] = e.target.value.slice(0, 1); // Only allow one digit per field
    setEnteredCode(newCode);
    // Move to the next input field after entering a digit
    if (e.target.value.length === 1 && index < 5) {
      document.getElementById(`digit-${index + 1}`).focus();
    }
  };

  const handleVerify = async () => {
    setVerifyButtonText("Verifying...");
  
    const code = enteredCode.join(""); // Join the array of digits into a single string
    console.log("Verification Code Entered: ", code);
  
    if (code === authCode) {
      try {
        const result = await registerNewUser(fullName, email, password); // Call registerNewUser
        if (result?.success) {
          setVerifyButtonText("Verified Success"); // Success, show success text
  
          // After successful registration, set authentication to true
          setAuth(true);  // Update authentication state
  
          setTimeout(() => setShowPopup(false), 1000); // Close popup after 1 second
        } else {
          setMessage("❌ Registration failed. Please try again.");
          setVerifyButtonText(labels.verifyButton); // Reset button text
        }
      } catch (error) {
        console.error("❌ Error during registration:", error);
        setMessage("❌ Registration error. Please try again.");
        setVerifyButtonText(labels.verifyButton); // Reset button text
      }
    } else {
      setMessage("❌ Incorrect code. Please try again.");
      setVerifyButtonText(labels.verifyButton); // Reset button text
      setEnteredCode(["", "", "", "", "", ""]); // Reset the 6-digit code on failure
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

          {/* This is where the message is displayed, with conditional styling */}
          {message && (
            <p className={message.startsWith("❌") ? "error-message" : "signup-message"}>
              {message}
            </p>
          )}

          {/* Show authentication code if received */}
          {authCode && (
            <>
              <div className="auth-code-inputs">
                <label className="auth-code-label">Enter your 6-digit Code</label>
                <div className="auth-code-inputs-container">
                  {enteredCode.map((digit, index) => (
                    <input
                      key={index}
                      id={`digit-${index}`}
                      type="text"
                      maxLength="1"
                      value={digit}
                      onChange={(e) => handleCodeInputChange(e, index)}
                      className="auth-code-input"
                    />
                  ))}
                </div>
              </div>
              <button
                className="verify-button"
                onClick={handleVerify}
                disabled={enteredCode.includes("")} // Disable verify button until all fields are filled
              >
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
