class StreamingService {
    var config = {};
    var pushTopicConfig = {};
    var subscriptionRef;
    var pushTopics;
    var isInitialized = false;
    var retryTimes = 20;
    var timeoutInterval;
    const cometd_statuses = {
       CONNECTED : 'connected',         // State assumed when this BayeuxClient is connected to the Bayeux server
       CONNECTING : 'connecting',       // State assumed when the connect is being sent for the first time
       DISCONNECTED : 'disconnected',   // State assumed before the handshake and when the disconnect is completed
       DISCONNECTING : 'disconnecting', // State assumed when the disconnect is being sent
       HANDSHAKEN : 'handshaken',       // State assumed when the handshake is received, but before connecting
       HANDSHAKING : 'handshaking',     // State assumed when the handshake is being sent
       REHANDSHAKING : 'rehandshaking', // State assumed when a first handshake failed and the handshake is retried, or when the Bayeux server requests a re-handshake
       TERMINATING : 'terminating',     // State assumed when the disconnect is received but terminal actions must be performed
       UNCONNECTED : 'unconnected'      // State assumed after the handshake when the connection is broken
    }

    constructor(_config, _pushTopicConfig) {
        _initServiceConfiguration(_config, _pushTopicConfig);
    }

    var _initServiceConfiguration(_config, _pushTopicConfig) {
        if(_config) {
            config = _config;
        } else {
            _initDefaultConfig(config);
        }
        if(pushTopicConfig) {
            pushTopicConfig = _pushTopicConfig;
        } else {
            _initDefaultPushTopicConfig(pushTopicConfig);
        }
    }

    var _initDefaultConfig = (_config) => {
        _config.ns = '';
        _config.timeout = 0;
        _config.duration = 0;
        _config.sobjectAccessError = '';
        _config.readStreamAction = null;
    };

    var _initDefaultPushTopicConfig = (_config) => {
        _config.pushTopicName = '';
        _config.sobjectType = '';
        _config.query = '';
        _config.apiVersion = '46.0';
        _config.notifyCreate = false;
        _config.notifyUpdate = false;
        _config.notifyDelete = false;
        _config.notifyUndelete = false;
        _config.notifyForFields = 'All';
    };

    this.initService = () => {
        var query = 'SELECT Id, Name, Query, ApiVersion, IsActive, NotifyForFields, NotifyForOperations, '
                  + 'Description, NotifyForOperationCreate, NotifyForOperationUpdate, NotifyForOperationDelete, '
                  + 'NotifyForOperationUndelete FROM PushTopic WHERE Name = \'' + config.pushTopicName + '\'';
        pushTopics = sforce.connection.query(query, {
            onSuccess: function(response) {
                if(!isInitialized) {
                    _init();
                }
            },
            onFailure: function(response) {
                _errorOnAccessingSobject(response, 'PushTopic');
            }
        });
    };

    var _init = () => {
        if(readStreamAction && _initPushTopicSuccess()) {
            isInitialized = true;
            _initStreamingConnection();
        }
    };

    var _initPushTopicSuccess = () => {
        var success = true;
        try {
            if(!_pushTopicExists()) {
                success = _createPushTopicSuccess();
            }
        } catch(error) {
            _errorOnAccessingSobject(error, config.ns + config.sobjectType);
            success = false;
        }
        return success;
    };

    var _pushTopicExists = () => {
        var pushTopicExists = false;
        if(pushTopics) {
            var records = pushTopics.getArray('records');
            if(records.length > 0) {
                console.info('Push topic for ' + config.pushTopicName + ' already exists.');
                pushTopicExists = true;
            }
        }
        return pushTopicExists;
    };

    var _createPushTopicSuccess = () => {
        var pushTopic = _createNewRecord();
        return _insertNewRecordSuccess(pushTopic);
    };

