azure = require("azure-storage")
Promise = require("bluebird")
Promise.promisifyAll azure
_ = require("lodash")
MessageFlowBalancer = require("./messageFlowBalancer")
MessageProcessor = require("./messageProcessor")
JobMessageProcessor = require("./jobMessageProcessor")

module.exports =

  # storageName, storageKey, queue, jobQueue, baseUrl, numOfMessages, visibilityTimeout, maxDequeueCount, concurrency
  run: (options) ->
    _.defaults options,
      numOfMessages: 16
      visibilityTimeout: 90
      maxDequeueCount: 5
      concurrency: 50

    { storageName, storageKey, queue, baseUrl, jobQueue } = options
    
    queueService = azure.createQueueService storageName, storageKey
    Processor = if jobQueue then JobMessageProcessor else MessageProcessor
    processor = new Processor(baseUrl)

    @createQueueIfNotExists queueService, storageName, storageKey, queue
    .then ->
      new MessageFlowBalancer(queueService, processor, options).run()


  createQueueIfNotExists: (queueService, storageName, storageKey, queue) ->
    queueService.createQueueIfNotExistsAsync(queue).then ->
      queueService.createQueueIfNotExistsAsync(queue + '-poison')