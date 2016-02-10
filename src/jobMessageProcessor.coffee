NotificationsApi = require('./notificationsApi')
MessageProcessor = require('./messageProcessor')
request = require('request')

module.exports =

class JobMessageProcessor extends  MessageProcessor
  process: (req, lastTry, callback) =>
    jobId = req.headers.job
    accessToken = req.headers.authorization
    notificationsApi = new NotificationsApi jobId, accessToken

    options = @_createRequestOptions req
    request options, (err, response, body) ->
      if err or response.statusCode >= 400
        return callback(err or body) if !lastTry
        return notificationsApi.fail response, (e) -> callback e or err or body
      notificationsApi.success response, callback