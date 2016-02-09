rp = require('request-promise')
_ = require("lodash")

module.exports =

class MessageProcessor
  constructor: (@baseUrl) ->
  
  process: (req, lastTry) =>
    accessToken = req.headers.authorization
    options = @_createRequestOptions req

    rp(options)
    .catch (response) ->
      throw response.error
      
  _createRequestOptions: (req) ->
    method: req.method
    uri: @baseUrl + req.resource
    headers: _.omit req.headers, "host"
    body: req.body
    resolveWithFullResponse: true