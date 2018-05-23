var pgp = require("pg-promise")({});
var connectionString = "postgres://localhost/instagramcloneuserlist";
var db = pgp(connectionString);

module.exports = db;