_ = require('lodash')
config = require('./config')
Promise = require("bluebird")
requestAsync = Promise.promisify require("request")
notificationsApi = require('./notificationsApi')

maxProcessCount = config.maxProcessMessageCount

module.exports = (queueService, baseUrl) ->
  processMessage: (queue) ->
    queueService
      .getMessagesAsync queue
      .then (messages) =>
        message = messages[0][0]
        return if not message?

        console.log message
        messageText = JSON.parse message.messagetext

        jobId = messageText.headers.job
        accessToken = messageText.headers.authorization

        requestMessage = @_createRequest messageText
        requestAsync requestMessage
        .then ([response]) =>
          if isSuccess response.statusCode
            @_requestSuccess queue, message, response, jobId, accessToken
          else
            @_requestFail queue, message, response, jobId, accessToken

  _createRequest: (messageText) ->
    method: messageText.method
    url: baseUrl + messageText.resource
    headers: messageText.headers
    body: messageText.body

  _requestSuccess: (queue, message, response, jobId, accessToken) ->
    console.log "SUCCESS"
    Promise.props
      notification: notificationsApi.success jobId, response, accessToken
      deleteMessage: @_deleteMessage queue, message

  _requestFail: (queue, message, response, jobId, accessToken) ->
    console.log "FAILURE"
    if _.parseInt(message.dequeuecount) >= maxProcessCount
      notification = notificationsApi.fail jobId, response, accessToken
      moveMessage = queueService
      .createMessageAsync queue + "-poison", message.messagetext
      .then => @_deleteMessage queue, message

      Promise.props {notification, moveMessage}

  _deleteMessage: (queue, message) ->
    queueService.deleteMessageAsync queue, message.messageid, message.popreceipt
