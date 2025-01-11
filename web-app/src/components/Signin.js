// Signin.js
import React from 'react';

const Signin = ({ onCancel }) => {
  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-lg font-semibold text-center">Sign In</h2>
      <input
        type="text"
        placeholder="Email"
        className="border border-gray-300 rounded p-2"
      />
      <input
        type="password"
        placeholder="Password"
        className="border border-gray-300 rounded p-2"
      />
      <div className="flex justify-between items-center">
        <button className="bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600">
          Submit
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

export default Signin;
