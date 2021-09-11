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

db.mdsConfig.insertMany([
  {
    v: 1,
    external: {
      identityUrl: "https://127.0.0.1:8081",
      nsUrl: "http://127.0.0.1:8082",
      qsUrl: "http://127.0.0.1:8083",
      fsUrl: "http://127.0.0.1:8084",
      sfUrl: "http://127.0.0.1:8085",
      smUrl: "http://127.0.0.1:8086",
      allowSelfSignCert: true
    },
    internal: {
      identityUrl: "https://mds-identity:8888",
      nsUrl: "http://mds-ns:8888",
      qsUrl: "http://mds-qs:8888",
      fsUrl: "http://mds-fs:8888",
      sfUrl: "http://mds-sf:8888",
      smUrl: "http://mds-sm:8888",
      allowSelfSignCert: true
    }
  }
]);
