package  
{
	import com.signt.interfaces.IWorkers;
	import com.signt.WorkerFactory;
	import com.signt.PseudoThread;
	
	import flash.display.*;
	import flash.utils.*;
	
	/**
	 * ...
	 * @author Bagus
	 */

	public class LoopWorker extends WorkerFactory implements IWorkers
	{
	
		public function LoopWorker(loader:LoaderInfo=null, privileges:Boolean = false)   {
			super(loader, privileges);
		}	

		// convert bitmapdata to bytearray
		
		final private function bmdToBytearray(bmd:BitmapData,dispose:Boolean=false) : ByteArray {
			var ba:ByteArray = new ByteArray;
			bmd.copyPixelsToByteArray(bmd.rect, ba);
			ba.position = 0;
			if (dispose) bmd.dispose();
			return ba;
		}
		
		// draw pixels
		
		final public function drawpixels(numpixels:uint, percent:Number, _w:int, _h:int, onComplete:Function = null, onProgress:Function = null):void {	
			if (callWorker("drawpixels", arguments, onComplete, onProgress)) return;
			
			debug("starting processing", numpixels, "of data");
			
			var canceled : Boolean = false;
			var canvas : BitmapData = new BitmapData(_w, _h, false,0x000000);
			var startTime : int = getTimer();
			var endTime:int;

			// to handle cancellation and progress reporting 
			// we must execute the process outside the main loop
			// so I use old pseudo threading to trick this situation
			// I split the whole process into several blocks of process
			// and execute them as new thread on timer event 
			
			var step 		: uint = 0;
			var steps		: uint = Math.floor(numpixels * (percent / 100));
			
			var totalBlock	: int = Math.floor(numpixels / steps);
			if (numpixels > totalBlock * steps) totalBlock++;
			
			// creating the batch with 0ms delay and single iteration
			
			var batch : PseudoThread = new PseudoThread(0, 1);
			
			for (var blockNumber:int = 0; blockNumber < totalBlock ; blockNumber++) {
				batch.add(
					function() : void {
						// cancelation check
						if (canceled) return;
						canceled = onProgress(step, numpixels, bmdToBytearray(canvas));
						if (canceled) {
							batch.stop();
							debug("job was canceled at #" + step.toString());
							endTime = getTimer() - startTime;
							onComplete(false,step,bmdToBytearray(canvas,true),endTime);
							return;
						};
						var nextstep : uint = step + steps;
						while (step < nextstep) {
							// the process
							var x : int = Math.random() * _w;
							var y : int = Math.random() * _h;
							var color : uint = Math.random() * 0xFFFFFF;
							canvas.setPixel(x, y, color);
							// counter check
							step++;
							if (step == numpixels) {
								onProgress(step, numpixels,bmdToBytearray(canvas))
								endTime = getTimer() - startTime;
								debug("job completed in ", endTime, "ms");
								onComplete(true, step, bmdToBytearray(canvas,true), endTime);
								break;
							}
						}
					}
				);
			}
			// execute
			batch.execute();
		}
	}
}
