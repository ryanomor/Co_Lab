const express = require('express');
const router = express.Router();
const { loginRequired } = require("../auth/helpers");
const passport = require("../auth/local");
const db = require("../db/queries");

router.post("/new", db.checkUser, db.createUser);

router.post("/login", passport.authenticate("local"), (req, res) => {
  console.log(req);
  const userObj = {
    firstname: req.user.firstname,
    lastname: req.user.lastname,  
    id: req.user.user_id,
    username: req.user.username,
  }

  res.status(200).json({
    user: userObj,
    message: `${req.user.username} is logged in`
  });
  return;
}); 

router.get("/", loginRequired, db.getSingleUser);
router.get("/logout", loginRequired, db.logoutUser);

module.exports = router;
