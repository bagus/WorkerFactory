package  
{
	import com.bit101.components.*;
	import flash.display.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.events.*;
	import flash.geom.*;
	
	import net.hires.debug.Stats;
	
	import com.signt.events.WorkerEvent;
	 
	public class TestMulti extends Sprite {
		public function TestMulti() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		private var workersIdle : Vector.<MultiWorker>;
		private var workersCreated : Vector.<MultiWorker>;
		private var workersBusy : Vector.<MultiWorker>;
		private var bmd : BitmapData;
		private var window : Window;
		
		private var numWorker : int = 4;
		private var numJob : int = 500;
		private var randomJob : Boolean = false;
		private var singleThread : Boolean = false;
		private var noProgress : Boolean = false;
		private var canceled : Boolean = false;
		private var sliderBlock:HSlider;
		private var buttonStart : PushButton 
		private var progressBar:ProgressBar;
		private var labelProgress:Label;
		private var blocksize:int = 23;
		private var jobTotal:int = 0;
		private var jobFinished:int = 0;
		private var startTime : int = 0;
		private var worksLoad : int = 0;
		private var worksLoadTotal : int = 0;
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// entry point
			
			bmd = new BitmapData(stage.stageWidth, stage.stageHeight, false, 0xffffff);
			canvasClear();
			var bitmap : Bitmap = new Bitmap(bmd);
			
			addChild(bitmap);
			
			//window
			
			var window:Window = new Window(this, (stage.stageWidth-300)/2, (stage.stageHeight-180)/2, "OPTIONS");
			window.width = 300;
			window.height = 190;		
			window.shadow = true;
			window.hasMinimizeButton = true;
			
			//stat
			
			var stat : Stats = new Stats();
			window.addChild(stat);
			stat.x = 8;
			stat.y = 10;
			
			// num worker slider

			var sliderWorker:HSlider = new HSlider(window.content, 90, 22, 
				function(e:Event):void {
					numWorker = Math.floor(sliderWorker.value);
					labelWorker.text = labelWorker.text.split(":")[0]+": "+Math.floor(sliderWorker.value).toString();
				}
			);
			sliderWorker.width = 200;
			sliderWorker.value = numWorker;
			sliderWorker.minimum = 1;
			sliderWorker.maximum = 20;			
			var labelWorker:Label = new Label(window.content, 90, 5, "Number of Workers: " + sliderWorker.value.toString());
			
			// block size slider
			
			sliderBlock = new HSlider(window.content, 90, 52, 
				function(e:Event):void {
					blocksize = Math.floor(sliderBlock.value);
					labelBlock.text = labelBlock.text.split(":")[0] + ": " + Math.floor(sliderBlock.value).toString();
					canvasClear();
				}
			);
			sliderBlock.width = 200;
			sliderBlock.minimum = 5;
			sliderBlock.maximum = 100;			
			sliderBlock.value = blocksize;
			var labelBlock:Label = new Label(window.content, 90, 35, "Block Size: " + Math.floor(sliderBlock.value).toString());
			
			// workload slider
			
			var sliderJob:HSlider = new HSlider(window.content, 90, 82,
				function(e:Event):void {
					numJob = Math.floor(sliderJob.value);
					labelJob.text = labelJob.text.split(":")[0] + ": " + Math.floor(sliderJob.value).toString()+" jobs";
				}
			);
			sliderJob.width = 200;
			sliderJob.minimum = 0;
			sliderJob.maximum = 2000;			
			sliderJob.value = numJob;
			var labelJob  : Label = new Label(window.content, 90, 65, "Workloads per worker: " + Math.floor(sliderJob.value).toString()+" jobs");
			
			// start button
			
			buttonStart = new PushButton(window.content, 8, 115, "START",
				function(event:Event):void { 
					buttonStart.enabled = false;
					if (!stage.hasEventListener(Event.ENTER_FRAME)) {
						workersCreated = new Vector.<MultiWorker>;
						sliderBlock.enabled = false;
						createWorker(); 
					} else {canceled = true;};
				}
			);
			buttonStart.width = stat.width;
			
			// checkboxes
			 
			new CheckBox(window.content, 90, 100, "Randomize workloads on each block", 
				function(e:Event):void { 
					randomJob = !randomJob;
				} 
			);
			new CheckBox(window.content, 90, 120, "Single Thread Mode", 
				function(e:Event):void { 
					singleThread = !singleThread;
				} 
			);
			new CheckBox(window.content, 200, 120, "Disable Progress", 
				function(e:Event):void { 
					noProgress = !noProgress;
				} 
			);			
			
			// progress bar
			
			progressBar = new ProgressBar(window.content, 8, 140);
			progressBar.width = 283;
			progressBar.height = 20;
		
			progressBar.maximum = 100;
			labelProgress = new Label(window.content, 18, 140, "Ready");
			labelProgress.width = progressBar.width - 20;
		}
		
		private function createWorker():void {
			var worker : MultiWorker = new MultiWorker(this.stage.loaderInfo);
			worker.addEventListener(WorkerEvent.READY, onWorkerReady);
			worker.addEventListener(WorkerEvent.TERMINATED, onWorkerTerminated);
			// if worker is not supported then run as single thread
			if (!worker.hasWorker||singleThread) worker.singleThreadMode = true;
		}
		private var jobs:Vector.<Object> = new Vector.<Object>;
		
		private function finished():void {
			stage.removeEventListener(Event.ENTER_FRAME, loadJob);
			var time : int = getTimer() - startTime;
			labelProgress.text = (canceled?"Canceled!":"Finished!")+" "+jobFinished.toString()+" blocks ("+worksLoad.toString()+" jobs) in " + time.toString() + "ms, Speed: "+Math.floor(time/jobFinished).toString()+"ms";
			while (workersCreated.length > 0) workersCreated.pop().destroy();
			sliderBlock.enabled = true;
			buttonStart.label = "START";
			buttonStart.enabled = true;
		}
		
		private function loadJob(e:Event):void {
			if(!canceled&&jobs.length) {
				if (workersIdle.length) {
					var worker : MultiWorker = workersIdle.shift();
					var job : Object = jobs.shift();
					
					canvasDrawBlock(job.x, job.y, 0xdddddd);					
					workersBusy.push(worker);
					var progressHandler : Function;
					if (!noProgress) progressHandler = 
						function (processed:int, total:int):Boolean {
							if (canceled) {
								for (var i:int = 0; i < workersBusy.length; i++ )
									if (workersBusy[i].name == worker.name) workersBusy.splice(i, 1);
								worksLoad += processed;
								return true;
							}
							canvasDrawBlock(job.x, job.y, worker.color, processed / total * 100);
							return false;
						}
					worker.calc(job, 
						function(isDone:Boolean,data:Object):void {
							worksLoad += job.loop;
							canvasDrawBlock(data.x, data.y, worker.color);	
							for (var i:int = 0; i < workersBusy.length; i++ ) {
								if (workersBusy[i].name == worker.name) workersBusy.splice(i, 1);
							}
							if (!canceled) {
								jobFinished++;
								var percent : int = 100 * (jobFinished / jobTotal);
								progressBar.value = percent;
								var time : int = getTimer() - startTime;
								labelProgress.text = "Progress (" + percent.toString() + "%) : " + jobFinished.toString() + " of " + jobTotal.toString()+" blocks, Speed: "+Math.floor(time/jobFinished).toString()+"ms/block";
								
								if (jobFinished == jobTotal) {
									finished();
								} else {
									workersIdle.push(worker);
								}
							}
						}, 
						progressHandler
					);
				}
			} 
			else if (singleThread) finished();
			else if (canceled) {
				if (workersBusy.length == 0) finished();
			}
		}
		
		private function canvasClear() : void {
			bmd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0xffffff);			
			var w:int = stage.stageWidth / blocksize;
			var h:int = stage.stageHeight / blocksize;		
			var i:int;
			var j:int;			
			for (j = 0; j < h; j++) {
				for (i = 0; i < w; i++) {
					canvasDrawBlock(i, j, 0xeeeeee);
				}
			}
		}
		private function canvasDrawBlock(x:int, y:int,color:uint,percent:Number=100) : void {
			bmd.fillRect(new Rectangle((x * blocksize)+1,(y * blocksize)+1,(blocksize-1)*percent/100,blocksize-1), color);
		}		
		private function run():void {
			workersIdle = new Vector.<MultiWorker>;
			workersBusy = new Vector.<MultiWorker>;
			canvasClear();
			canceled = false;
			startTime = getTimer();
			var i:int;
			var j:int;
			var w:int = stage.stageWidth / blocksize;
			var h:int = stage.stageHeight / blocksize;
			var total : int = 0;
			var id : int = 0;
			jobs = new Vector.<Object>;
			worksLoad = 0;
			worksLoadTotal = 0;
			jobFinished = 0;
			for (j = 0; j < h; j++) {
				for (i = 0; i < w; i++) {
					total = !randomJob?numJob:Math.random() * numJob ;
					worksLoadTotal += total;
					id++;
					jobs.push( { id:id, x:i, y:j, hash:"", loop: total } )
				}
			}
			jobTotal = jobs.length;
			for (i = 0; i < workersCreated.length; i++) {
				workersIdle.push(workersCreated[i]);
			}
			stage.addEventListener(Event.ENTER_FRAME, loadJob);
			buttonStart.enabled = true;
			buttonStart.label = "STOP";
		}

		private function onWorkerReady(event:Event = null):void {
			var worker : MultiWorker = event.currentTarget as MultiWorker;
			worker.removeEventListener(WorkerEvent.READY, onWorkerReady);
			workersCreated.push(worker);
			progressBar.value = 100 * (workersCreated.length / numWorker);
			labelProgress.text = "Worker #" + workersCreated.length.toString() + " created";
			if (workersCreated.length < numWorker) {
				createWorker(); 
			} else {
				run();
			}
		}
		
		private function onWorkerTerminated(e:Event):void {
			trace('worker destroyed');
		}
	}
}