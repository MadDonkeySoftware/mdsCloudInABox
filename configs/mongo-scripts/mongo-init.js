db = db.getSiblingDB('mds-identity');

db.createUser({
  user: "dbuser",
  pwd: "pwd4mongo",
  roles: [{
    role: "readWrite",
    db: "mds-identity"
  }]
});

db.mdsCounter.insertMany([
  { key: 'account', value: 1000 }
]);
