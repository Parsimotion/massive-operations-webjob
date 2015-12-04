Promise = require("bluebird")
requestAsync = Promise.promisify require("request")

baseApi = process.env.NotificationsApiUrl

module.exports =
  success: (jobId, response) ->
    @_makeRequest jobId,
      success: true
      statusCode: response.statusCode

  fail: (jobId, response) ->
    console.log response.body
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
    # .then (res) -> console.log res
