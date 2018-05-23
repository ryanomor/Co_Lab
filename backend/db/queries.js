const db = require("./index");
const authHelpers = require("../auth/helpers");
const passport = require("../auth/local");

const getAllUsers = (req, res, next) => {
  db
    .any("select * from users")
    .then(function(data) {
      res.status(200).json({
        status: "success",
        data: data,
        message: "Retrieved ALL users"
      });
    })
    .catch(function(err) {
      return next(err);
    });
}

const checkUser = (req, res, next) => {
  db.any("SELECT username FROM users WHERE username=${username}", {username: req.body.username})
    .then(users => {
        if(users.length === 0) {
          next();
          return;
        }
        res.status(400).json({ message: "user already exists" });
        return;
    })
    .catch((err) => {
      console.log("err:", err);
      res.status(500).json({ message: "error creating user" });
    });
};

function createUser(req, res, next) {
  const hash = authHelpers.createHash(req.body.password);
  console.log("create user hash:", hash);
  db
    .one(
      `INSERT INTO users (email, username, password_digest, firstname, lastname) 
      VALUES ($1, $2, $3, $4, $5)
      RETURNING user_ID`, // Will insert a new row in users table and return the id of new user
      [ req.body.email, req.body.username, hash, req.body.firstname, req.body.lastname ]
      // { email: req.body.email, username: req.body.username, password: hash, user_bio: req.body.user_bio }
    )
    .then((user) => {
      res.send({user_id: user.user_id , message: `created user: ${req.body.username}`});
    })
    .catch(err => {
      console.log(err);
      res.status(500).send({ message: "error creating user" });
  });
}

function logoutUser(req, res, next) {
  req.logout();
  res.status(200).send("log out success");
};

function getSingleUser(req, res, next) {
  db
    .any("SELECT * FROM users WHERE username = ${username}", req.user)
    .then(function(data) {
      res.status(200).json({
        status: "success",
        data: data,
        message: "Fetched one user"
      });
    })
    .catch(function(err) {
      return next(err);
    });
}

const updateSingleUser = (req, res, next) => {
  db
    .none(
      "update users set username = ${newName} where username = ${username}",
      req.body
    )
    .then(function(data) {
      res.status(200).json({
        status: "success",
        message: "Changed one user"
      });
    })
    .catch(function(err) {
      return next(err);
    });
};

const getUserProfile = (req, res, next) => {
  db 
    .any(`SELECT users.username, users.user_bio, images.img_url 
          FROM users 
          JOIN images ON images.user_id=$1
          WHERE users.user_id=$1`,
         [ req.user.user_id ])
    .then(function(data){
      res.status(200).json({
        status: "success",
        data: data,
        message: "Fetched current user's profile"
      });
    })
    .catch(function(err) {
      return next(err);
    });
}

module.exports = {
  checkUser,
  createUser,
  logoutUser,
  getSingleUser,
  getAllUsers,
  updateSingleUser,
};
