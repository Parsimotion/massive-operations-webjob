# Webjob para leer y procesar massive operations del azure storage

```javascript
options = {
  storageName,
  storageKey,
  baseUrl, //API base URL
  queue, //Queue Name
  numOfMessages, //BatchSize for every time messages are requested from de queue
  visibilityTimeout, //Time in seconds for a message to reapear if it wasn't deleted
  maxDequeueCount, //Max number of times a message is tried to be processed
  concurrency, //Number of messages processed in parallel
}

var job = require('massive-operations-webjob');
job.run(options);
```
