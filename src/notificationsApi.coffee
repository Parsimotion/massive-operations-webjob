baseApi = require('./config').notificationsApiUrl
Promise = require("bluebird")
requestAsync = Promise.promisify require("request")

module.exports =
  class NotificationsApi
    constructor: (@jobId, @accessToken) ->

    success: (response) =>
      @_makeRequest
        success: true
        statusCode: response.statusCode

    fail: (response) =>
      @_makeRequest
        success: false
        statusCode: response.statusCode
        message: response.body

    _makeRequest: (body) =>
      requestMessage =
        method: "POST"
        url: baseApi + "/jobs/#{@jobId}/operations"
        headers:
          'content-type': 'application/json'
          'Authorization': @accessToken
        body:
          JSON.stringify body

      console.log "SENDING NOTIFICATION"
      console.log requestMessage

      requestAsync requestMessage
      .then ([response]) ->
        if isSuccess response.statusCode
          console.log "NOTIFICATION OK"
        else
          err =
            status: response.statusCode
            body: response.body
          throw err
      .catch (err) -> console.log err
