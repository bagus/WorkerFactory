package  
{
	
	import com.signt.interfaces.IWorkers;
	import com.signt.events.WorkerEvent;
	import com.signt.WorkerFactory;
	import flash.display.LoaderInfo;

	public class SimpleWorker extends WorkerFactory implements IWorkers	{

		// the constructor

		public function SimpleWorker(loader:LoaderInfo=null, privilege:Boolean = false) {

			// the default value for parameters is needed because flash 
			// will load worker on background without passed any parameter 

			super(loader, privilege);
		}
				
		public function myFunction(name:String, onComplete:Function=null):void {

			// onComplete, onProgress, onError parameter are optional
			// if you want some data returned you need to add onComplete callback
			// just pass the data on parameter if you don't 

			if (!singleThreadMode && isPrimordial) {

				// calling the same function on background 

				call("myFunction", arguments, onComplete);
				return;
			} 

			// write your code here
			var data : String;
			data = "Hello " + name + ", I am running on background";
			
			// passes the data back to main
			onComplete(data)
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
