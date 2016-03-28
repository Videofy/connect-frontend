var spy = require("eye-spy");
var spawn = require('child_process').spawn;

function build (done) {
  console.log("Building client.")
  builder = spawn("npm", ["run", "build"], { stdio: "inherit" });
  builder.on("close", function (code) {
    done();
  });
}

spy(".", /^(src|components)\/.*\.(json|coffee|js|jade|less|css)$/, function (path, done) {
  build(done);
});
