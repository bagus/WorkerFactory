package com.signt 
{
	/**
	 * Global Shared Data
	 * 
	 * @author Bagus
	 */
	public class GlobalData  {
		
		private static var _instances : Object = { };
		private var DATA : Object = { };
		
		public function GlobalData($blocker:SingletonBlocker) 
		{
			if ( $blocker == null ) 
			{
				throw new Error( "Public construction not allowed.  Use getInstance()" );
				}
		}
		public static function getInstance (key:String) : Object {
			if (!(key in _instances)) _instances[key] = new GlobalData( new SingletonBlocker() );
			return _instances[key].DATA;
		}
		public static function killInstance (key:String) : void {
			for (var id:String in _instances[key].data) 
				delete _instances[key].data[id];
			delete _instances[key];
		}		
		
	}

}
class SingletonBlocker
{

}