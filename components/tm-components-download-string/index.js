module.exports = function downloadString ( filename, str, contentType ) {
  contentType = contentType || "text/plain";
  var a = document.createElement("a");
  a.download = filename;
  a.href = "data:" + contentType + 
    ";charset=utf-8," + 
    encodeURIComponent(str);
  a.click();
};
