import React, { Component } from 'react';
import Homepage from './components/homepage/homepage';
import UserContainer from './containers/userContainer';
import { Route, Switch } from 'react-router-dom';
import logo from './logo.svg';
import './App.css';

class App extends Component {
  render() {
    return (
      <div className='App'>
        <Switch>
          <Route path='/user' component={UserContainer} />
          <Route path='/' component={Homepage} />
        </Switch>
      </div>
    );
  }
}

export default App;
