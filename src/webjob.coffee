global.isSuccess = (code) ->
  /2../.test code

azure = require("azure-storage")
Promise = require("bluebird")
Promise.promisifyAll azure
controller = require("./messagesCtrl")

module.exports =
  create: (storageName, storageKey, baseUrl) ->
    queueService = azure.createQueueService storageName, storageKey
    controller queueService, baseUrl
