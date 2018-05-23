import React from "react";
import { connect } from "react-redux";
import User from "../components/user/profile";

class UserContainer extends React.Component {
    // Use dipatch here to update profile info
  render() {
    console.log(this.props);
    return (
        <User store={this.props.user} />
    );
  }
}

export default connect(state => state)(UserContainer);