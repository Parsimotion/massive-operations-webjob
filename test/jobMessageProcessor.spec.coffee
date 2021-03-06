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

describe "JobMessageProcessor", ->
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

    describe "and request response fail with with a code between 400 and 499", ->
      errorMessage = error: "Resource doesnt exist"

      beforeEach ->
        nock baseApi
        .get message.resource
        .reply 404, errorMessage       

      it "should call the callback with retry: false as parameter", (done) ->
        processor.process message, false, (err) ->
          err.retry.should.eql false
          done()

      it "should notify the failure to the NotificationsApi", (done) ->
        failNotification = mocks.expectNotification
          success: false
          statusCode: 404
          message: JSON.stringify errorMessage

        processor.process message, false, ->
          failNotification.done()
          done()

    describe "and request response fail with with a code 500 and over", ->
      errorMessage = error: "Unhandled error"
      failNotification = null

      beforeEach ->
        nock baseApi
        .get message.resource
        .reply 500, errorMessage       

        failNotification = mocks.expectNotification
          success: false
          statusCode: 500
          message: JSON.stringify errorMessage

      describe "and it ain't the last try", ->
        error = null
        beforeEach (done) ->
          processor.process message, false, (err) ->
            error = err
            done()

        it "should not notify the failure to the NotificationsApi", ->
          failNotification.isDone().should.eql false

        it "should call the callback with retry: true as parameter", ->
          error.retry.should.eql true

      describe "and it is the last try", ->
        error = null
        beforeEach (done) ->
          processor.process message, true, (err) ->
            error = err
            done()

        it "should notify the failure to the NotificationsApi", ->
          failNotification.isDone().should.eql true

        it "should call the callback with retry: false as parameter", ->
          error.retry.should.eql false

    describe "and request response fail with with a code 409 and it ain't the last try", ->
      errorMessage = error: "Conflict please retry"
      failNotification = null
      error = null

      beforeEach (done) ->
        nock baseApi
        .get message.resource
        .reply 409, errorMessage

        failNotification = mocks.expectNotification
          success: false
          statusCode: 409
          message: JSON.stringify errorMessage

        processor.process message, false, (err) ->
          error = err
          done()

      it "should not notify the failure to the NotificationsApi", ->
        failNotification.isDone().should.eql false

      it "should call the callback with retry: true as parameter", ->
        error.retry.should.eql true
