Promise = require("bluebird")
requestAsync = Promise.promisify require("request")

baseApi = process.env.NotificationsApiUrl

module.exports =
  success: (jobId, response) ->
    requestMessage =
      method: "POST"
      url: baseApi + "/jobs/#{jobId}/operations"
      headers:
        'content-type': 'application/json'
      body: JSON.stringify
        success: true
        statusCode: response.statusCode

    requestAsync requestMessage

  fail: (jobId, response) ->
    requestMessage =
      method: "POST"
      url: baseApi + "/jobs/#{jobId}/operations"
      headers:
        'content-type': 'application/json'
      body: JSON.stringify
        success: false
        statusCode: response.statusCode
        message: response

    requestAsync requestMessage