    var _createNewRecord = () => {
        var pushTopic = new sforce.SObject('PushTopic');
        pushTopic.Name = pushTopicConfig.pushTopicName;
        pushTopic.Query = pushTopicConfig.query;
        pushTopic.ApiVersion = pushTopicConfig.apiVersion;
        pushTopic.NotifyForOperationCreate = pushTopicConfig.notifyCreate;
        pushTopic.NotifyForOperationUpdate = pushTopicConfig.notifyUpdate;
        pushTopic.NotifyForOperationDelete = pushTopicConfig.notifyDelete;
        pushTopic.NotifyForOperationUndelete = pushTopicConfig.notifyUndelete;
        pushTopic.NotifyForFields = pushTopicConfig.notifyForFields;
        return pushTopic;
    };

    var _insertNewRecordSuccess = (pushTopic) => {
        var success = true;
        try {
            var insertResult = sforce.connection.create([pushTopic]);
            if(insertResult[0].getBoolean('success')) {
                console.info(config.pushTopicName + ' PushTopic not found and a new one is created');
            } else {
                console.error('Problem creating ' + config.pushTopicName + ' PushTopic: ', insertResult[0]);
                _errorOnAccessingSobject(insertResult[0], 'PushTopic');
                success = false;
            }
        } catch(error) {
            _errorOnAccessingSobject(error, 'PushTopic');
            success = false;
        }
        return success;
    };

    var _errorOnAccessingSobject = (error, sobjectType) => {
        var msg = config.sobjectAccessError + (error.faultstring || error);
        msg = msg.replace('{SOBJECT}', sobjectType);
        console.warn(msg);
    };

    var _initStreamingConnection = () => {
        var status = $copado.cometd.getStatus();
        if(status !== cometd_statuses.CONNECTED) {
            var asyncConnect = new Promise(function(resolve, reject) {
                _connectToStreaming();
            });
        } else {
            _subscribeToStreaming();
        }
    };

    var _connectToStreaming = () => {
        _setRemainingRetryAttempts();
        setTimeout(function() {
            _handleCurrentConnectionStatus();
        }, 1000);
    };

    var _setRemainingRetryAttempts = () => {
        var status = $copado.cometd.getStatus();
        if(status == cometd_statuses.DISCONNECTED || status == cometd_statuses.UNCONNECTED) {
            if(retryTimes == 0) {
                return;
            }
            retryTimes--;
            console.info('[' + config.pushTopicName + '] connecting to streaming... retry attempts left: ' + retryTimes);
        }
    };

    var _handleCurrentConnectionStatus = () => {
        status = $copado.cometd.getStatus();
        console.log('[' + config.pushTopicName + '] status: ' + status);
        switch(status) {
            case cometd_statuses.CONNECTED:
                _subscribeToStreaming();
                break;
            case cometd_statuses.HANDSHAKING:
            case cometd_statuses.HANDSHAKEN:
            case cometd_statuses.CONNECTING:
            case cometd_statuses.REHANDSHAKING:
                _connectToStreaming();
                break;
            case cometd_statuses.DISCONNECTED:
            case cometd_statuses.UNCONNECTED:
                this.c = $copado.cometd.init({
                  url: window.location.protocol + '//' + window.location.hostname + '/cometd/37.0/',
                  requestHeaders: {
                    Authorization: 'OAuth ' + __sfdcSessionId
                  }
                });
                _connectToStreaming();
                break;
            default:
                break;
        }
    };

    var _subscribeToStreaming = () => {
        subscriptionRef = $copado.cometd.subscribe('/topic/' + config.pushTopicName, function(message) {
            _readStream(message);
        });
        if(config.duration) {
            _startIntervalTimer();
        }
    };

    var _startIntervalTimer = () => {
        setTimeout(function() {
            timeoutInterval = setInterval(_runCountdown, 1000);
        }, 10000);
        document.addEventListener('click', function() {
            config.timeout = config.duration;
        });
    };

    var _runCountdown = () => {
        _unsubscribeIfTimeIsOut();
        setTimeout(function() {
            config.timeout -= 1000;
            _runCountdown();
        }, 1000);
    };

