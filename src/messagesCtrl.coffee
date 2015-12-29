_ = require('lodash')
config = require('./config')
Promise = require("bluebird")
requestAsync = Promise.promisify require("request")
notificationsApi = require('./notificationsApi')

maxProcessCount = config.maxProcessMessageCount

isSuccess = (code) ->
  /2../.test code

module.exports = (queueService, baseUrl) ->
  processMessage: (queue) ->
    queueService
      .getMessagesAsync queue
      .then (messages) =>
        message = messages[0][0]
        console.log message
        messageText = JSON.parse message.messagetext
        requestMessage =
          method: messageText.method
          url: baseUrl + messageText.resource
          headers: messageText.headers
          body: messageText.body

        requestAsync requestMessage
        .then ([response]) =>
          jobId = messageText.headers.job
          if isSuccess response.statusCode
            @_requestSuccess queue, message, response, jobId
          else
            @_requestFail queue, message, response, jobId

  _requestSuccess: (queue, message, response, jobId) ->
    console.log "SUCCESS"
    Promise.props
      notification: notificationsApi.success jobId, response
      deleteMessage: @_deleteMessage queue, message

  _requestFail: (queue, message, response, jobId) ->
    console.log "FAILURE"
    if _.parseInt(message.dequeuecount) >= maxProcessCount
      notification = notificationsApi.fail jobId, response
      moveMessage = queueService
      .createMessageAsync queue + "-poison", message.messagetext
      .then => @_deleteMessage queue, message

      Promise.props {notification, moveMessage}

  _deleteMessage: (queue, message) ->
    queueService.deleteMessageAsync queue, message.messageid, message.popreceipt
