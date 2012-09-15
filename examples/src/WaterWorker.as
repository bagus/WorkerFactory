package  
{
	import flash.geom.*;
	import flash.filters.*
	import flash.events.*;
	import flash.system.*;
	import flash.display.*;
	import flash.net.*;
	import flash.utils.*;
	
	import be.nascom.flash.graphics.Rippler;
	
	import com.signt.interfaces.IWorkers;
	import com.signt.events.WorkerEvent;
	import com.signt.WorkerFactory;
	
	
	
	/**
	 * ...
	 * @author Bagus
	 */

	public class WaterWorker extends WorkerFactory implements IWorkers
	{
		[Embed(source="../embeds/images/shallow-water-750509-ga.jpg")]
        private var _sourceImage : Class;
		
		//////////////////////////////////////////////////////////////////////////////
		
		private var _canvas : Sprite;
		private var _bitmapdata : BitmapData;
		private var _started : Boolean = false;
		private var _rippler : Rippler;
		private var _scale : Number = 1;
		private var _stage : Stage;
		
		private var _width : int;
		private var _height : int;
		
		public var bitmap : Bitmap;
		
		// constructor

		public function WaterWorker(loader:LoaderInfo=null,giveAppPrivileges:Boolean = false)   {
			super(loader, giveAppPrivileges);
			addEventListener(WorkerEvent.MODE_CHANGED, onModeChange);
		}
		
		
		
		//////////////////////////////////////////////////////////////////////////////
		
		// prepare canvas to draw on both side
		
		final public function create(width:int = 0, height:int = 0, scale:Number = 1):void {
			
			// tell the worker to do the same 
			
			callWorker("create", arguments);
			
			_scale = scale;
			
			_width = width;
			_height = height;
			
			_canvas = new Sprite();
			_canvas.graphics.beginBitmapFill(new _sourceImage().bitmapData, null, true, false);
			_canvas.graphics.drawRect(0, 0, width, height);
			_canvas.graphics.endFill();
			_canvas.scrollRect = new Rectangle(0, 0, width, height);
			
			_bitmapdata = new BitmapData(width * _scale, height * _scale, false, 0);
			
			bitmap = new Bitmap(_bitmapdata);
			bitmap.smoothing = true;
			
			bitmap.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);			

			setScale(_scale);
		}
		
		final public function setScale(scale:Number):void {
			_scale = scale;
			bitmap.scaleX = bitmap.scaleY = 1 / (1 * _scale);
			_canvas.scaleX = _canvas.scaleY = _scale;
			if (_rippler) _rippler.destroy();
			_rippler = new Rippler(new Rectangle(0, 0, _width*_scale, _height*_scale), 60 * _scale, 6 * _scale);
		}
		
		final public function onAddedToStage(e:Event) : void {
			bitmap.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			bitmap.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			_stage = bitmap.stage;
			if(singleThreadMode) _stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_stage.addEventListener ( Event.DEACTIVATE, onDeactivate ); 
			start();
		}
		
		final public function onRemovedFromStage(e:Event) : void {
			stop();
			bitmap.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			bitmap.removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			if(singleThreadMode) _stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_stage.removeEventListener ( Event.ACTIVATE, onActivate ); 
			_stage.removeEventListener ( Event.DEACTIVATE, onDeactivate ); 
		}
		
		final private function onActivate ( e:Event ):void { 
			if(singleThreadMode) _stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			_stage.removeEventListener ( Event.ACTIVATE, onActivate ); 
			_stage.addEventListener ( Event.DEACTIVATE, onDeactivate );
			start();
		} 
		
		final private function onDeactivate ( e:Event ):void { 
			_stage.removeEventListener ( Event.DEACTIVATE, onDeactivate ); 
			_stage.addEventListener ( Event.ACTIVATE, onActivate ); 
			stop();
		}
		
        final private function onMouseMove(event : MouseEvent) : void {
			drawRipple(bitmap.mouseX * _scale, bitmap.mouseY * _scale);
        }		

		final public function start():void {
			if (!_started) {
				_started = true;
				if(singleThreadMode) _stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				else updateFrame();
			}
		}
		
		final public function stop():void {
			if (_started) {
				_started = false;
				if(singleThreadMode) _stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				_bitmapdata.applyFilter(_bitmapdata, _bitmapdata.rect, new Point(0, 0), new BlurFilter(2, 2, 3) );
			}
		}
		
		final public function drawRipple(x : int, y : int, size:int = 20) : void {
			if(callWorker("drawRipple", arguments)) return;
			_rippler.drawRipple(x, y, size * _scale, 1);
		}
		
		private function onEnterFrame(e:Event):void {
			updateFrame();
		}		
		
		final public function updateFrame(ba:ByteArray = null):void {
			if (singleThreadMode) renderWater();
			else {
				// water rendering loop using worker
				if (this.isPrimordial) {
					// do nothing if not started or deactived
					if (!_started) return;
					if (ba) _bitmapdata.setPixels(_bitmapdata.rect, ba);
					// call worker
					call("updateFrame");
				}
				else {
					renderWater();
					// call main
					call("updateFrame", [bmdToBytearray(_bitmapdata)]);
				}
			}
		}
		
		final private function renderWater():void {
			_bitmapdata.draw(_canvas, _canvas.transform.matrix);
			_rippler.render(_bitmapdata);			
		}
		
		final private function bmdToBytearray(bmd:BitmapData,dispose:Boolean=false) : ByteArray {
			var ba:ByteArray = new ByteArray;
			bmd.copyPixelsToByteArray(bmd.rect, ba);
			ba.position = 0;
			if (dispose) bmd.dispose();
			return ba;
		}
		
		final private function onModeChange(event:Event) : void {
			if (!_started) return;
			if (!singleThreadMode) {
				_stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				updateFrame();
			} else _stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		override public function destroy(callback:Function = null):void {
			_bitmapdata.dispose();
			if (this.isPrimordial) {
				
			} else {
				_rippler.destroy();
			}
			super.destroy(callback);
		}
	
	}
}
