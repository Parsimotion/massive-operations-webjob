notificationsApiUrl = "http://notifications-api-mock.net"
process.env.NotificationsApiUrl = notificationsApiUrl
nock = require('nock')
include = require("include")
notificationsApi = include("src/notificationsApi")

jobId = 0
resource = "/jobs/#{jobId}/operations"

successRes =
  statusCode: 201

failureRes =
  statusCode: 500
  body: "Error"

successReq = null
failureReq = null

describe "NotificationsApi", ->
  beforeEach ->
    nock.cleanAll()

    nocking = (body) ->
      nock notificationsApiUrl
      .post resource, body
      .reply 200

    successReq = nocking
      success: true
      statusCode: successRes.statusCode

    failureReq = nocking
      success: false
      statusCode: failureRes.statusCode
      message: failureRes

  it "on success should send the operation with success = true", ->
    notificationsApi.success jobId, successRes
    .then -> successReq.done()

  it "on failure should send the operation with success = false and the response", ->
    notificationsApi.fail jobId, failureRes
    .then -> failureReq.done()
