package ru.kutu.grindplayer.utils{

    import flash.external.ExternalInterface;
	import flash.events.Event;
	import flash.events.TimerEvent;
    import flash.utils.Timer;

	/**
     * ...
     * @author 
     */
    public class utils {

        public static function log(... args):void {
            var __incomingArgs:* = args as Array;
            call(['log', ExternalInterface.objectID].concat(__incomingArgs));
        }

		public static function call(args:Array, async:Boolean = true):void {
			if (async) {
				var asyncTimer:Timer = new Timer(10, 1);
				asyncTimer.addEventListener(TimerEvent.TIMER,
					function(event:Event):void {
						asyncTimer.removeEventListener(TimerEvent.TIMER, arguments.callee);
						ExternalInterface.call.apply(ExternalInterface, args);
					}
				);
				asyncTimer.start();
			} else {
				ExternalInterface.call.apply(ExternalInterface, args);
			}
		}

    }

}