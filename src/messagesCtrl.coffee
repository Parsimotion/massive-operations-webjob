Promise = require("bluebird")
requestAsync = Promise.promisify require("request")

module.exports = (queueService, baseUrl) ->
  processMessage: (queue) ->
    queueService
      .getMessagesAsync queue
      .then (messages) ->
        message = messages[0][0]
        console.log message
        messageText = JSON.parse message.messagetext
        requestMessage =
          method: messageText.method
          url: baseUrl + messageText.resource
          headers: messageText.headers
          body: messageText.body

        requestAsync requestMessage
        .then (response) ->
          queueService.deleteMessageAsync queue, message.messageid, message.popreceipt

      .catch (err) ->
        console.error "PROCESS FAIL"
        throw err
