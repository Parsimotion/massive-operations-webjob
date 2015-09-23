azure = require("azure-storage")
Promise = require("bluebird")
Promise.promisifyAll azure
request = require("request")

module.exports = =>
  azure
    .createQueueService process.env.STORAGE_NAME, process.env.STORAGE_KEY
    .getMessagesAsync process.env.QUEUE_NAME
    .then (messages) ->
      message = JSON.parse messages[0][0].messagetext
      requestMessage =
        method: message.method
        url: "URL" + message.resource
        headers: message.headers
        body: message.body

      request requestMessage, (err, resp, body) ->
        console.log resp
        console.log body
        throw err if err


    .catch (err) ->
      console.log "ERROR"
      console.log err

