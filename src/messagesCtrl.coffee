Promise = require("bluebird")
requestAsync = Promise.promisify require("request")
notificationsApi = require('./notificationsApi')

maxProcessCount = process.env.MaxProcessMessageCount

isSuccess = (code) ->
  /2../.test code

module.exports = (queueService, baseUrl) ->
  processMessage: (queue) ->
    queueService
      .getMessagesAsync queue
      .then (messages) =>
        message = messages[0][0]
        # console.log message
        messageText = JSON.parse message.messagetext
        requestMessage =
          method: messageText.method
          url: baseUrl + messageText.resource
          headers: messageText.headers
          body: messageText.body

        requestAsync requestMessage
        .then (response) =>
          jobId = messageText.headers.Job
          if isSuccess response[0].statusCode
            @_requestSuccess queue, message, response[0], jobId
          else
            @_requestFail queue, message, response[0], jobId

  _requestSuccess: (queue, message, response, jobId) ->
    notificationsApi.success jobId, response
    queueService.deleteMessageAsync queue, message.messageid, message.popreceipt

  _requestFail: (queue, message, response, jobId) ->
    if Number.parseInt(message.dequeuecount) >= maxProcessCount
      notificationsApi.fail jobId, response
      queueService.createMessageAsync queue + "-poison", message.messagetext
      .then -> queueService.deleteMessageAsync queue, message.messageid, message.popreceipt
