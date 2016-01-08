nock = require('nock')
mocks = require('./helpers/mocks')
MessagesCtrl = include("src/messagesCtrl")

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
ctrl = null
notification = null
queueServiceMock = null

describe "MessagesCtrl", ->
  beforeEach ->
    queueServiceMock = mocks.createQueueService message
    ctrl = MessagesCtrl queueServiceMock, baseApi

  describe "when process message", ->
    beforeEach ->
      req = nock baseApi
      .get message.resource
      .reply 200, [ id: 0 ]

      notification = mocks.expectNotification
        success: true
        statusCode: 200

      ctrl.processMessage queue

    it "should get the message from storage", ->
      queueServiceMock.shouldGetMessages queue

    it "should send message request to base api", ->
      req.done()

    describe "and request response success", ->

      it "should delete the message from storage", ->
        queueServiceMock.shouldDeleteMessage queue

      it "should notify to NotificationsApi", ->
        notification.done()

    describe "and request response fail", ->
      beforeEach ->
        nock.cleanAll()

        errorMessage = JSON.stringify error: "Resource doesnt exist"

        nock baseApi
        .get message.resource
        .reply 404, errorMessage

        notification = mocks.expectNotification
          success: false
          statusCode: 404
          message: errorMessage

        ctrl.processMessage queue

      it "should notify to NotificationsApi", ->
        notification.done()

      it "should move to poison queue", ->
        queueServiceMock.shouldCreateMessage queue + "-poison", message
        queueServiceMock.shouldDeleteMessage queue
