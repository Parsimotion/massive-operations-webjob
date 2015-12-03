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
      body:
        success: true
        statusCode: response.statusCode

    requestAsync requestMessage
    .then (res) -> console.log res
    .catch (err) -> console.error err

  fail: (jobId, response) ->
    requestMessage =
      method: "POST"
      url: baseApi + "/jobs/#{jobId}/operations"
      headers:
        'content-type': 'application/json'
      body:
        success: false
        statusCode: response.statusCode
        message: response

    requestAsync requestMessage
    .then (res) -> console.log res
    .catch (err) -> console.error err
