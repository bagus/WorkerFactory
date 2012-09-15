package 
{
	
	import flash.display.*;
	import flash.events.*;
	import flash.system.*;
	import flash.utils.*;
	import net.hires.debug.Stats;
	import com.bit101.components.*;
	import com.signt.events.WorkerEvent;
	
	public class TestLoop extends Sprite 
	{

		public function TestLoop():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			stage.frameRate = 60;
			var worker:LoopWorker = new LoopWorker(this.stage.loaderInfo);
			worker.addEventListener(WorkerEvent.READY, onWorkerStarted);
			worker.addEventListener(WorkerEvent.TERMINATED, onWorkerTerminated);		
			if (!worker.hasWorker) worker.singleThreadMode = true;
		}
				
		private function onWorkerStarted(e:Event = null):void {
			trace('worker started');
			var bg : Sprite = new Sprite;					
			bg.x = 100;
			bg.y = 10;
			bg.graphics.beginFill(0xffffff, .85);
			bg.graphics.drawRect(0, 5, 290, 55);
			bg.graphics.endFill();

			var bmd : BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight,false,0x000000);
			var bmp :Bitmap = new Bitmap(bmd);
			
			var started : Boolean = false;
			var canceled : Boolean = false;
			
			var btnStart:PushButton;
			
			addChild(bmp);
			addChild(bg);
			addChild( new Stats() );
					
			var progressBar:ProgressBar = new ProgressBar(bg, 10, 35);
			progressBar.maximum = 100;
			progressBar.width = 270;
			progressBar.height = 20;
			progressBar.value = 0;
			var label : Label = new Label(bg, 20, 35,"");			
			var worker:LoopWorker = e.currentTarget as LoopWorker;
			var onStartClicked : Function  = function () : void {
				if (started) {
					canceled = true;
					return;
				}
				canceled = false;
				started = true;
				btnStart.label = "STOP";
				
				// generate 10.000.000 random pixels in background
				// progress every 2 percent
				
				worker.drawpixels(10000000, 2, bmd.width, bmd.height, 
					// complete callback
					function(status:Boolean, pixels:uint, result:ByteArray, elapsed:int):void { 
						label.text = (status == true?"FINISHED":"CANCELED")+"! " + pixels.toString()+" PIXELS IN "+elapsed.toString() + " MS";
						bmd.setPixels(bmd.rect, result);
						btnStart.label = "START";
						started = false;
					},
					// progress callback
					function(processed:int, total:int, result:ByteArray):Boolean { 
						if (canceled) return true;
						bmd.setPixels(bmd.rect, result);
						var percent : int = Math.floor(processed / total * 100);
						progressBar.value = percent;
						label.text = "DRAWING " + processed.toString() + " OF " + total.toString()+" PIXELS ("+percent.toString()+"%)";
						return false;
					}

				);
			}
			btnStart = new PushButton(bg, 10, 10, "START", onStartClicked);
			btnStart.width = 50;
			new CheckBox(bg, 80, 15, "SINGLE THREAD MODE", 
				function(e:Event):void { 
					worker.singleThreadMode = !worker.singleThreadMode;
				} 
			);
			
			return;
		}
		
		private function onWorkerTerminated(e:Event):void {
			trace('worker destroyed');
		}

		
	}
	
}