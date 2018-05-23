import React, { Component } from "react";
import { Route, Switch } from "react-router-dom";
import { Redirect } from "react-router";
import { connect } from "react-redux";
import Login from "./login";
import Signup from "./signup";
import axios from "axios";
import "./homepage.css";

class Homepage extends Component {
  constructor() {
    super();

    this.state = {
      // for login
      loginUsername: "",
      loginPassword: "",

      // for signup
      firstname: "",
      lastname: "",
      username: "",
      email: "",
      email_confirm: "",
      password: "",

      // for errors in input
      errorMessage: ""
    };
  }

  handleChange = e => {
    this.setState({
      [e.target.name]: e.target.value,
      errorMessage: ""
    });
  };

  handleLogin = e => {
    e.preventDefault();
    const { loginUsername, loginPassword } = this.state;
    console.log("log in");
    return;
    axios
      .post(`/user/login`, {
        username: loginUsername,
        password: loginPassword
      })
      .then(res => {
        console.log(res.data);
        this.login(res.data);
        console.log(this.props.Profile);
      })
      .catch(err => {
        console.log(err.response);
        if (err.response && err.response.data) {
          this.setState({
            loginUsername: "",
            loginPassword: "",
            message: err.response.data.message
          });
        } else {
          this.setState({
            loginUsername: "",
            loginPassword: "",
            message: "Error signing up"
          });
        }
      });
  };

  validateEmail = email => {
    return email.match(/^([\w.%+-]+)@([\w-]+\.)+([\w]{2,})$/i);
  };

  handleSignUp = e => {
    e.preventDefault();
    const {
      firstname,
      lastname,
      username,
      password,
      email,
      email_confirm
    } = this.state;
    const isValid = this.validateEmail(email);
    console.log("sign up");
    return;

    if (password.length < 6) {
      this.setState({
        errorMessage: "Password must be 6 characters or more"
      });
      return;
    } else if (!isValid) {
      this.setState({
        errorMessage: "Please enter a valid email"
      });
    } else if (email != email_confirm) {
      this.setState({
        errorMessage: "Emails do not match"
      });
      return;
    }

    const newUser = {
      email,
      firstname,
      lastname,
      username
    };

    axios
      .post(`/user/new`, newUser)
      .then(res => {
        console.log(res.data);
        this.login(res.data);
        console.log(this.props.Profile);
      })
      .catch(err => {
        console.log(err.response);
        if (err.response && err.response.data) {
          this.setState({
            message: err.response.data.message
          });
        } else {
          this.setState({
            message: "Error signing up"
          });
        }
      });
  };

  login = user => {
    const { dispatch } = this.props;
    dispatch({ type: "LOGIN", user });
  };

  renderLogin = () => {
    return (
      <Login 
        handleChange={this.handleChange} 
        handleLogin={this.handleLogin} 
        errorMessage={this.errorMessage}
      />
    );
  };

  renderSignup = () => {
    return (
      <Signup
        handleChange={this.handleChange}
        handleSignUp={this.handleSignUp}
        errorMessage={this.errorMessage}
      />
    );
  };

  render() {
    const { handleChange, handleLogin, handleSignUp } = this.state;
    const { user } = this.props;
    console.log(this.props);
    if (user.user.id) {
      return <Redirect to="/user" />;
    }

    return (
      <div>
        <h1>Homepage</h1>
        <div className="form">
          <h2>Co_Lab</h2>
          <Switch>
            <Route path="/signup" render={this.renderSignup} />
            <Route path="/" render={this.renderLogin} />
          </Switch>
        </div>
      </div>
    );
  }
}

export default connect(state => state)(Homepage);
