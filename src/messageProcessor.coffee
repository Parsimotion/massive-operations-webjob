NotificationsApi = require('./notificationsApi')
rp = require('request-promise')
_ = require("lodash")

module.exports =

class MessageProcessor
  constructor: (@baseUrl) ->
  
  process: (req, lastTry) =>
    jobId = req.headers.job
    accessToken = req.headers.authorization
    notificationsApi = new NotificationsApi jobId, accessToken

    options = @_createRequestOptions req
    console.log options

    rp(options)
    .then (response) ->
      notificationsApi.success response
    .catch (response) ->
      throw response.error if !lastTry
      notificationsApi.fail response
      .then ->
        throw response.error
      

  _createRequestOptions: (req) ->
    method: req.method
    uri: @baseUrl + req.resource
    headers: _.omit req.headers, "host"
    body: req.body
    resolveWithFullResponse: true