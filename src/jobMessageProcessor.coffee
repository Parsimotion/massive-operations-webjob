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
        return callback(retry: true) if (err? or response?.statusCode >= 500) and !lastTry
        return notificationsApi.fail err or response, -> callback retry: false
      notificationsApi.success response, callback