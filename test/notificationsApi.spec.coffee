nock = require('nock')
mocks = require('./helpers/mocks')
NotificationsApi = include("src/notificationsApi")
notificationsApi = new NotificationsApi mocks.jobId, mocks.accessToken, 0

successRes =
  statusCode: 201
failureRes =
  statusCode: 500
  body: message: "Error"

describe "NotificationsApi", ->

  it "on success should send the operation with success = true", (done) ->
    req = mocks.expectNotification
      success: true
      statusCode: successRes.statusCode

    notificationsApi.success successRes, ->
      req.done()
      done()

  it "on failure should send the operation with success = false and response body", (done) ->
    req = mocks.expectNotification
      success: false
      statusCode: failureRes.statusCode
      message: failureRes.body

    notificationsApi.fail failureRes, ->
      req.done()
      done()

  it "should retry when fails sending the operation", (done) ->
    body =
      success: false
      statusCode: failureRes.statusCode
      message: failureRes.body

    notification = nock "http://notifications-api-mock.net"
      .post "/jobs/0/operations", body
      .twice()
      .reply 500

    req = nock "http://notifications-api-mock.net"
      .post "/jobs/0/operations", body
      .reply 200

    notificationsApi.fail failureRes, (err, response)->
      notification.done()
      req.done()
      response.attempts.should.eql 3
      done()

