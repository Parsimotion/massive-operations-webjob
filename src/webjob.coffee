azure = require("azure-storage")
Promise = require("bluebird")
Promise.promisifyAll azure
_ = require("lodash")
MessageFlowBalancer = require("./messageFlowBalancer")
MessageProcessor = require("./messageProcessor")

module.exports =

  # storageName, storageKey, queue, baseUrl, numOfMessages, visibilityTimeout, maxDequeueCount, concurrency
  run: (options) ->
    _.defaults options,
      numOfMessages: 16
      visibilityTimeout: 90
      maxDequeueCount: 5
      concurrency: 50    

    { storageName, storageKey, queue, baseUrl } = options
    
    queueService = azure.createQueueService storageName, storageKey
    processor = new MessageProcessor(baseUrl)

    @createQueueIfNotExists queueService, storageName, storageKey, queue
    .then ->
      new MessageFlowBalancer(queueService, processor, options).run()


  createQueueIfNotExists: (queueService, storageName, storageKey, queue) ->
    queueService.createQueueIfNotExistsAsync(queue).then ->
      queueService.createQueueIfNotExistsAsync(queue + '-poison')