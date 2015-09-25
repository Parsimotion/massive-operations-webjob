# Webjob para leer y procesar massive operations del azure storage

```javascript
var job = require('massive-operations-webjob');

job
.create(STORAGE_NAME, STORAGE_KEY, BASE_URL_API)
.processMessage(QUEUE_NAME);
```
