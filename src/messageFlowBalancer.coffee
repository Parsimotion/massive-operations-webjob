_ = require("lodash")
MessageProcessor = require("./messageProcessor")
async = require('async')
Promise = require("bluebird")

module.exports =

class MessageFlowBalancer

  constructor: (@queueClient, @messageProcessor, @options) ->
    { @queue, @baseUrl, @maxMessages, @maxDequeueCount, @concurrency } = options

  run: =>
    console.log "running..."
    worker = @_getWorker()
    q = async.queue worker, @concurrency
    gettingMessages = null

    getMessages = =>
      gettingMessages = true
      @_getMessages 0, (messages) =>
        gettingMessages = false
        messages.forEach (message) =>
          q.push message, (err) =>
            reorderpoint = Math.ceil @maxMessages / 2 
            getMessages() if q.length() <= reorderpoint and gettingMessages is false

    getMessages()  

  _getWorker: => (message, callback) =>
    lastTry = _.parseInt(message.dequeueCount) >= @maxDequeueCount
    req = message.messageText
    console.log message

    @messageProcessor.process req, lastTry, (err) =>
      return callback() if err? and !lastTry
      return @_moveToPoison(err, message, callback) if err?
      @_deleteMessage message, callback

  _moveToPoison: (err, message, callback) =>
    @queueClient.createMessage @queue + "-poison", message.messageText, =>
      @_deleteMessage message, callback

  _deleteMessage: (message, callback) =>
    @queueClient.deleteMessage @queue, message.messageId, message.popReceipt, callback

  _getMessages: (timeout, callback) =>
    retrieve = =>
      options = _.pick(@options, ['maxMessages', 'visibilityTimeout'])
      @queueClient.getMessages @queue, options, (err, messages) =>
        return @_getMessages(@_nextTimout(timeout), callback) if err? or messages.length == 0
        callback messages

    setTimeout retrieve, timeout

  _nextTimout: (timeout) ->
    return 1000 if timeout is 0
    Math.min(timeout * 2, 8000)