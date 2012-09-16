package com.signt 
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/** 
	 * 
	 * The PseudoThread is a simple timer based multithreading class to execute batch of serial jobs through the queue
	 * 
	 * @author Bagus
	 * @mail bagus@signt.com
	 * 
	 */
	 
	public class PseudoThread 
	{
		private var _jobs : Vector.<Object>;
		private var _running : Boolean = false;
		private var _timer : Timer;
		private var _iteration : int = 1;

		/**
		 * Creates timer based pseudo thread instance.
		 * 
		 * @param waitingtime The amount of delay time before execute the next job in miliseconds
		 * @param iteration The number of job batch to be executed when timer triggered.
		 * 
		 */
		
		public function PseudoThread(waitingtime:int=0,iteration:int=1) 
		{
			_jobs = new Vector.<Object>;
			_running = false;
			_iteration = iteration;
			_timer = new Timer(waitingtime);
		}
		
		/**
		 * Adding job to the queue
		 * 
		 * @param method The method or abstract function to be execute
		 * @param params the method arguments
		 * 
		 */		
		
		final public function add(method:Function, params:Array=null):void {
			_jobs.push( { method:method, params:params } );
		}
		
		final private function doJob(event:TimerEvent = null):void {
			if (!_running) return;
			if(_timer.hasEventListener(TimerEvent.TIMER)) {
				_timer.stop();
				_timer.removeEventListener(TimerEvent.TIMER, doJob);
			}
			for (var i:int = 0; i < _iteration; i++) {
				if (_running && _jobs.length > 0) {
					var job:Object = _jobs.shift();
					job.method.apply(null, job.params);
				} else {
					_running = false;
					break;
				}
			}
			if (_jobs.length) loadJob();
		}

		final private function loadJob():void {
			if (_running && !_timer.hasEventListener(TimerEvent.TIMER)) {
				_timer.addEventListener(TimerEvent.TIMER, doJob);
				_timer.start();
			}
		}
		
		/**
		 * execute the all jobs in the queue
		 */	
		
		final public function execute():void {
			if(!_running) {
				_running = true;
				loadJob();
			}
		}
		
		/**
		 * stopping execution and clearing the queue
		 */		
		
		public function stop():void {
			if(_running) {
				_running = false;
				_jobs = new Vector.<Object>;
			}
		}		
	}

}