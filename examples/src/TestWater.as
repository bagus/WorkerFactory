package {
	
	import com.signt.events.WorkerEvent;
	

	
	import flash.display.*;
	import flash.events.*;
	import flash.system.*;
	import flash.utils.*;
	
	import net.hires.debug.Stats;
	import com.bit101.components.*;
	
	/**
	 * ...
	 * @author Bagus
	 */
	
	public class TestWater extends Sprite {
		
		public function TestWater():void {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private var water : WaterWorker;
		
		private function init(e:Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.BEST;
			stage.frameRate = 30;
			// start the worker
			water = new WaterWorker(stage.loaderInfo);
			water.addEventListener(WorkerEvent.READY, onWorkerStarted);
			water.addEventListener(WorkerEvent.TERMINATED, onWorkerTerminated);
		}
		
		private function onWorkerStarted(e:Event):void {
			water.removeEventListener(WorkerEvent.READY, onWorkerStarted);
			water.create(460, 300);
			addChild(water.bitmap);
			addChild( new Stats() );
			var btnStart:PushButton;
			btnStart = new PushButton(this, 100, 10, "SINGLE THREAD MODE", function(e:Event):void {
				btnStart.label = (water.singleThreadMode ? "SINGLE":"MULTI") + " THREAD MODE";
				water.singleThreadMode = !water.singleThreadMode;
			});
			btnStart.width = 120;
		}
		private function onWorkerTerminated(e:Event):void {
			removeChild(water.bitmap);
		}
	}
}