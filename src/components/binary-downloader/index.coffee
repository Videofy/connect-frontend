arrayBufferToBase64 = (buffer)->
  bytes = new Uint8Array(buffer)
  binary = ''
  for i in [0...bytes.byteLength]
    binary += String.fromCharCode(bytes[i])

  return window.btoa(binary)

module.exports =
  downloadBinaryToBase64: (url, done)->
    done ?= ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', url, true)
    xhr.responseType = 'arraybuffer'

    xhr.onload = (e)->
      return done(Error('Error in response')) unless @status is 200
      done(null, arrayBufferToBase64(@response))

    xhr.onerror = (e)->
      done(Error(@statusText))

    xhr.send()
