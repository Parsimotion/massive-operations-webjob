require("should")
nock = require('nock')
mock = require('mock-require')
simple = require('simple-mock')
simple.Promise = require("bluebird")

notificationsApiUrl = "http://notifications-api-mock.net"

mock "../../src/config",
  notificationsApiUrl: notificationsApiUrl
  maxProcessMessageCount: 3


module.exports =
  expectNotification: (jobId, notification) ->
    resource = "/jobs/#{jobId}/operations"

    nock notificationsApiUrl
    .post resource, notification
    .reply 200

  createQueueService: (message) ->
    getMessagesAsync: simple.stub().resolveWith [
      [
        messageid: 'c93c90eb-40ee-4ced-8b95-dff8055fe66e'
        insertiontime: 'Wed, 02 Dec 2015 18:32:29 GMT'
        expirationtime: 'Wed, 09 Dec 2015 18:32:29 GMT'
        dequeuecount: '100'
        popreceipt: 'AgAAAAMAAAAAAAAAA/2QGTAt0QE='
        timenextvisible: 'Wed, 02 Dec 2015 18:34:38 GMT'
        messagetext: JSON.stringify message
      ]
    ]

    createMessageAsync: simple.stub().resolveWith
      isSuccessful: true
      statusCode: 201

    deleteMessageAsync: simple.stub().resolveWith
      isSuccessful: true
      statusCode: 204

    shouldGetMessages: (queue) ->
      @getMessagesAsync.lastCall.arg.should.be.eql queue

    shouldCreateMessage: (queue, message) ->
      @createMessageAsync.lastCall.args[0].should.be.eql queue
      @createMessageAsync.lastCall.args[1].should.be.eql JSON.stringify message

    shouldDeleteMessage: (queue) ->
      @deleteMessageAsync.lastCall.arg.should.be.eql queue
