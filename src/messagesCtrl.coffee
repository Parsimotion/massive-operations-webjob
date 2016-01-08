_ = require('lodash')
config = require('./config')
Promise = require("bluebird")
requestAsync = Promise.promisify require("request")
NotificationsApi = require('./notificationsApi')

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
        notificationsApi = new NotificationsApi jobId, accessToken

        requestMessage = @_createRequest messageText
        requestAsync requestMessage
        .then ([response]) =>
          if isSuccess response.statusCode
            @_requestSuccess queue, message, response, notificationsApi
          else
            @_requestFail queue, message, response, notificationsApi

  _createRequest: (messageText) ->
    method: messageText.method
    url: baseUrl + messageText.resource
    headers: messageText.headers
    body: messageText.body

  _requestSuccess: (queue, message, response, notificationsApi) ->
    console.log "SUCCESS"
    Promise.props
      notification: notificationsApi.success response
      deleteMessage: @_deleteMessage queue, message

  _requestFail: (queue, message, response, notificationsApi) ->
    console.log "FAILURE"
    if _.parseInt(message.dequeuecount) >= maxProcessCount
      notification = notificationsApi.fail response
      moveMessage = queueService
      .createMessageAsync queue + "-poison", message.messagetext
      .then => @_deleteMessage queue, message

      Promise.props {notification, moveMessage}

  _deleteMessage: (queue, message) ->
    queueService.deleteMessageAsync queue, message.messageid, message.popreceipt
