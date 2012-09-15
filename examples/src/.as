	package 
{
	import com.signt.Interfaces.IWorkers;
	import com.signt.Workers;
	import flash.display.*;
	import flash.events.*;
	import flash.system.*;
	import net.hires.debug.Stats;
	
	
	
	/**
	 * ...
	 * @author Bagus
	 */
	public class Main extends Sprite 
	{
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private var worker : BitmapWorker;
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			trace("starting worker");
			
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			//stage.quality = StageQuality.BEST;
			
			worker = new BitmapWorker(true, this.stage);
			
			worker.addEventListener(WorkerState.RUNNING, onWorkerStarted);
			worker.addEventListener(WorkerState.TERMINATED, onWorkerTerminated);
			
			// entry point
		}
		private function onWorkerTerminated(e:Event):void {
			trace('yes it destroyed');
		}
		private function test1(worker:IWorkers):void {
			worker.add("looptest", [1000000,10000, "John"], 
				// on complete
				function(result:String):void { 
					trace(result);
				},
				// on progress
				function(processed:int,total:int, result:String):Boolean { 
					trace("progress", processed, total, result);
					return false;
				}

			);
			
			var total:int = 10000;
			for (var i:int = 0; i < total;i++) {
				worker.add("hello", [i,"John"], 
					function(i:int, result:String):void { 
						if(i%1000==0) trace(i,result); 
						if(i==total) {
							if (worker.destroy()) {
								trace('destroying');
							}
						}
					}
				);
			}
			worker.execute();
		}
		private function onWorkerStarted(e:Event):void {
			var worker:BitmapWorker = e.currentTarget as BitmapWorker;
			worker.removeEventListener(WorkerState.RUNNING, onWorkerStarted);
			trace("yes its started", e.currentTarget);
			//worker.call("hello", ["john"], function():void { } );
			worker.create(600, 419,.5);
			//worker.start(400,300);
			//worker.bitmap.scaleX = worker.bitmap.scaleY = 1;
			//worker.bitmap.smoothing = false;
			addChild(worker.bitmap);
			addChild( new Stats() );
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			//var worker :
		}
        private function handleMouseMove(event : MouseEvent) : void
        {
            // the ripple point of impact is size 20 and has alpha 1
			worker.call("drawRipple", [worker.bitmap.mouseX, worker.bitmap.mouseY]);
        }		
		
	}
	
}