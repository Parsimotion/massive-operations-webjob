request = require("request")

errorExit = (err) ->
  console.log err
  process.exit 1

doneExit = ->
  process.exit 0

module.exports = (queueService, baseUrl) ->
  processMessage: (queue) ->
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

        request requestMessage, (err) ->
          throw err if err
          queueService.deleteMessageAsync(queueName, message.messageid, message.popreceipt)
          .then -> doneExit()
          .catch (err) ->
            console.log "DELETE ERROR"
            errorExit err

      .catch (err) ->
        console.log "PROCESS ERROR"
        errorExit err
