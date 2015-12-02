Promise = require("bluebird")
requestAsync = Promise.promisify require("request")

errorExit = (err) ->
  console.log err
  process.exit 1

doneExit = ->
  console.log "PROCESS DONE"
  process.exit 0

module.exports = (queueService, baseUrl) ->
  processMessage: (queue) ->
    queueService
      .getMessagesAsync queue
      .then (messages) ->
        message = messages[0][0]
        # console.log message
        messageText = JSON.parse message.messagetext
        requestMessage =
          method: messageText.method
          url: baseUrl + messageText.resource
          headers: messageText.headers
          body: messageText.body

        requestAsync requestMessage
        .then (response) ->
          queueService.deleteMessageAsync queue, message.messageid, message.popreceipt
          .then -> doneExit()
          .catch (err) ->
            console.log "DELETE ERROR"
            errorExit err

      .catch (err) ->
        console.log "PROCESS ERROR"
        errorExit err
