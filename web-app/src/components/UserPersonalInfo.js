import React, { useState } from "react";

const UserPersonalInfo = ({ fullName }) => {
  const [selectedOption, setSelectedOption] = useState(""); // State for dropdown selection

  return (
    <div className="user-personal-info">
      <h2>Welcome, {fullName}</h2>
      <label htmlFor="options">Choose an option:</label>
      <select 
        id="options" 
        value={selectedOption} 
        onChange={(e) => setSelectedOption(e.target.value)}>
        <option value="">Select...</option>
        <option value="option1">Option 1</option>
        <option value="option2">Option 2</option>
        <option value="option3">Option 3</option>
      </select>
    </div>
  );
};

export default UserPersonalInfo;
