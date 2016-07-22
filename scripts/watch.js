var spy = require("eye-spy");
var spawn = require('child_process').spawn;

var server;

function start(done) {
  if (server) {
    console.log("Restarting server.");
    server.kill();
  }
  else {
    console.log("Starting server.");
  }

  server = spawn("node", ["server/index"], { 
    stdio: "inherit", 
    env: process.env 
  });

  if (done) setTimeout(done, 2000);
}

function build (done) {
  console.log("Building client.")
  builder = spawn("npm", ["run", "build"], { stdio: "inherit" });
  builder.on("close", function (code) {
    done();
  });
}

spy(".", /^src\/((?!client).)*\.coffee$/, function (path, done){
  start(done);
});

spy(".", /^(src\/components|components)\/.*\.(json|coffee|js|jade|less|css)$/, function (path, done) {
  build(done);
});

start();