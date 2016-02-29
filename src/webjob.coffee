azureQueue = require("azure-queue-node")
Promise = require("bluebird")
_ = require("lodash")
MessageFlowBalancer = require("./messageFlowBalancer")
MessageProcessor = require("./messageProcessor")
JobMessageProcessor = require("./jobMessageProcessor")

module.exports =

  # storageName, storageKey, queue, jobsQueue, baseUrl, maxMessages, visibilityTimeout, maxDequeueCount, concurrency
  run: (options) ->
    _.defaults options,
      maxMessages: 16
      visibilityTimeout: 90
      maxDequeueCount: 5
      concurrency: 50

    { storageName, storageKey, queue, baseUrl, jobsQueue } = options

    queueClient = azureQueue.setDefaultClient
      accountUrl: "http://#{storageName}.queue.core.windows.net/",
      accountName: storageName,
      accountKey: storageKey

    Processor = if jobsQueue then JobMessageProcessor else MessageProcessor
    processor = new Processor(baseUrl)

    @createQueueIfNotExists storageName, storageKey, queue
    .then ->
      new MessageFlowBalancer(queueClient, processor, options).run()


  createQueueIfNotExists: (storageName, storageKey, queue) ->
    azureStorage = require("azure-storage")
    queueService = Promise.promisifyAll azureStorage.createQueueService storageName, storageKey
    queueService.createQueueIfNotExistsAsync(queue).then ->
      queueService.createQueueIfNotExistsAsync(queue + '-poison')


