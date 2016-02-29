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
    request options, (err, response) ->
      if err or response?.statusCode >= 400
        return callback(err or response) if response?.statusCode >= 500 and !lastTry
        return notificationsApi.fail response, -> callback err or response
      notificationsApi.success response, callback