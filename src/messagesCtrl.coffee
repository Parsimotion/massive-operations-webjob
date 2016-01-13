_ = require('lodash')
config = require('./config')
Promise = require("bluebird")
rp = require('request-promise')
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
        console.log "SENDING REQUEST"
        console.log requestMessage

        rp requestMessage
        .then (response) => @_requestSuccess queue, message, response, notificationsApi
        .catch (response) => @_requestFail queue, message, response, notificationsApi


  _createRequest: (messageText) ->
    method: messageText.method
    uri: baseUrl + messageText.resource
    headers: _.omit messageText.headers, "host"
    body: messageText.body
    resolveWithFullResponse: true

  _requestSuccess: (queue, message, response, notificationsApi) ->
    console.log "SUCCESS"
    console.log response.body

    Promise.props
      notification: notificationsApi.success response
      deleteMessage: @_deleteMessage queue, message

  _requestFail: (queue, message, response, notificationsApi) ->
    console.log "FAILURE"
    console.log response.error

    if _.parseInt(message.dequeuecount) >= maxProcessCount
      notification = notificationsApi.fail response
      moveMessage = queueService
      .createMessageAsync queue + "-poison", message.messagetext
      .then => @_deleteMessage queue, message

      Promise.props {notification, moveMessage}

  _deleteMessage: (queue, message) ->
    queueService.deleteMessageAsync queue, message.messageid, message.popreceipt
