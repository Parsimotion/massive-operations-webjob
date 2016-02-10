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
      @_getMessages 0, (messages) =>
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

    @messageProcessor.process req, lastTry, (err) =>
      return callback() if err? and !lastTry
      return @_moveToPoison(err, message, callback) if err?
      @_deleteMessage message, callback

  _moveToPoison: (err, message, callback) =>
    console.log err
    @queueService.createMessage @queue + "-poison", message.messagetext, =>
      @_deleteMessage message, callback

  _deleteMessage: (message, callback) =>
    @queueService.deleteMessage @queue, message.messageid, message.popreceipt, callback

  _getMessages: (timeout, callback) =>
    retrieve = =>
      options = _.pick @options, ['numOfMessages', 'visibilityTimeout']
      @queueService.getMessages @queue, options, (err, messages) =>
        return @_getMessages(@_nextTimout(timeout), callback) if err? or messages.length == 0
        console.log "got #{messages.length}"
        callback messages

    setTimeout retrieve, timeout

  _nextTimout: (timeout) ->
    return 1000 if timeout is 0
    Math.min(timeout * 2, 8000)