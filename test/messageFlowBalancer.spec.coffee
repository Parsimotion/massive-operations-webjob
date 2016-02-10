nock = require('nock')
mocks = require('./helpers/mocks')
JobMessageProcessor = include("src/jobMessageProcessor")

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
    processor = new JobMessageProcessor baseApi

  afterEach ->
    nock.cleanAll()

  describe "when process message", ->
    beforeEach (done) ->
      req = nock baseApi
      .get message.resource
      .reply 200, [ id: 0 ]

      notification = mocks.expectNotification
        success: true
        statusCode: 200

      processor.process message, false, done

    it "should send message request to base api", ->
      req.done()

    describe "and request response success", ->

      it "should notify to NotificationsApi", ->
        notification.done()

    describe "and request response fail", ->
      errorMessage = error: "Resource doesnt exist"

      beforeEach ->
        nock baseApi
        .get message.resource
        .reply 404, errorMessage       

      it "should call the callback with the error", (done) ->
        processor.process message, false, (err) ->
          err.should.eql JSON.stringify errorMessage
          done()

      it "should send notify the failure to the NotificationsApi if it is the last try", (done) ->
        failNotification = mocks.expectNotification
          success: false
          statusCode: 404
          message: JSON.stringify errorMessage

        processor.process message, true, ->
          failNotification.done()
          done()

