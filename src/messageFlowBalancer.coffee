_ = require("lodash")
MessageProcessor = require("./messageProcessor")
async = require('async')
Promise = require("bluebird")

module.exports =

class MessageFlowBalancer

  constructor: (@queueService, @messageProcessor, @options) ->
    { @queue, @baseUrl, @numOfMessages, @maxDequeueCount, @concurrency } = options

  run: =>
    worker = @_getWorker()
    q = async.queue worker, @concurrency
    gettingMessages = null

    getMessages = =>
      gettingMessages = true
      console.log "reordering due to internal queue length is #{q.length()}..."
      @_getMessages().then (messages) =>
        gettingMessages = false
        messages.forEach (message) =>
          startTime = new Date()
          q.push message, (err) =>
            elapsedTime = parseInt (new Date() - startTime) / 1000
            console.log "message #{message.messageid} processed successfully in #{elapsedTime}s"
            reorderpoint = Math.ceil @numOfMessages / 2 
            getMessages() if q.length() <= reorderpoint and gettingMessages is false

    getMessages()  

  _getWorker: => (message, callback) =>
    lastTry = _.parseInt(message.dequeuecount) >= @maxDequeueCount
    req = JSON.parse message.messagetext

    @messageProcessor.process(req, lastTry)
    .then () =>
      @_deleteMessage(message).finally -> callback()
    .catch (err) =>
      return callback() if !lastTry
      console.log err
      @_moveToPoison(message).finally -> callback()

  _moveToPoison: (message) =>
    @queueService
    .createMessageAsync(@queue + "-poison", message.messagetext).then () =>
      @_deleteMessage message

  _deleteMessage: (message) =>
    @queueService.deleteMessageAsync @queue, message.messageid, message.popreceipt

  _getMessages: (timeout = 0) =>
    new Promise (resolve) ->
      setTimeout resolve, timeout
    .then () =>
      options = _.pick @options, ['numOfMessages', 'visibilityTimeout']
      @queueService
      .getMessagesAsync @queue, options
      .then ([messages]) =>
        return @_getMessages(@_nextTimout timeout) if messages.length == 0
        console.log "got #{messages.length}"
        messages

  _nextTimout: (timeout) ->
    return 1000 if timeout is 0
    Math.min(timeout * 2, 8000)