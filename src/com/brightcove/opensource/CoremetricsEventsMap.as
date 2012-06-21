/**
 *
 *    @author     Sapient
 *    @copyright  " "
 *    @version    1.0
 *
 */
package com.brightcove.opensource
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class CoremetricsEventsMap extends EventDispatcher
	{
		private var _map:Array = new Array();
		private var _milestones:Array = new Array();
		
		//coremetrics account from xml
		public var coremetricsClientID:String;
		public var coremetricsVN2:String;
		public var coremetricsDCD:String;
		public var coremetricsCookieDomain:String;
		public var coremetricsCategoryName:String;
		
		[Embed(source="../assets/events_map.xml", mimeType="application/octet-stream")]
		protected const EventsMap:Class;

		/**
		 *Constructor that loads XML.
		 */
		public function CoremetricsEventsMap(xmlFileURL:String = null)
		{
			if(xmlFileURL)
			{
				var request:URLRequest = new URLRequest(xmlFileURL);
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onXMLFileLoaded);
				loader.load(request);
			}
			else
			{
				var byteArray:ByteArray = (new EventsMap()) as ByteArray;
				var bytes:String = byteArray.readUTFBytes(byteArray.length);
				var eventsMapXML:XML = new XML(bytes);
				eventsMapXML.ignoreWhitespace = true;
				
				parseAccountInfo(eventsMapXML);
				parseEventsMap(eventsMapXML);
				
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		/**
		XML Loaded
		 */
		private function onXMLFileLoaded(event:Event):void
		{
			var eventsMapXML:XML = new XML(event.target.data);
			parseAccountInfo(eventsMapXML);
			parseEventsMap(eventsMapXML);
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 *Parse Account Info from XML.
		 */
		private function parseAccountInfo(eventsMap:XML):void
		{
			//coremetrics
			coremetricsClientID=eventsMap.initialization.clientID;
			coremetricsVN2=eventsMap.initialization.VN2;
			coremetricsDCD=eventsMap.initialization.DCD;
			coremetricsCookieDomain=eventsMap.initialization.cookieDomain;
			coremetricsCategoryName=eventsMap.initialization.categoryName;
			
		}
		/**
		 *Maps Event in XML.
		 */
		private function parseEventsMap(eventsMap:XML):void
		{
			for(var node:String in eventsMap.events.event)
			{
				var event:XML = eventsMap.events.event[node];
				
				var eventName:String = event.@name;
				var propsXML:XMLList = event.prop;
				var eventsXML:XMLList = event.eventNumbers;
				
				var props:Array = new Array();
				for(var j:uint = 0; j < propsXML.length(); j++)
				{
					var propXML:XML = propsXML[j];
				
					props.push({
						number: propXML.@number,
						value: propXML.@value 
					});
				}
				
				var events:Array = new Array();
				for(var k:uint = 0; k < eventsXML.length(); k++)
				{
					var eventXML:XML = eventsXML[k];
				
					events.push(eventXML.@value);
				}
				
				var eventInfo:Object = {
					name: eventName,
					props: props,
					events: events
				};
				
				if(eventName == 'milestone')
				{
					var milestone:Object = {
						props: props,
						events: events,
						type: event.@type,
						marker: event.@value
					};
					
					_milestones.push(milestone);
				}
				
				_map.push(eventInfo);
			}
		}
		
		/**
		 *set map.
		 */
		public function get map():Array
		{
			return _map;
		}
		
		/**
		 *get Milestone.
		 */
		public function get milestones():Array
		{
			return _milestones;
		}
	}
}
/*End of Code*/