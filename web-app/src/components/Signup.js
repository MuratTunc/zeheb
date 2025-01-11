// Signup.js
import React from 'react';

const Signup = ({ onCancel }) => {
  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-lg font-semibold text-center">Sign Up</h2>
      <input
        type="text"
        placeholder="Username"
        className="border border-gray-300 rounded p-2"
      />
      <input
        type="email"
        placeholder="Email"
        className="border border-gray-300 rounded p-2"
      />
      <input
        type="password"
        placeholder="Password"
        className="border border-gray-300 rounded p-2"
      />
      <div className="flex justify-between items-center">
        <button className="bg-green-500 text-white py-2 px-4 rounded hover:bg-green-600">
          Register
        </button>
        <button
          onClick={onCancel}
          className="bg-red-500 text-white py-2 px-4 rounded hover:bg-red-600"
        >
          Cancel
        </button>
      </div>
    </div>
  );
};

export default Signup;
