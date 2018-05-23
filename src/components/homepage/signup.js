import React from "react";
import { Link } from "react-router-dom";

const Submit = ({ username, password, handleChange, handleSignUp }) => {
  return (
    <div>
      <h2>Sign Up</h2>
      <form onSubmit={handleSignUp}>
        <input
          type="text"
          name="firstname"
          onChange={handleChange}
          placeholder="First name"
        />
        <input
          type="text"
          name="lastname"
          onChange={handleChange}
          placeholder="Last name"
        />
        <input
          type="text"
          name="username"
          onChange={handleChange}
          placeholder="Username"
        />
        <input
          type="text"
          name="email"
          onChange={handleChange}
          placeholder="Email"
        />
        <input
          type="text"
          name="email_confirm"
          onChange={handleChange}
          placeholder="Re-Enter Email"
        />
        <input
          type="password"
          name="password"
          onChange={handleChange}
          placeholder="Password"
        />
        <span>
          <Link to="/">Already have an account?</Link>{" "}
          <input type="submit" value="signup" />
        </span>
      </form>
    </div>
  );
};

export default Submit;
