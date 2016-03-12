_ = require("lodash")
request = require 'request'

module.exports =

class MessageProcessor
  constructor: (@baseUrl) ->

  process: (req, lastTry, callback) =>
    options = @_createRequestOptions req
    request options, (err, response) =>
      return callback(retry: !lastTry) if err? or @_retryableCode response
      callback()

  _createRequestOptions: (req) ->
    method: req.method
    uri: @baseUrl + req.resource
    headers: _.omit req.headers, "host"
    body: req.body
    resolveWithFullResponse: true

  _retryableCode: (response) ->
    code = response?.statusCode
    code == 409 or code >= 500