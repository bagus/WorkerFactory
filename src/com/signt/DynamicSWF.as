package com.signt {
	
    /** 
     * 
     * The DynamicSWF is a class for generating swf bytes code from defined classname
     * 
	 * @author Bagus
     * @mail bagus@signt.com
     * 
     */	 
	
	import com.codeazur.as3swf.*;
	import com.codeazur.as3swf.data.*;
	import com.codeazur.as3swf.tags.*;
	
	import flash.utils.ByteArray;

	public class DynamicSWF
	{
		
		/**
		 * Creates a Dynamic SWF from defined Class name.
		 * @param className the Class to create
		 * @param bytes SWF ByteArray which must contain the Class definition (usually loaderInfo.bytes)
		 * @return the new SWF ByteArray
		 */
		
		public static function fromClass(className:String, bytes:ByteArray):ByteArray {
			var swf:SWF = new SWF(bytes);
			var tags:Vector.<ITag> = swf.tags;
			for (var i:int = 0; i < tags.length; i++) {
				if (tags[i] is TagSymbolClass) {
					for each (var symbol:SWFSymbol in (tags[i] as TagSymbolClass).symbols) {
						if (symbol.tagId == 0) {
							symbol.name = className;
							var swfBytes:ByteArray = new ByteArray();
							swf.publish(swfBytes);
							swfBytes.position = 0;
							return swfBytes;	
						}
					}
				}
			}
			return null;
		}
	}
}