azureQueue = require("azure-queue-node")
Promise = require("bluebird")
_ = require("lodash")
chokidar = require("chokidar")
path = require('path')
MessageFlowBalancer = require("./messageFlowBalancer")
MessageProcessor = require("./messageProcessor")
JobMessageProcessor = require("./jobMessageProcessor")

module.exports =

  # storageName, storageKey, queue, jobsQueue, baseUrl, maxMessages, visibilityTimeout, maxDequeueCount, concurrency
  run: (options) ->
    _.defaults options,
      maxMessages: 16
      visibilityTimeout: 300 #5min
      maxDequeueCount: 5
      concurrency: 50

    { storageName, storageKey, queue, baseUrl, jobsQueue } = options

    queueClient = azureQueue.setDefaultClient
      accountUrl: "http://#{storageName}.queue.core.windows.net/",
      accountName: storageName,
      accountKey: storageKey

    Processor = if jobsQueue then JobMessageProcessor else MessageProcessor
    processor = new Processor(baseUrl)
    messageFlowBalancer = new MessageFlowBalancer queueClient, processor, options

    @createQueueIfNotExists storageName, storageKey, queue
    .then () =>
      messageFlowBalancer.run()
      @watchForGracefulShutdown messageFlowBalancer


  createQueueIfNotExists: (storageName, storageKey, queue) ->
    azureStorage = require("azure-storage")
    queueService = Promise.promisifyAll azureStorage.createQueueService storageName, storageKey
    queueService.createQueueIfNotExistsAsync(queue).then ->
      queueService.createQueueIfNotExistsAsync(queue + '-poison')

  watchForGracefulShutdown: (messageFlowBalancer) ->
    fullPathToExpectedFile = process.env.WEBJOBS_SHUTDOWN_FILE
    folderToWatch = path.dirname fullPathToExpectedFile
    expectedFilename = path.basename fullPathToExpectedFile
    chokidar.watch(folderToWatch, { persistent: true, depth: 0 })
    .on 'add', (fullPath) ->
      filename = path.basename fullPath
      messageFlowBalancer.kill() if filename is expectedFilename