    var _unsubscribeIfTimeIsOut = () => {
        if(config.timeout == 0) {
            if(subscriptionRef) {
                $copado.cometd.unsubscribe(subscriptionRef);
                console.info('Subscription to ' + config.pushTopicName + ' ended.');
            }
            clearInterval(timeoutInterval);
            return;
        }
    };

    var _readStream = (message) => {
        console.info('Push message: ', message);
        if(message.channel == '/topic/' + config.pushTopicName) {
            readStreamAction && readStreamAction();
        }
    };

    this.disconnect = () => {
        $copado.cometd.disconnect();
    };
}


/*
var streaming = streaming || {};

((service) => {
    service.config = service.config || {};

    ((config) => {
        config.ns = '';
        config.timeout = 0;
        config.duration = 0;
        config.sobjectAccessError = '';
        config.pushTopicName = '';
        config.sobjectType = '';
        config.query = '';
        config.readStreamAction = {};
    })(service.config);

    var subscriptionRef;
    var hasPushTopic = false;
    var isInitialized = false;
    var retryTimes = 20;
    var timeoutInterval;
    const cometd_statuses = {
       CONNECTED : 'connected',         // State assumed when this BayeuxClient is connected to the Bayeux server
       CONNECTING : 'connecting',       // State assumed when the connect is being sent for the first time
       DISCONNECTED : 'disconnected',   // State assumed before the handshake and when the disconnect is completed
       DISCONNECTING : 'disconnecting', // State assumed when the disconnect is being sent
       HANDSHAKEN : 'handshaken',       // State assumed when the handshake is received, but before connecting
       HANDSHAKING : 'handshaking',     // State assumed when the handshake is being sent
       REHANDSHAKING : 'rehandshaking', // State assumed when a first handshake failed and the handshake is retried, or when the Bayeux server requests a re-handshake
       TERMINATING : 'terminating',     // State assumed when the disconnect is received but terminal actions must be performed
       UNCONNECTED : 'unconnected'      // State assumed after the handshake when the connection is broken
    }

    var _errorOnAccessingSobject = (e, sobjectType) => {
        var msg = service.config.sobjectAccessError + (e.faultstring || e);
        msg = msg.replace('{SOBJECT}', sobjectType);
        console.warn(msg);
    };

    service.initService = (pushTopicName, sobjectType, query, readStreamAction) => {
        service.config.pushTopicName = pushTopicName;
        service.config.sobjectType = sobjectType;
        service.config.query = query;
        service.config.readStreamAction = readStreamAction;
        var query = 'SELECT Id, Name FROM PushTopic limit 10';
        var result = sforce.connection.query(query, {
            onSuccess: function(res) {
                if(!isInitialized) {
                    _init();
                }
            },
            onFailure: function(res) {
                console.error(res);
            }
        });
    };

    var _init = () => {
        isInitialized = true;
        if(_initPushTopic()) {
            _initStreaming();
        }
    };

    var _initPushTopic = () => {
        try {
            _getPushTopics();
            if(!hasPushTopic) {
                _createPushTopic();
            }
            return true;
        } catch(e) {
            _errorOnAccessingSobject(e, service.config.ns + service.config.sobjectType);
            return false;
        }
    };

    var _initStreaming = () => {
        var status = $copado.cometd.getStatus();
        if(status !== cometd_statuses.CONNECTED) {
            var asyncConnect = new Promise(function(resolve, reject) {
                _connectToStreaming();
            });
        } else {
            _subscribeToStreaming();
        }
    };

    var _getPushTopics = () => {
        var pushTopicName = service.config.pushTopicName;
        try {
            var result = sforce.connection.query('SELECT Id, Name, Query, ApiVersion, IsActive, NotifyForFields, NotifyForOperations, '
                                                + 'Description, NotifyForOperationCreate, NotifyForOperationUpdate, NotifyForOperationDelete, '
                                                + 'NotifyForOperationUndelete FROM PushTopic WHERE Name = \'' + pushTopicName + '\'');
        } catch(e) {
            return _errorOnAccessingSobject(e,'PushTopic');
        }
        var records = result.getArray('records');
        if(records.length > 0) {
            for(var i = 0; i < records.length; i++) {
                if(records[i].Name == pushTopicName) {
                    console.info('Push topic for ' + pushTopicName + ' already exists.');
                    hasPushTopic = true;
                    break;
                }
            }
        }
    };

    var _createPushTopic = () => {
        var pushTopicName = service.config.pushTopicName;
        var pushTopic = new sforce.SObject('PushTopic');
        pushTopic.Name = pushTopicName;
        pushTopic.Query = service.config.query;
        pushTopic.ApiVersion = 46.0;
        pushTopic.NotifyForOperationCreate = true;
        pushTopic.NotifyForOperationUpdate = true;
        pushTopic.NotifyForOperationDelete = false;
        pushTopic.NotifyForOperationUndelete = false;
        pushTopic.NotifyForFields = 'Select';
        try {
            var result = sforce.connection.create([pushTopic]);
        } catch(e) {
            return _errorOnAccessingSobject(e, 'PushTopic');
        }
        if(result[0].getBoolean('success')) {
            console.info(pushTopicName + ' PushTopic not found and a new one is created');
        } else {
            console.error('Problem creating ' + pushTopicName + ' PushTopic: ', result[0]);
            return _errorOnAccessingSobject(result[0], 'PushTopic');
        }
    };

    var _connectToStreaming = () => {
        var status = $copado.cometd.getStatus();
        if(status == cometd_statuses.DISCONNECTED || status == cometd_statuses.UNCONNECTED) {
            if(retryTimes == 0) {
                return;
            }
            retryTimes--;
            console.info('[' + service.config.pushTopicName + '] connecting to streaming... retry attempts left: ' + retryTimes);
        }
        setTimeout(function() {
            status = $copado.cometd.getStatus();
            console.log('[' + service.config.pushTopicName + '] status: ' + status);
            switch(status) {
                case cometd_statuses.CONNECTED:
                    _subscribeToStreaming();
                    break;
                case cometd_statuses.HANDSHAKING:
                case cometd_statuses.HANDSHAKEN:
                case cometd_statuses.CONNECTING:
                case cometd_statuses.REHANDSHAKING:
                    _connectToStreaming();
                    break;
                case cometd_statuses.DISCONNECTED:
                case cometd_statuses.UNCONNECTED:
                    service.c = $copado.cometd.init({
                      url: window.location.protocol + '//' + window.location.hostname + '/cometd/37.0/',
                      requestHeaders: { Authorization: 'OAuth ' + __sfdcSessionId }
                    });
                    _connectToStreaming();
                    break;
                default:
                    break;
            }
        }, 1000);
    };

    var _subscribeToStreaming = () => {
        subscriptionRef = $copado.cometd.subscribe('/topic/' + service.config.pushTopicName, function(message) {
            _readStream(message);
        });
        if(service.config.duration) {
            _startTimer();
        }
    };

    var _startTimer = () => {
        setTimeout(function() {
            timeoutInterval = setInterval(_runCountdown(), 1000);
        }, 10000);
        document.addEventListener('click', function() {
            service.config.timeout = service.config.duration;
        });
    };

    var _runCountdown = () => {
        if(service.config.timeout == 0) {
            if(subscriptionRef) {
                $copado.cometd.unsubscribe(subscriptionRef);
                console.info('Subscription to ' + service.config.pushTopicName + ' ended.');
            }
            clearInterval(timeoutInterval);
            return;
        }
        setTimeout(function() {
            service.config.timeout -= 1000;
            _runCountdown();
        }, 1000);
    };

    var _readStream = (message) => {
        console.info('Push message: ', message);
        var statusMap = service.statusMap;
        if(message.channel == '/topic/' + service.config.pushTopicName) {
            readStreamAction && readStreamAction();
        }
    };

    service.disconnect = () => {
        $copado.cometd.disconnect();
    };
})(streaming);
*/