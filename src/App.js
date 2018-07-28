import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';

class App extends Component {
  render() {
    return (
      <div className="App">
        <header className="App-header">
          <img src={logo} className="App-logo" alt="logo" />
          <h1 className="App-title">Welcome to React</h1>
        </header>
        <p className="App-intro">
          To get started, edit <code>src/App.js</code> and save to reload.
        </p>
        <p>Card Number: <input type="text" name="cardNumber" /></p>
        <p>
          <select name="cardExpirationMonth">
            <option value="1" selected="selected">01</option>
            <option value="2">02</option>
            <option value="3">03</option>
                      〜 中略 〜
            <option value="12">12</option>
          </select>
          <select name="cardExpirationYear">
            <option value="2015" selected="selected">2015</option>
            <option value="2016">2016</option>
            <option value="2017">2017</option>
                      〜 中略 〜
            <option value="2035">2035</option>
        </select>
        </p>
      </div>
    );
  }
}

export default App;
