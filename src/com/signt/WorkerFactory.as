package  com.signt 
{
	
	/** 
	 * 
	 * The WorkerFactory is an extendable worker class with built-in messaging function for communication between main and worker
	 * 
	 * version 0.5.2
	 * 
	 * Released under MIT license:
	 * http://www.opensource.org/licenses/mit-license.php
	 * 
	 * @author Bagus
	 * @mail bagus@signt.com
	 * 
	 */	 

	import flash.display.*;
	import flash.events.*;
	import flash.system.*;
	import flash.utils.*;
	import flash.net.*;
	
	import com.codeazur.as3swf.SWF;
	
	import com.signt.interfaces.IWorkerFactory;
	import com.signt.events.WorkerEvent;
	import com.signt.types.WorkerMessage;
	import com.signt.GlobalData;
	
	public class WorkerFactory extends Sprite implements IWorkerFactory 
	{	
		private var __incomingMessageChannel:MessageChannel;
		private var __outgoingMessageChannel:MessageChannel;
		
		private var __jobs : Object;
		private var __jobID : uint = 0;
		private var __processID : uint = 0;
		private var __process : Object;
		private var __tasklist : Vector.<Object> = new Vector.<Object>;
		private var __started : Boolean;
		private var __ready : Boolean;
		private var __loaderInfo : LoaderInfo ;
		private var __DATA : Object;
		private var __singleThreadMode : Boolean = false;		
		private var __isPrimordial : Boolean;
		
		protected var __worker:Worker;
		
		public function WorkerFactory(loader:LoaderInfo = null, giveAppPrivileges:Boolean = false, noCache:Boolean=false) {
			
			if(Worker.isSupported) {
				if (Worker.current.isPrimordial) {
					if (loader == null) {
						error('loader is required!'); 
						return;
					} 
					__isPrimordial = true;
					__loaderInfo = loader;
					var cn : String = getQualifiedClassName(this).replace(/::/g, ".");
					var swf:ByteArray
					if(!noCache) {
						if (!GlobalData.getInstance("WorkerFactory")[cn]) {
							GlobalData.getInstance("WorkerFactory")[cn] = DynamicSWF.fromClass(cn, __loaderInfo.bytes);
						}
						swf = GlobalData.getInstance("WorkerFactory")[cn];
					} else swf = DynamicSWF.fromClass(cn, __loaderInfo.bytes);
					__worker = WorkerDomain.current.createWorker(swf, giveAppPrivileges);
					__incomingMessageChannel = Worker.current.createMessageChannel(__worker);
					__outgoingMessageChannel = __worker.createMessageChannel(Worker.current);
					__worker.setSharedProperty("incomingMessage", __incomingMessageChannel);
					__worker.setSharedProperty("outgoingMessage", __outgoingMessageChannel);
					__outgoingMessageChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessageReceived);
					__worker.addEventListener(Event.WORKER_STATE, onWorkerStateHandler); 
					__worker.start();
				} else {
					__isPrimordial = false;
					__worker = Worker.current;
					__incomingMessageChannel = __worker.getSharedProperty("incomingMessage");
					__outgoingMessageChannel = __worker.getSharedProperty("outgoingMessage");
					__incomingMessageChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessageReceived);
					__ready = true;
					send([WorkerMessage.READY, {} ]);			
				}						
				//debug("initialization complete");
			} else {
				__isPrimordial = true;
			}
			__reset();			
		}
		
		final public function get isPrimordial():Boolean {
			return (!__worker?true:__isPrimordial);
		}
		
		final public function get hasWorker() : Boolean {
			return __worker ? true : false;
		}
		
		final public function get singleThreadMode() : Boolean {
			return __singleThreadMode;
		}
		
		final public function set singleThreadMode(value:Boolean) : void {
			__singleThreadMode = value;
			if (hasEventListener(WorkerEvent.MODE_CHANGED)) {
				dispatchEvent(new Event(WorkerEvent.MODE_CHANGED));
			}			
			if (value && !__ready) {
				__ready = true;
				if (hasEventListener(WorkerEvent.RUNNING)) {
					dispatchEvent(new Event(WorkerEvent.RUNNING));
				}
			}
		}
		
		final private function __reset():void {
			__started 	= false;
			__ready 	= false;
			__jobs 		= { };
			__process 	= { };
			__DATA		= { };							
		}
		
		/**
		 * Calling a function on the other side, if you calling from main it will call function on worker, vice versa
		 * 
		 * @param method The function name to be called.
		 * @param args The function parameters to be passed.
		 * @param onComplete a callback which is called when process has been completed
		 * @param onProgress a callback for handle progress event and cancelation.
		 * @param onError a callback which is called when an error has occured.
		 * 
		 */		
		
		final public function call(method:String, args:Array = null, onComplete:Function = null, onProgress:Function = null, onError:Function = null) : Boolean {
			if (__isPrimordial && !__ready) { 
				error("worker is not ready"); 
				return false; 
			} 
			
			// sanitize the arguments
			if (args == null) args = [];
			if (onError!=null && args.indexOf(onError) != -1) args.pop();
			if (onProgress!=null && args.indexOf(onProgress) != -1) args.pop();
			if (onComplete != null && args.indexOf(onComplete) != -1) args.pop();			
			
			if(onComplete!=null) {
				__jobID++;
				__jobs[__jobID] = { id:__jobID, onComplete:onComplete, onProgress:onProgress, onError:onError, single:true };
			}
			try {
				if(!__singleThreadMode)
					send([WorkerMessage.CALL, { id:(onComplete != null?__jobID:0), method:method, args:args, onComplete: !(onComplete == null) , onProgress: !(onProgress == null), onError: !(onError == null) } ]);			
				else __processMessage([WorkerMessage.CALL, { id:(onComplete != null?__jobID:0), method:method, args:args, onComplete: !(onComplete == null) , onProgress: !(onProgress == null), onError: !(onError == null) } ]);
			} catch (e:*) { 
				error(e);
				if(onComplete!=null) delete __jobs[__jobID];
			}
			return true;
		}				

		/**
		 * Calling a function on worker side, this function is only can be called from main and when not in single thread mode
		 * 
		 * @param method The function name to be called.
		 * @param args The function parameters to be passed.
		 * @param onComplete a callback which is called when process has been completed
		 * @param onProgress a callback for handle progress event and cancelation.
		 * @param onError a callback which is called when an error has occured.
		 * 
		 */		
		
		final public function callWorker(method:String, args:Array = null, onComplete:Function = null, onProgress:Function = null, onError:Function = null) : Boolean {
			if (!__singleThreadMode && __isPrimordial) {
				return call(method, args, onComplete, onProgress, onError);
			}
			return false;
		}				
		
		/**
		 * Tracing a message.
		 */		
		 
		protected function debug(...args) : void { 
			if (!Capabilities.isDebugger) return;  
			if (__isPrimordial) 
				trace.apply(null, ["Debug:"].concat(args)); 
			else send([WorkerMessage.DEBUG, ["[w]"].concat(args)]); 
		}
		
		/**
		 * Displaying detailed error message.
		 */		
		
		protected function error(...args) : void { 
			if (!Capabilities.isDebugger) return;  
			if (__isPrimordial) { 
				var error :String = args[0]+"\n";
				if(args.length>1)
				for (var i:int = 1; i < args.length; i++) {
					if ((args[i] != null) && (args[i] != undefined)) {
						var message :* = args[i];
						var err : String = "";
						if (message is String) {
							err = message;
						} else {
							err = 	("errorID" in message?"ID: " + message.errorID + "\n":"") +
									("name" in message?"\tName: " + message.name + "\n":"") +
									("exceptionValue" in message?"\tException: " + message.exceptionValue+ "\n":"") +
									("message" in message?"\tMessage: " + message.message+ "\n":"") + 				
									("text" in message?"\tText: " + message.text + "\n":"");
							if ("stackTrace" in message) {
								err += "\nStack Trace:";
								for (var e:int = 0; e < message.stackTrace.length; e++) {
									var stack : * = message.stackTrace[e];
									err += "\n\t"+e.toString()+" ";
									err += ("functionName" in stack?"function: " + stack.functionName + " ":"");
									err += ("sourceURL" in stack?"file: " + stack.sourceURL + " (" + ("line" in stack?stack.line.toString() + ")":"") + " ":"");
								}	
							}
						}
					}			
					error += err;
				}
				trace("Error:",error);
			} else send([WorkerMessage.ERROR, ["[w]"].concat(args)]); 
		}
		
		// experimental not implemente
		
		final private function exec(method:Function, params:Array = null):void {
			var timer : Timer = new Timer(0);
			var todo : Function = function(e:Event = null):void {
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, todo);
				timer = null;
				method.apply(null, params);
			};
			timer.addEventListener(TimerEvent.TIMER,todo);
			timer.start();
		}
		/**
		 * Set the value of data on both side, so that data on both sides had the same value
		 *
		 * @param varname Property name.
		 * @param value The value to be set.
		 *
		 */		
		
		final public function dataSet(name:String, value:*) : void {
			__DATA[name] = value;
			if(!__singleThreadMode) send([WorkerMessage.DATA_SET, [name, value]]);
		}

		/**
		 * Delete the value of data on both side
		 *
		 * @param varname Property name.
		 * @param value The value to be set.
		 *
		 */		
		
		final public function dataDelete(name:String) : void {
			delete __DATA[name];
			if(!__singleThreadMode) send([WorkerMessage.DATA_DELETE,[name]]);
		}
		
		/**
		 * Returns the value of data on current side
		 *
		 * @param name Property name.
		 *    
		 */				
		
		final public function dataGet(name:String) : * {
			return __DATA[name];
		}
		
		/**
		 * Syncronize the data value on both side
		 *
		 * @param name Property name.
		 *    
		 */		
		
		final public function dataSync(name:String) : void {
			if(!__singleThreadMode) send([WorkerMessage.DATA_SYNC, [name]]);
		}
		
		/**
		 * Destroy the worker
		 *
		 * @param callback a callback to return success or fail state
		 *    
		 */		
		
		public function destroy(callback:Function = null) : void {
			if (__isPrimordial) {
				this.call("destroy", [], function(success:Boolean):void {
					if (success) {
						__ready = false;
						success = __worker.terminate();
						if (callback != null) callback(success);
					}
				})
			}
			else {
				if(callback!=null) callback(true);
				__reset();
			}
		}		
		
		//[PRIVATE]//////////////////////////////////////////////////////////////////////////////
		
		final private function onWorkerStateHandler(e:Event):void  { 
			debug("worker state:",e.currentTarget.state);
			switch(e.currentTarget.state) {
				case WorkerState.RUNNING:
					if (hasEventListener(WorkerEvent.RUNNING)) 
						dispatchEvent(new Event(WorkerEvent.RUNNING));
					break;
				case WorkerState.NEW:
					if (hasEventListener(WorkerEvent.NEW)) 
						dispatchEvent(new Event(WorkerEvent.NEW));
					break;					
				case WorkerState.TERMINATED:
					__reset();
					if (hasEventListener(WorkerEvent.TERMINATED)) 
						dispatchEvent(new Event(WorkerEvent.TERMINATED));
					break;					
			}
			if (hasEventListener(Event.WORKER_STATE)) 
				dispatchEvent(e);
		}			
		
		final private function onMessageReceived(event:Event):void {
			var msg : * = event.currentTarget.receive();
			if (msg is Array) {
				if (!(msg.length > 1)) {
					error("missing arguments for message:",msg);
					return;
				}
			} else error("invalid message");
			__processMessage(msg);
		}
		
		final private function send(msg:Array) : void {
			if (!__worker) {
				__processMessage(msg);
				return;
			}
			if (__isPrimordial)__incomingMessageChannel.send(msg);
			else __outgoingMessageChannel.send(msg);
		}
		
		final private function __processMessage(msg:Array) : void {
			var cmd : int = msg[0];
			var params : Object = msg[1];
			var task : Object;
			var job : Object;
			switch(cmd) {
				case WorkerMessage.READY :
					__ready = true;
					if (hasEventListener(WorkerEvent.READY)) 
						dispatchEvent(new Event(WorkerEvent.READY));					
					break;
				case WorkerMessage.DEBUG :
					debug.apply(null,params);
					break;
				case WorkerMessage.ERROR :
					error.apply(null,params);
					break;
				case WorkerMessage.CALL :
					job = params;
					switch(job.method) {
						case WorkerMessage.CALL :
							error("cannot calling internal method: " + job.method);
							return;
						default : 
							if (!(job.method in this)) {
								error("method not found: " + job.method);
								return;
							}
					}
					__process[job.id] = job;
					if (job.onComplete) {
						// inject new complete event
						job.args.push(
							function(...result):void {
								if(job.id in __process) {
									delete __process[job.id];
									send([WorkerMessage.EVENT_COMPLETE, { id:job.id, result:result } ] );
								}
							}
						);
					}
					if (job.onProgress) {
						// inject new progress event
						job.args.push(function(...progress):Boolean {
							if (dataGet("jobcanceled#" + job.id.toString())) {
								delete __DATA["jobcanceled#" + job.id.toString()];
								return true;
							}
							send([WorkerMessage.EVENT_PROGRESS, { id:job.id, progress:progress } ] );
							return false;
						});
					}
					try {
						this[job.method].apply(null, job.args);
					} catch (e:*) {
						error(e);
						if (job.onError) {
							if(job.id in __process) {
								delete __process[job.id];
								send([WorkerMessage.EVENT_ERROR, { id:job.id, error:e } ] );
							}
						}
					}
					break;

				case WorkerMessage.EVENT_COMPLETE :
					job = params;
					task = __jobs[job.id];
					delete __jobs[job.id];
					if(task && task.onComplete!=null) task.onComplete.apply(null,job.result);
					break;

				case WorkerMessage.EVENT_PROGRESS :
					job = params;
					task = __jobs[job.id];
					if(task) {
						if (task && (task.onProgress)) {
							if (task.onProgress.apply(null, job.progress)) {
								dataSet("jobcanceled#" + job.id.toString(), true);
							} 
						}
					};
					break;
				case WorkerMessage.EVENT_ERROR :
					job = params;
					task = __jobs[job.id];
					delete __jobs[job.id];
					if(task.onError!=null) task.onError(job.error);
					break;			
				case WorkerMessage.DATA_SET :
					if ((params is Array) && params.length > 1) {
						__DATA[params[0]] = params[1];
					}
					else error("data value is required for property :",params[0]);
					break;
				case WorkerMessage.DATA_DELETE :
					delete __DATA[params[0]];
					break;
				case WorkerMessage.DATA_SYNC :
					if(params[0] in __DATA) {
						send([WorkerMessage.DATA_SET, [params[0], __DATA[params[0]]]]);
					}
					break;
					
				default : 
					error("invalid command:",cmd);
			}
		}
	}
}
