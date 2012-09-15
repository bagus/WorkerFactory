package  
{
	import flash.display.Sprite;
	import com.signt.events.WorkerEvent;
	import flash.events.Event;
	 
	public class TestSimple extends Sprite {
		public function TestSimple() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			// create new instance of simple worker
			var myWorker : SimpleWorker = new SimpleWorker(this.stage.loaderInfo);
			// add listener
			myWorker.addEventListener(WorkerEvent.RUNNING, onWorkerStarted);
			myWorker.addEventListener(WorkerEvent.TERMINATED, onWorkerTerminated);
			// if worker is not supported then run as single thread
			if (!myWorker.hasWorker) myWorker.singleThreadMode = true;

		}
		private function onWorkerStarted(event:Event = null):void {
			trace('worker started');
			var myWorker : SimpleWorker = event.currentTarget as SimpleWorker
			// worker ready then 
			// call your function
			myWorker.myFunction("John",
				// onComplete
				function (data:String) : void {
					trace(data);
					myWorker.destroy();
				}
			);
		}
		private function onWorkerTerminated(e:Event):void {
			trace('worker destroyed');
		}
	}
}