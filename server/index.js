var express  = require('express')
var isMobile = require('./is-mobile')

var started = Date.now()
var app = express()
app.use(express.static('public'))
app.set('view engine', 'jade')
app.set('views', './views')

app.get('/', function(req, res) {
  res.render('index', {
    endpoint: process.env.ENDPOINT || '',
    timestamp: started,
    isMobile: isMobile(req.headers['user-agent']),
    segmentKey: mkey(req)
  })
})

app.listen(process.env.PORT || 8080)

function mkey (req) {
  if (req.headers.dnt === 1 || process.env.NODE_ENV != 'production') {
    return ''
  }
  return process.env.SEGMENT || ''
}
