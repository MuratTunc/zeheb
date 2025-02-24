// UserPersonalInfo.js
import React, { useState, useEffect } from "react";
import "./UserPersonalInfo.css"; // Ensure the correct CSS is imported

const UserPersonalInfo = ({ fullName, setAuth, setFullName }) => {
  const [selectedOption, setSelectedOption] = useState(""); // State for dropdown selection
  const [isPopupVisible, setPopupVisible] = useState(false); // State for toggling the popup visibility

  const togglePopup = () => {
    setPopupVisible(!isPopupVisible);
  };

  // Close popup if clicked outside
  const handleClickOutside = (e) => {
    if (e.target.closest(".user-personal-info") === null) {
      setPopupVisible(false);
    }
  };

  const handleLogout = () => {
    setAuth(false); // Logout by setting auth to false
    setFullName(""); // Clear the full name when logged out
  };

  useEffect(() => {
    // Adding event listener for clicks outside to close the popup
    document.addEventListener("click", handleClickOutside);

    return () => {
      document.removeEventListener("click", handleClickOutside);
    };
  }, []);

  return (
    <div className="user-personal-info">
      <h2 onClick={togglePopup} style={{ cursor: "pointer" }}>
        Welcome, {fullName} ⏷
      </h2>

      {isPopupVisible && (
        <div className="popup-menu">
          <button className="popup-button">Settings</button>
          <button className="popup-button" onClick={handleLogout}>Logout</button>
        </div>
      )}
    </div>
  );
};

export default UserPersonalInfo;
