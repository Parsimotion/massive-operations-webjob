require("should")
nock = require('nock')
mock = require('mock-require')
simple = require('simple-mock')
simple.Promise = require("bluebird")

notificationsApiUrl = "http://notifications-api-mock.net"

mock "../../src/config",
  notificationsApiUrl: notificationsApiUrl
  maxProcessMessageCount: 3


module.exports =
  jobId: 0
  accessToken: "Bearer 1234567890"

  expectNotification: (notification, done = ->) ->
    resource = "/jobs/#{@jobId}/operations"
    headers =
      'authorization': @accessToken

    nock notificationsApiUrl, reqheaders: headers
    .post resource, notification
    .reply 200, ->
      setTimeout done, 0
      ""

  nockGetMessages: (messages, done = ->) ->
    queueMessages = messages.map (message) ->
      """
        <QueueMessage>
          <MessageId>#{ message.id }</MessageId>
          <InsertionTime>Thu, 03 Jul 2014 08:54:30 GMT</InsertionTime>
          <ExpirationTime>Thu, 10 Jul 2014 08:54:30 GMT</ExpirationTime>
          <DequeueCount>#{ message.dequeueCount }</DequeueCount>
          <PopReceipt>sK52prNk0QgBAAAA</PopReceipt>
          <TimeNextVisible>Thu, 03 Jul 2014 08:55:19 GMT</TimeNextVisible>
          <MessageText>#{ JSON.stringify(message.messageText) }</MessageText>
        </QueueMessage>
      """
    response = ->
      setTimeout done, 0
      """
      <?xml version="1.0" encoding="utf-8"?>
      <QueueMessagesList>
      #{ queueMessages }
      </QueueMessagesList>
      """

    nock("http://storage.queue.core.windows.net")
    .get("/jobs/messages")
    .once()
    .reply 200, response, { 'cache-control': 'no-cache', 'transfer-encoding': 'chunked', 'content-type': 'application/xml', server: 'Windows-Azure-Queue/1.0 Microsoft-HTTPAPI/2.0', 'x-ms-request-id': '51e22df0-d77a-4c04-a5f9-0a8a0f885ca4', 'x-ms-version': '2014-02-14', date: 'Thu, 03 Jul 2014 08:54:49 GMT' }


  nockDeleteMessage: (messageId, done = ->) ->
    response = ->
      setTimeout done, 0
      ""

    nock("http://storage.queue.core.windows.net")
    .delete("/jobs/messages/#{messageId}?popreceipt=sK52prNk0QgBAAAA")
    .reply 204, response, { 'content-length': '0', server: 'Windows-Azure-Queue/1.0 Microsoft-HTTPAPI/2.0', 'x-ms-request-id': 'f53bc13a-c6b7-45af-b4d8-6b79e1587af6', 'x-ms-version': '2014-02-14', date: 'Fri, 04 Jul 2014 07:26:32 GMT' }

  nockUpdateMessage: (messageId, done = ->) ->
    response = ->
      setTimeout done, 0
      ""

    nock("http://storage.queue.core.windows.net")
    .put("/jobs/messages/#{messageId}?popreceipt=sK52prNk0QgBAAAA&visibilitytimeout=1")
    .reply 204, response, { 'content-length': '0', server: 'Windows-Azure-Queue/1.0 Microsoft-HTTPAPI/2.0', 'x-ms-request-id': 'e1a50159-d947-4f43-af48-d944cf6a9661', 'x-ms-version': '2014-02-14', 'x-ms-popreceipt': 'DKtBR2tl0QgBAAAA', 'x-ms-time-next-visible': 'Fri, 04 Jul 2014 06:49:46 GMT', date: 'Fri, 04 Jul 2014 06:39:46 GMT' }

  createQueueService: (message) ->
    getMessagesAsync: simple.stub().resolveWith [
      [
        messageid: 'c93c90eb-40ee-4ced-8b95-dff8055fe66e'
        insertiontime: 'Wed, 02 Dec 2015 18:32:29 GMT'
        expirationtime: 'Wed, 09 Dec 2015 18:32:29 GMT'
        dequeuecount: '100'
        popreceipt: 'AgAAAAMAAAAAAAAAA/2QGTAt0QE='
        timenextvisible: 'Wed, 02 Dec 2015 18:34:38 GMT'
        messagetext: JSON.stringify message
      ]
    ]

    createMessageAsync: simple.stub().resolveWith
      isSuccessful: true
      statusCode: 201

    deleteMessageAsync: simple.stub().resolveWith
      isSuccessful: true
      statusCode: 204

    shouldGetMessages: (queue) ->
      @getMessagesAsync.lastCall.arg.should.be.eql queue

    shouldCreateMessage: (queue, message) ->
      @createMessageAsync.lastCall.args[0].should.be.eql queue
      @createMessageAsync.lastCall.args[1].should.be.eql JSON.stringify message

    shouldDeleteMessage: (queue) ->
      @deleteMessageAsync.lastCall.arg.should.be.eql queue
