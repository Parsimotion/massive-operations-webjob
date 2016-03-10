baseApi = require('./config').notificationsApiUrl
request = require('requestretry')

module.exports =
  class NotificationsApi
    constructor: (@jobId, @accessToken, @retryDelay = 1000) ->

    success: (response, callback) =>
      @_makeRequest {
        success: true
        statusCode: response.statusCode        
      }, callback

    fail: (error, callback) =>
      @_makeRequest {
        success: false
        statusCode: error.statusCode
        message: error.body or error.message
      }, callback

    _makeRequest: (body, callback) =>
      requestMessage =
        retryDelay: @retryDelay
        method: "POST"
        url: baseApi + "/jobs/#{@jobId}/operations"
        headers:
          'content-type': 'application/json'
          'Authorization': @accessToken
        body: body
        json: true
      request requestMessage, callback