baseApi = require('./config').notificationsApiUrl
rp = require('request-promise')

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
        message: response.error

    _makeRequest: (body) =>
      requestMessage =
        method: "POST"
        uri: baseApi + "/jobs/#{@jobId}/operations"
        headers:
          'content-type': 'application/json'
          'Authorization': @accessToken
        body: body
        json: true

      rp requestMessage
      .catch (response) ->
        console.log
          status: response.statusCode
          body: response.error
