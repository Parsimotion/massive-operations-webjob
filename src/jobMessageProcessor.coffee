NotificationsApi = require('./notificationsApi')
MessageProcessor = require('./messageProcessor')
rp = require('request-promise')

module.exports =

class JobMessageProcessor extends  MessageProcessor
  process: (req, lastTry) =>
    jobId = req.headers.job
    accessToken = req.headers.authorization
    notificationsApi = new NotificationsApi jobId, accessToken

    @_sendRequest(req)
    .then (response) ->
      notificationsApi.success response
    .catch (response) ->
      throw response.error if !lastTry
      notificationsApi.fail response
      .then ->
        throw response.error