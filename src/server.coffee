azure = require("azure-storage")
Promise = require("bluebird")
Promise.promisifyAll azure
controller = require("./messagesCtrl")

module.exports = (storageName, storageKey, baseUrl) ->
  queueService = azure.createQueueService storageName, storageKey
  controller queueService, baseUrl
