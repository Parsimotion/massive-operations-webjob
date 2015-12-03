require("should")
include = require("include")
Promise = require("Bluebird")
simple = require('simple-mock')
nock = require('nock')

baseApi = "http://base-url.com/api"
queue = "massiveoperations"
message =
  method: "GET"
  resource: "/resource"
  headers: "Content-Type": "application/json"

queueServiceMock =
  getMessagesAsync: simple.stub().resolveWith [
    [
      messageid: 'c93c90eb-40ee-4ced-8b95-dff8055fe66e'
      insertiontime: 'Wed, 02 Dec 2015 18:32:29 GMT'
      expirationtime: 'Wed, 09 Dec 2015 18:32:29 GMT'
      dequeuecount: '4'
      popreceipt: 'AgAAAAMAAAAAAAAAA/2QGTAt0QE='
      timenextvisible: 'Wed, 02 Dec 2015 18:34:38 GMT'
      messagetext: JSON.stringify message
    ]
  ]

  deleteMessageAsync: simple.stub().resolveWith
    isSuccessful: true
    statusCode: 204


ctrl = include("src/messagesCtrl") queueServiceMock, baseApi
req = null

describe "MessagesCtrl", ->
  beforeEach ->
    req = nock baseApi
    .get message.resource
    .reply 200, [ id: 0 ]

  describe "when process message", ->
    beforeEach ->
      ctrl.processMessage queue

    it "get the message from storage", ->
      queueServiceMock.getMessagesAsync.called.should.be.true

    it "send message request to base api", ->
      req.done()

    it "delete the message from storage", ->
      queueServiceMock.deleteMessageAsync.called.should.be.true
