import React, { useState, useEffect, useRef } from "react";
import "./Signin.css";

const Signin = ({ labels }) => {
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
    <div className="signin-container" ref={popupRef}>
      <button className="signin-button" onClick={() => setShowPopup(!showPopup)}>
        {labels.signin}
      </button>

      {showPopup && (
        <div className="signin-popup">
          <label className="signin-label">{labels.email}</label>
          <input type="email" className="signin-input" placeholder={labels.email} />

          <label className="signin-label">{labels.password}</label>
          <input type="password" className="signin-input" placeholder={labels.password} />

          <button className="signin-submit">{labels.login}</button>
        </div>
      )}
    </div>
  );
};

export default Signin;
