config = require('./config')
Promise = require("bluebird")
requestAsync = Promise.promisify require("request")

baseApi = config.notificationsApiUrl

module.exports =
  success: (jobId, response) ->
    @_makeRequest jobId,
      success: true
      statusCode: response.statusCode

  fail: (jobId, response) ->
    @_makeRequest jobId,
      success: false
      statusCode: response.statusCode
      message: response.body

  _makeRequest: (jobId, body) ->
    requestMessage =
      method: "POST"
      url: baseApi + "/jobs/#{jobId}/operations"
      headers:
        'content-type': 'application/json'
      body:
        JSON.stringify body

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
