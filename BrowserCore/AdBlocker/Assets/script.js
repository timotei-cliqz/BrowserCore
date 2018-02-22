console.log("script injected");
(function(){
 var messageHandler = window.webkit.messageHandlers.focusTrackingProtection;
 var oldLog = console.log;
 console.log = function(message) {
    messageHandler.postMessage({ msg: message });
    oldLog.apply(console, arguments);
 };
 var oldInfo = console.info;
 console.info = function(message) {
    messageHandler.postMessage({ msg: message });
    oldInfo.apply(console, arguments);
 };
 var oldWarn = console.warn;
 console.warn = function(message) {
    messageHandler.postMessage({ msg: message });
    oldWarn.apply(console, arguments);
 };
 })();

