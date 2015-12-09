notificationsApiUrl = "http://notifications-api-mock.net"
process.env.NotificationsApiUrl = notificationsApiUrl
process.env.MaxProcessMessageCount = 3

require("should")
include = require("include")
simple = require('simple-mock')
nock = require('nock')

baseApi = "http://base-url.com/api"
queue = "massiveoperations"
message =
  method: "GET"
  resource: "/resource"
  headers:
    "Content-Type": "application/json"
    Job: "0"

queueServiceMock =
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


ctrl = include("src/messagesCtrl") queueServiceMock, baseApi
req = null
notification = null

describe "MessagesCtrl", ->

  describe "when process message", ->
    beforeEach ->
      req = nock baseApi
      .get message.resource
      .reply 200, [ id: 0 ]

      notification = nock notificationsApiUrl
      .post "/jobs/#{message.headers.Job}/operations",
        success: true
        statusCode: 200
      .reply 200

      ctrl.processMessage queue

    it "should get the message from storage", ->
      queueServiceMock.getMessagesAsync.called.should.be.true

    it "should send message request to base api", ->
      req.done()

    describe "and request response success", ->

      it "should delete the message from storage", ->
        queueServiceMock.deleteMessageAsync.called.should.be.true

      it "should notify to NotificationsApi", ->
        notification.done()

    describe "and request response fail", ->
      beforeEach ->
        nock.cleanAll()

        errorMessage = JSON.stringify error: "Resource doesnt exist"

        nock baseApi
        .get message.resource
        .reply 404, errorMessage

        notification = nock notificationsApiUrl
        .post "/jobs/#{message.headers.Job}/operations",
          success: false
          statusCode: 404
          message: errorMessage
        .reply 200

        ctrl.processMessage queue

      it "should notify to NotificationsApi", ->
        notification.done()

  it "should finish with error when fail processing message", (done) ->
    nock.cleanAll()

    ctrl
    .processMessage queue
    .then done
    .catch -> done()
