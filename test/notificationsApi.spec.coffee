mocks = require('./helpers/mocks')
notificationsApi = include("src/notificationsApi")

jobId = 0
successRes =
  statusCode: 201
failureRes =
  statusCode: 500
  body: "Error"

describe "NotificationsApi", ->

  it "on success should send the operation with success = true", ->
    req = mocks.expectNotification jobId,
      success: true
      statusCode: successRes.statusCode

    notificationsApi.success jobId, successRes, mocks.accessToken
    .then -> req.done()

  it "on failure should send the operation with success = false and response body", ->
    req = mocks.expectNotification jobId,
      success: false
      statusCode: failureRes.statusCode
      message: failureRes.body

    notificationsApi.fail jobId, failureRes, mocks.accessToken
    .then -> req.done()
