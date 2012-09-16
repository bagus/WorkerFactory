package  
{
	
	import com.signt.events.WorkerEvent;
	import com.signt.PseudoThread;
	import com.signt.WorkerFactory;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import com.adobe.crypto.MD5;
	

	public class MultiWorker extends WorkerFactory	{

		
		
		private var __color		: uint;

		// the constructor

		public function MultiWorker(loader:LoaderInfo=null) {
			super(loader, false);
			if (isPrimordial) {
				__color = Math.random() * 0xffffff;
			} 
		}

		final public function get color():uint {
			return __color;
		}
		
		
		// function
		final public function calc(data:Object, onComplete:Function = null, onProgress:Function = null):void {
			// call the same function in bg
			if (callWorker("calc", arguments, onComplete, onProgress)) return;
			data.hash = data.id;
			var batch : PseudoThread = new PseudoThread(0, 1);
			if(data.loop>0) {
				var n :int = data.loop / 4;
				for (var i:int = 0; i < data.loop; i++) {
					if (onProgress!=null && i % n == 0) if (onProgress(i, data.loop)) { onComplete(false,data); return };
					data.hash = MD5.hash(data.hash);
				}
			}
			onComplete(true,data)
		}
				
		override public function destroy(callback:Function = null):void {
			if (this.isPrimordial) {
				// clean main var here if any
			} else {
				// clean worker var here if any
			}
			super.destroy(callback);
		}
	}
}
