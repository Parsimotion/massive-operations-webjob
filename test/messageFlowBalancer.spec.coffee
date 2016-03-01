nock = require('nock')
mocks = require('./helpers/mocks')
JobMessageProcessor = include("src/jobMessageProcessor")
MessageFlowBalancer = include("src/messageFlowBalancer")
azureQueue = require("azure-queue-node")

message =
  method: "GET"
  resource: "/resource"
  headers:
    "content-type": "application/json"
    "job": mocks.jobId
    "authorization": mocks.accessToken

baseApi = "http://base-url.com/api"
storageName = "storage"
queueClient = azureQueue.setDefaultClient
  accountUrl: "http://#{storageName}.queue.core.windows.net/",
  accountName: storageName,
  accountKey: "maestruli"

errorMessage = error: "soyUnError"
MAX_DEQUEUE_COUNT = 5

processor = new JobMessageProcessor baseApi

messageFlowBalancer = new MessageFlowBalancer queueClient, processor, { queue: "jobs", maxDequeueCount: MAX_DEQUEUE_COUNT }

nockRequest = (resource, statusCode, body, done = ->) ->
  nock baseApi
  .get resource
  .reply statusCode, ->
    setTimeout done, 0
    body

describe "MessageFlowBalancer with a JobMessageProcessor", ->

  afterEach ->
    nock.cleanAll()

  describe "when run is called", ->
    it "should get the messages", ->
      getMessages = mocks.nockGetMessages [ ], ->
        getMessages.done()
      
      messageFlowBalancer.run()

    describe "and succeeding messages are retrieved from the queue", ->
      req = null
      notification = null
      deleteMessage = null

      beforeEach (done) ->
        req = nockRequest(message.resource, 200, [ id: 0 ])
        mocks.nockGetMessages([ { id: "soyUnId", messageText: message, dequeueCount: 1 } ])
        notification = mocks.expectNotification
          success: true
          statusCode: 200
        deleteMessage = mocks.nockDeleteMessage("soyUnId", done)

        messageFlowBalancer.run()

      it "should send the request on the message", ->
        req.done()

      it "should notify", ->
        notification.done()

      it "should delete the message", ->
        deleteMessage.done()

    describe "and failing messages of known exception are retrieved from the queue", ->
      notification = null
      deleteMessage = null
      putInPoison = null

      beforeEach (done) ->
        nockRequest(message.resource, 400, errorMessage)
        mocks.nockGetMessages([ { id: "soyUnId", messageText: message, dequeueCount: 1 } ])
        notification = mocks.expectNotification
          success: false
          statusCode: 400
          message: JSON.stringify errorMessage

        putInPoison = mocks.nockPutMessage(message)
        deleteMessage = mocks.nockDeleteMessage("soyUnId", done)

        messageFlowBalancer.run()

      it "should notify the failure", ->
        notification.done()

      it "should delete the message", ->
        deleteMessage.done()

      it "should put the message in the poison queue", ->
        putInPoison.done()

    describe "and failing messages of unknown exception are retrieved from the queue", ->
      notification = null
      deleteMessage = null
      updateMessage = null
      putInPoison = null

      describe "and the message's dequeueCount is smaller than the maximum allowed", ->

        beforeEach (done) ->
          nockRequest(message.resource, 500, errorMessage)
          mocks.nockGetMessages([ { id: "soyUnId", messageText: message, dequeueCount: 1 } ])

          notification = mocks.expectNotification
            success: false
            statusCode: 500
            message: JSON.stringify errorMessage

          putInPoison = mocks.nockPutMessage(message)
          deleteMessage = mocks.nockDeleteMessage("soyUnId")
          updateMessage = mocks.nockUpdateMessage("soyUnId", done)

          messageFlowBalancer.run()

        it "should not notify the failure", ->
          notification.isDone().should.eql false

        it "should not delete the message", ->
          deleteMessage.isDone().should.eql false

        it "should not put the message in the poison queue", ->
          putInPoison.isDone().should.eql false

        it "should update the message visibilitytimeout", ->
          updateMessage.done()

      describe "and the message's dequeueCount is the maximum allowed", ->

        beforeEach (done) ->
          nockRequest(message.resource, 500, errorMessage)
          mocks.nockGetMessages([ { id: "soyUnId", messageText: message, dequeueCount: MAX_DEQUEUE_COUNT } ])
          notification = mocks.expectNotification
            success: false
            statusCode: 500
            message: JSON.stringify errorMessage

          putInPoison = mocks.nockPutMessage(message)
          deleteMessage = mocks.nockDeleteMessage("soyUnId", done)

          updateMessage = mocks.nockUpdateMessage("soyUnId")

          messageFlowBalancer.run()

        it "should notify the failure", ->
          notification.done()

        it "should delete the message", ->
          deleteMessage.done()

        it "should not update the message visibilitytimeout", ->
          updateMessage.isDone().should.eql false

        it "should put the message in the poison queue", ->
          putInPoison.done()

    describe "and the request to the real api fails awfully", ->
      deleteMessage = null
      updateMessage = null
      notification = null
      putInPoison = null

      describe "and the message's dequeueCount is smaller than the maximum allowed", ->

        beforeEach (done) ->
          awfulMessage = { message: 'something awful happened', code: 'AWFUL_ERROR' }
          nock baseApi
          .get message.resource
          .replyWithError('')

          mocks.nockGetMessages([ { id: "soyUnId", messageText: message, dequeueCount: 1 } ])

          notification = mocks.expectNotification
            success: false
            statusCode: undefined
            message: JSON.stringify awfulMessage

          putInPoison = mocks.nockPutMessage(message)
          deleteMessage = mocks.nockDeleteMessage("soyUnId")
          updateMessage = mocks.nockUpdateMessage("soyUnId", done)

          messageFlowBalancer.run()

        it "should not notify the failure", ->
          notification.isDone().should.eql false

        it "should not delete the message", ->
          deleteMessage.isDone().should.eql false

        it "should not put the message in the poison queue", ->
          putInPoison.isDone().should.eql false

        it "should update the message visibilitytimeout", ->
          updateMessage.done()

      describe "and the message's dequeueCount is the maximum allowed", ->

        beforeEach (done) ->
          awfulMessage = { message: 'something awful happened', code: 'AWFUL_ERROR' }
          nock baseApi
          .get message.resource
          .replyWithError awfulMessage

          mocks.nockGetMessages([ { id: "soyUnId", messageText: message, dequeueCount: MAX_DEQUEUE_COUNT } ])

          notification = mocks.expectNotification
            success: false
            message: 'something awful happened'

          putInPoison = mocks.nockPutMessage(message)
          deleteMessage = mocks.nockDeleteMessage("soyUnId", done)
          updateMessage = mocks.nockUpdateMessage("soyUnId")

          messageFlowBalancer.run()

        it "should notify the failure", ->
          notification.done()

        it "should delete the message", ->
          deleteMessage.done()

        it "should not update the message visibilitytimeout", ->
          updateMessage.isDone().should.eql false

        it "should not put the message in the poison queue", ->
          putInPoison.done()
