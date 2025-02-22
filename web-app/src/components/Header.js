import React from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import Signin from "./Signin"; // Import Signin component

const Header = () => {
  const labels = {
    signin: "Sign in",
    email: "Email",
    password: "Password",
    login: "Log in",
  };

  return (
    <nav className="navbar navbar-dark bg-secondary p-3">
      <div className="container-fluid">
        <a className="navbar-brand" href="#">My App</a>
        <div className="d-flex">
          <Signin labels={labels} /> {/* Signin Component */}
          <a className="btn btn-light" href="#">Signup</a>
        </div>
      </div>
    </nav>
  );
};

export default Header;
