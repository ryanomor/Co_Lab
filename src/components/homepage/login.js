import React from "react";
import { Link } from "react-router-dom";

const Login = ({ handleChange, handleLogin }) => {
  return (
    <div>
      <h2>Log in</h2>
      <form onSubmit={handleLogin}>
        <input
          type="text"
          placeholder="Username"
          name="loginUsername"
          onChange={handleChange}
        />
        <input
          type="password"
          placeholder="Password"
          name="loginPassword"
          onChange={handleChange}
        />
        <span>
          <Link to="/signup">Sign up</Link> {" "}
          <input type="submit" value="login" />
        </span>
      </form>
    </div>
  );
};

export default Login;