nock = require('nock')
mocks = require('./helpers/mocks')
MessageProcessor = include("src/messageProcessor")

queue = "massiveoperations"
baseApi = "http://base-url.com/api"
message =
  method: "GET"
  resource: "/resource"
  headers:
    "content-type": "application/json"
    "job": mocks.jobId
    "authorization": mocks.accessToken

req = null
processor = null
notification = null
queueServiceMock = null

describe "MessageProcessor", ->
  beforeEach ->
    queueServiceMock = mocks.createQueueService message
    processor = new MessageProcessor baseApi

  afterEach ->
    nock.cleanAll()

  describe "when process message", ->
    beforeEach ->
      req = nock baseApi
      .get message.resource
      .reply 200, [ id: 0 ]

      notification = mocks.expectNotification
        success: true
        statusCode: 200

      processor.process message, false

    it "should send message request to base api", ->
      req.done()

    describe "and request response success", ->

      it "should notify to NotificationsApi", ->
        notification.done()

    describe "and request response fail", ->
      errorMessage = JSON.stringify error: "Resource doesnt exist"

      beforeEach ->
        nock baseApi
        .get message.resource
        .reply 404, errorMessage       

      it "should reject the promise", (done) ->
        processor.process(message, false).catch (err) ->
          err.should.eql errorMessage
          done()

      it "should send notify the failure to the NotificationsApi if it is the last try", (done) ->
        failNotification = mocks.expectNotification
          success: false
          statusCode: 404
          message: errorMessage

        processor.process(message, true).catch ->
          failNotification.done()
          done()

