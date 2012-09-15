package com.signt.events 
{
	import flash.events.Event;

	public class WorkerEvent extends Event
	{
		public static const RUNNING:String = "WORKER_RUNNING";
		public static const READY:String = "WORKER_READY";
		public static const NEW:String = "WORKER_NEW";
		public static const TERMINATED:String = "WORKER_TERMINATED";
		public static const MODE_CHANGED:String = "WORKER_MODE_CHANGED";

		public function WorkerEvent(type:String)
		{
			super(type);
		}
		
	}
}