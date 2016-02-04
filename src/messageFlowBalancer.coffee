_ = require("lodash")
MessageProcessor = require("./messageProcessor")
async = require('async')

module.exports =

class MessageFlowBalancer

  constructor: (@queueService, @messageProcessor, @options) ->
    { @queue, @baseUrl, @numOfMessages, @concurrency } = options

  run: =>
    worker = @_getWorker()
    q = async.queue worker, @concurrency

    getMessages = =>
      @_getMessages().then (messages) =>
        messages.forEach (message) =>
          q.push message, ->
            reorderpoint = Math.ceil @numOfMessages / 2 
            getMessages() if q.length() <= reorderpoint

    getMessages()  

  _getWorker: => (message, callback) =>
    lastTry = _.parseInt(message.dequeuecount) >= maxDequeueCount
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

  _getMessages: =>
    options = _.pick @options, ['numOfMessages', 'visibilityTimeout']
    @queueService
    .getMessagesAsync @queue, options
    .then ([messages]) ->