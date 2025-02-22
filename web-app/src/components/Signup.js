import React, { useState, useEffect, useRef } from "react";
import "./Signup.css";

const Signup = ({ labels }) => {
  const [showPopup, setShowPopup] = useState(false);
  const popupRef = useRef(null); // Reference to pop-up

  const handleClickOutside = (event) => {
    if (popupRef.current && !popupRef.current.contains(event.target)) {
      setShowPopup(false); // Close pop-up
    }
  };

  useEffect(() => {
    if (showPopup) {
      document.addEventListener("mousedown", handleClickOutside);
    } else {
      document.removeEventListener("mousedown", handleClickOutside);
    }
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [showPopup]);

  return (
    <div className="signup-container" ref={popupRef}>
      <button className="signup-button" onClick={() => setShowPopup(!showPopup)}>
        {labels.signup}
      </button>

      {showPopup && (
        <div className="signup-popup">
          <label className="signup-label">{labels.fullName}</label>
          <input type="text" className="signup-input" placeholder={labels.fullName} />

          <label className="signup-label">{labels.email}</label>
          <input type="email" className="signup-input" placeholder={labels.email} />

          <label className="signup-label">{labels.password}</label>
          <input type="password" className="signup-input" placeholder={labels.password} />

          <button className="signup-submit">{labels.signupButton}</button>
        </div>
      )}
    </div>
  );
};

export default Signup;
