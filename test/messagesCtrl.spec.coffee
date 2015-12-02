require("should")
include = require("include")
Promise = require("Bluebird")
nock = require('nock')

baseApi = "http://base-url.com/api"
message =
  method: "GET"
  resource: "/resource"
  headers: "Content-Type": "application/json"

queueServiceMock =
  getMessagesAsync: =>
    Promise.resolve [
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

  deleteMessageAsync: =>
    Promise.resolve
      isSuccessful: true
      statusCode: 204


ctrl = include("src/messagesCtrl") queueServiceMock, baseApi
req = null

describe "MessagesCtrl", ->

  beforeEach ->
    req = nock baseApi
    .get message.resource
    .reply 200, [ id: 0 ]

  it "send message request to base api", ->
    ctrl
    .processMessage("massiveoperations")
    .then -> req.done()
