import React, { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import Signin from "./Signin"; // Import Signin component
import Signup from "./Signup"; // Import Signup component
import UserPersonalInfo from "./UserPersonalInfo"; // Import UserPersonalInfo component

const Header = () => {
  const [isAuthenticated, setAuth] = useState(false); // Tracks authentication success
  const [fullName, setFullName] = useState(""); // Stores user’s full name

  const labels = {
    signin: "Sign in",
    email: "Email",
    password: "Password",
    login: "Log in",
    signup: "Sign up",
    fullName: "Full Name",
    signupButton: "Sign Up",
    verifyButton: "Verify",
  };

  return (
    <nav className="navbar navbar-dark bg-secondary p-3">
      <div className="container-fluid">
        <a className="navbar-brand">My App</a>
        <div className="d-flex">
          {isAuthenticated ? (
            <UserPersonalInfo fullName={fullName} setAuth={setAuth} setFullName={setFullName} />
          ) : (
            <>
              <Signin labels={labels} setAuth={setAuth} setFullName={setFullName} />
              <Signup labels={labels} setAuth={setAuth} setFullName={setFullName} />
            </>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Header;
