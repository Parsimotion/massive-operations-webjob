mocks = require('./helpers/mocks')
NotificationsApi = include("src/notificationsApi")
notificationsApi = new NotificationsApi mocks.jobId, mocks.accessToken

successRes =
  statusCode: 201
failureRes =
  statusCode: 500
  error: "Error"

describe "NotificationsApi", ->

  it "on success should send the operation with success = true", ->
    req = mocks.expectNotification
      success: true
      statusCode: successRes.statusCode

    notificationsApi.success successRes, ->
      req.done()

  it "on failure should send the operation with success = false and response body", ->
    req = mocks.expectNotification
      success: false
      statusCode: failureRes.statusCode
      message: failureRes.error

    notificationsApi.fail failureRes, ->
      req.done()
