const bcrypt = require("bcryptjs");
const db = require("../db/index");

const loginRequired = (req, res, next) => {
    if (!req.user) {
        res.status(401)
           .json({status: "Please log in first"});
        return;
    };
    return next();
};

const createHash = (password) => {
    const salt = bcrypt.genSaltSync();
    const hash = bcrypt.hashSync(password, salt);
    return hash;
};

const comparePass = (userPass, databasePass) => {
    return bcrypt.compareSync(userPass, databasePass);
};

module.exports = {
    loginRequired,
    createHash,
    comparePass,
};