request = require("request")

module.exports = (queueService, baseUrl) ->
  proccessMessage: (queue) ->
    queueService
      .getMessagesAsync queue
      .then (messages) ->
        message = messages[0][0]
        messageText = JSON.parse message.messagetext
        console.log message
        requestMessage =
          method: messageText.method
          url: baseUrl + messageText.resource
          headers: messageText.headers
          body: messageText.body

        request requestMessage, (err, resp, body) ->
          throw err if err
          console.log body
          console.log resp

      .catch (err) ->
        console.log "ERROR"
        console.log err
