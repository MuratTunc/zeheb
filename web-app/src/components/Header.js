// Header.js
import React, { useState } from 'react';
import 'bootstrap/dist/css/bootstrap.min.css'; // Bootstrap, if you're also using it
import Signin from './Signin';
import Signup from './Signup';

const Header = () => {
  const [showSignin, setShowSignin] = useState(false);
  const [showSignup, setShowSignup] = useState(false);

  const handleClosePopup = () => {
    setShowSignin(false);
    setShowSignup(false);
  };

  return (
    <>
      <header className="bg-gray-800 text-white p-4 fixed top-0 w-full flex justify-between items-center shadow-lg z-50">
        <h1 className="text-xl font-bold">ZEHEP</h1>
        <div className="space-x-4">
          <button
            className="bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600"
            onClick={() => setShowSignin(true)}
          >
            SIGN IN
          </button>
          <button
            className="bg-green-500 text-white py-2 px-4 rounded hover:bg-green-600"
            onClick={() => setShowSignup(true)}
          >
            SIGN UP
          </button>
        </div>
      </header>

      {showSignin && (
      <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex justify-center items-center">
         <div className="bg-white rounded-lg p-4 pt-2 shadow-lg"> {/* Adjusted padding */}
            <Signin onCancel={handleClosePopup} />
         </div>
      </div>
      )}

     {showSignup && (
     <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex justify-center items-center">
        <div className="bg-white rounded-lg p-4 pt-2 shadow-lg"> {/* Adjusted padding */}
           <Signup onCancel={handleClosePopup} />
        </div>
      </div>
)}
    </>
  );
};

export default Header;