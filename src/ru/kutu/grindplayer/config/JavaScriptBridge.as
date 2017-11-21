package ru.kutu.grindplayer.config {
	
    import com.adobe.images.JPGEncoder;
    import com.sociodox.utils.Base64;
    import flash.display.BitmapData;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.system.Security;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    import flash.events.TimerEvent;

    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import org.osmf.events.MediaPlayerCapabilityChangeEvent;
	import org.osmf.events.MetadataEvent;
	
	import ru.kutu.grind.config.JavaScriptBridgeBase;
    import ru.kutu.grind.config.PlayerConfiguration;
	import ru.kutu.grind.events.MediaElementChangeEvent;
	import ru.kutu.grindplayer.events.AdvertisementEvent;
	import ru.kutu.osmf.subtitles.SubtitlesEvent;
	
	public class JavaScriptBridge extends JavaScriptBridgeBase {
		
		public function JavaScriptBridge() {
			declaredByWhiteList.push("ru.kutu.grindplayer.media::GrindMediaPlayer");
		}
		
		[PostConstruct]
		override public function init():void {
			super.init();
			eventMap.mapListener(eventDispatcher, AdvertisementEvent.ADVERTISEMENT, onAdvertisement, AdvertisementEvent);
            ExternalInterface.addCallback("get", onGetPropertyCalled);
            ExternalInterface.addCallback("set", onSetPropertyCalled);
            ExternalInterface.addCallback("getProperty", onGetPropertyCalled);
            ExternalInterface.addCallback("setProperty", onSetPropertyCalled);
            ExternalInterface.addCallback("snapshot", onSnapshotCalled);
            ExternalInterface.addCallback("setClick", onSetClickCalled);
            ExternalInterface.addCallback("detectStall", onDetectStallCalled);
            ExternalInterface.addCallback("sync", onSyncCalled);
            ExternalInterface.addCallback("resume", player.play);
            ExternalInterface.addCallback("play", player.play);
            ExternalInterface.addCallback("stop", player.stop);
            //onSetClickCalled("snapshot");
            player.bufferTime = 1;
		}
		
		override protected function initializeEventMap():void {
			super.initializeEventMap();
			eventMaps[SubtitlesEvent.SUBTITLES_SWITCHING_CHANGE]	= function(event:SubtitlesEvent):Array{return [event.switching];};
			eventMaps[SubtitlesEvent.NUM_SUBTITLES_STREAMS_CHANGE]	= function(event:SubtitlesEvent):Array{return [];};
			eventMaps[SubtitlesEvent.HAS_SUBTITLES_CHANGE]			= function(event:MediaPlayerCapabilityChangeEvent):Array{return [event.enabled];};
		}
		
		private function onAdvertisement(event:AdvertisementEvent):void {
			var ids:Array = [];
			if (event.ads && event.ads is Array) {
				for each (var item:Object in event.ads) {
					ids.push(item.id);
				}
			}
			call([javascriptCallbackFunction, ExternalInterface.objectID, "advertisement", ids]);
		}

        private function onGetPropertyCalled(pPropertyName:String = ""):*{

            switch(pPropertyName){
                case "autoplay":
                    return player.autoPlay;
                case "buffering":
                    return player.buffering;
                case "bufferTime":
                    return player.bufferTime;
                case "bufferLength":
                    return player.bufferLength;
                case "currentTime":
                    return player.currentTime;
                case "duration":
                    return player.duration;
                case "enableControlBar":
                    return PlayerConfiguration.enableControlBar;
                case "enableDblClick":
                    return PlayerConfiguration.enableDblClick;
                case "enableKeyPress":
                    return PlayerConfiguration.enableKeyPress;
                case "loop":
                    return player.loop;
                case "mediaHeight":
                    return player.mediaHeight;
                case "mediaWidth":
                    return player.mediaWidth;
                case "muted":
                    return player.muted;
                case "paused":
                    return player.paused;
                case "playing":
                    return player.playing;
                case "seeking":
                    return player.seeking;
                case "state":
                    return player.state;
                case "volume":
                    return player.volume;
            }
            return null;
        }

        private function onSetPropertyCalled(pPropertyName:String = "", pValue:* = null):void{
            switch(pPropertyName){
                case "autoplay":
                    player.autoPlay = humanToBoolean(pValue);
                    break;
                case "bufferTime":
                    player.bufferTime = Number(pValue);
                    break;
                case "enableControlBar":
                    PlayerConfiguration.enableControlBar = humanToBoolean(pValue);
                    break;
                case "enableDblClick":
                    PlayerConfiguration.enableDblClick = humanToBoolean(pValue);
                    break;
                case "enableKeyPress":
                    PlayerConfiguration.enableKeyPress = humanToBoolean(pValue);
                    break;
                case "loop":
                    player.loop = humanToBoolean(pValue);
                    break;
                case "muted":
                    player.muted = humanToBoolean(pValue);
                    break;
                case "volume":
                    player.volume = Number(pValue);
                    break;
                default:
                    log('PROPERTY_NOT_FOUND', pPropertyName);
                    break;
            }
        }

        public function humanToBoolean(pValue:*):Boolean{
            if(String(pValue) == "true" || String(pValue) == "1"){
                return true;
            }
            else{
                return false;
            }
        }

        public function log(... args):void {
            var __incomingArgs:* = args as Array;
            call(['log', ExternalInterface.objectID].concat(__incomingArgs));
        }

        private function onSnapshotCalled(path:String = ""):String{
            //onSetClickCalled(_clickAction);
            //Security.loadPolicyFile("xmlsocket://localhost:843");
            //Security.loadPolicyFile("http://localhost:8081/crossdomain.xml");

            var jpgEncoder:JPGEncoder;
            jpgEncoder = new JPGEncoder(90);
            var rect:Rectangle = player.displayObject.getRect(player.displayObject);
            //log("onSnapshotCalled-video", player.mediaWidth, player.mediaHeight);
            //log("onSnapshotCalled-videoRect1", rect.width, rect.height);
            var bitmapData:BitmapData = new BitmapData(player.mediaWidth, player.mediaHeight);
            try {
                var m:Matrix = new Matrix();
                m.scale(bitmapData.width/rect.width, bitmapData.height/rect.height);
                bitmapData.draw(player.displayObject, m);
            }
            catch(e:SecurityError){
                log("snapshot-bitmapData.draw-SecurityError", e.message);
                throw e;
            }
            catch(e:ArgumentError){
                log("snapshot-bitmapData.draw-ArgumentError", e.message);
                throw e;
            }
            var img:ByteArray = jpgEncoder.encode(bitmapData);
            if (path == "") {
                log('snapshot OK');
                return Base64.encode(img);
            }

            if (/^https?:\/\//i.test(path)) {
                //var v:URLVariables = new URLVariables();
                //for (var i:int = 0; i<fields.length; i++) {
                //    var p:Array = fields[i];
                //    v[p[0]] = p[1];
                //}

                var sendHeader:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
                var sendReq:URLRequest = new URLRequest(path);

                sendReq.requestHeaders.push(sendHeader);
                sendReq.method = URLRequestMethod.POST;
                sendReq.data = img;

                var sendLoader:URLLoader;
                sendLoader = new URLLoader();
                sendLoader.addEventListener(Event.COMPLETE, completeHandler);
                sendLoader.load(sendReq);
            }
            else {
                var file:FileReference = new FileReference();
                file.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
                file.addEventListener(Event.COMPLETE, completeHandler);
                try {
                    file.save(img, path);
                }
                catch(e:Error){
                    log('Auto save failed. Click video to retry');
                }
            }

            return "";
        }

        private function ioErrorHandler(event:IOErrorEvent):void{
            log('snapshotComplete', event);
        }

        private function completeHandler(event:Event):void{
            log('snapshotComplete', event);
        }

        private function onUncaughtError(e:Event):void{
            e.preventDefault();
        }

        private var _clickAction:String = "";

        private function onSetClickCalled(action:String = ""):void{
            if(player.displayObject) {
                player.displayObject.removeEventListener(MouseEvent.CLICK, onStageClick);
                player.displayObject.addEventListener(MouseEvent.CLICK, onStageClick);
            }
            _clickAction = action;
        }

        private function onStageClick(e:MouseEvent):void{
            if(_clickAction.indexOf("stat") > -1) {
                // Live content When streaming live content, set the bufferTime property to 0.
                log('currentTime', player.currentTime);
                log('bufferTime', player.bufferTime);
                log('bufferLength', player.bufferLength);
                var lag:int = player.bufferLength - player.bufferTime;
                log('lag', lag);
            }
            if(_clickAction.indexOf("snapshot") > -1) {
                onSnapshotCalled("dummy");
            }
        }

        private function onSyncCalled():void{
            player.pause();
            player.play();
        }

        private var _stallTimer:Timer = null;
        private var _stallListener:String = "";
        private var _stallTmo:int = 30;
        private var _lastVideoTime:Number = 0; // number of seconds
        private var _lastRecordTime:Date = new Date();

        private function onDetectStallCalled(listener:String = "", tmo:int = 30):void{
            if (tmo < 10)
                tmo = 10;
            _stallTmo = tmo;
            _stallListener = listener;

            tmo = _stallTmo * 1000 / 3;
            tmo = tmo >= 5000 ? tmo : 5000;
            if (!_stallTimer) {
                _stallTimer = new Timer(tmo);
                _stallTimer.addEventListener(TimerEvent.TIMER, onStallTimer);
            }

            if(_stallTimer.delay != tmo)
                _stallTimer.delay = tmo;
            if (listener == "" && _stallTimer.running) {
                _stallTimer.stop();
            }
            else if (listener != "" && !_stallTimer.running) {
                startStallTimer();
            }
        }

        private function startStallTimer():void {
            updateStallRecord();
            _stallTimer.start();
        }

        private function updateStallRecord():void {
            _lastVideoTime = player.currentTime;
            _lastRecordTime = new Date();
            //log('updateStallRecord', _lastVideoTime, _lastRecordTime.toTimeString());
        }

        private function onStallTimer(evt:Event):void {
            var now:Date = new Date();
            if (player.bufferLength > player.bufferTime + 0.5) {
                ExternalInterface.call(_stallListener, ExternalInterface.objectID, 'lag');
                //log('lag detected', ns.bufferLength, ns.bufferTimeMax);
            }
            if (player.currentTime == _lastVideoTime &&
                now.getTime() - _lastRecordTime.getTime() > _stallTmo * 1000) {
                if(ExternalInterface.available) {
                    ExternalInterface.call(_stallListener, ExternalInterface.objectID, 'stall');
                }
                //log('Stall detected', _stallListener, _lastVideoTime, _lastRecordTime.toTimeString());
                updateStallRecord();
            }
            if (player.currentTime != _lastVideoTime) {
                updateStallRecord();
            }
        }
	}
	
}
