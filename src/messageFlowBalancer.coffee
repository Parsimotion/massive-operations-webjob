_ = require("lodash")
MessageProcessor = require("./messageProcessor")
async = require('async')
Promise = require("bluebird")

module.exports =

class MessageFlowBalancer

  constructor: (@queueClient, @messageProcessor, @options) ->
    { @queue, @baseUrl, @maxMessages, @maxDequeueCount, @concurrency } = @options
    @killed = false
    @q = async.queue @_getWorker(), @concurrency

  kill: =>
    @killed = true
    @q.kill()

  run: =>
    console.log "running..."
    gettingMessages = null

    getMessages = =>
      gettingMessages = true
      @_getMessages 0, (messages) =>
        gettingMessages = false
        messages.forEach (message) =>
          @q.push message, (err) =>
            console.log "#{ @q.running() } tasks still running..." if @killed
            reorderpoint = Math.ceil @maxMessages / 2 
            getMessages() if @q.length() <= reorderpoint and gettingMessages is false and not @killed

    getMessages()

  _getWorker: => (message, callback) =>
    lastTry = _.parseInt(message.dequeueCount) >= @maxDequeueCount
    req = message.messageText

    @messageProcessor.process req, lastTry, (err) =>
      return @_deleteMessage message, callback if not err?
      return @_releaseMessage(message, callback) if err.retry
      @_moveToPoison(message, callback)

  _moveToPoison: (message, callback) =>
    @queueClient.putMessage @queue + "-poison", message.messageText, =>
      @_deleteMessage message, callback

  _deleteMessage: (message, callback) =>
    @queueClient.deleteMessage @queue, message.messageId, message.popReceipt, callback

  _releaseMessage: (message, callback) =>
    @queueClient.updateMessage @queue, message.messageId, message.popReceipt, 5, message.messageText, callback    

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