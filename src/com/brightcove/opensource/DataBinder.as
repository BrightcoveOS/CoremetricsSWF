/**
 *
 *    @author     Sapient
 *    @copyright  " "
 *    @version    1.0
 *
 */
package com.brightcove.opensource
{
	import com.brightcove.api.dtos.VideoDTO;
	import com.brightcove.api.modules.ExperienceModule;
	
	public class DataBinder
	{
		private var _currentVideo:VideoDTO;
		
		/**
		 *gets Value for the current Video and Experience from XML.  
		 */
		public function getValue(property:String, experienceModule:ExperienceModule, video:VideoDTO = null):String
		{
			if(property.indexOf("{") !== -1)
			{				
				var matches:Array = property.match(/\{.*?\}/g); 
				for(var i:uint = 0; i < matches.length; i++)
				{
					var match:String = matches[i];					
					var dataBindingValue:String = match.substring(1, match.length-1); //strip off the curly braces
					var propertySplit:Array = dataBindingValue.split('.');
					
					if(propertySplit[0].toLowerCase() == 'video')
					{
						property = property.replace(match, getVideoProperty(propertySplit, video));
					}
					else if(propertySplit[0].toLowerCase() == 'experience')
					{
						property = property.replace(match, getExperienceProperty(propertySplit, experienceModule));
					}
				}
			}
			
			return property; //if we didn't get anything data-bound, it returns what was passed in
		}
		
		/**
		 *gets Property value for the Video attribute.
		 */
		private function getVideoProperty(propertySplit:Array, video:VideoDTO):String
		{
			if(propertySplit[1].toLowerCase().indexOf('customfields[') !== -1)
			{
				var customFieldSplit:Array = propertySplit[1].split("'");
				var customFieldName:String = customFieldSplit[1].toLowerCase();
				
				return video.customFields[customFieldName];
			}
			else //not a custom field
			{
				return video[propertySplit[1]];
			}
				
			return null;
		}
		
		/**
		 *gets Property value for the Experience attribute. 
		 */
		private function getExperienceProperty(propertySplit:Array, experienceModule:ExperienceModule):String
		{
			var experienceProperty:String = propertySplit[1].toLowerCase();
			
			var str:String;

			switch(experienceProperty)
			{
				
				case 'publisherid':
					
					return experienceModule.getPublisherID().toString();
					
					break;
				
				case 'referrerurl':
					if(experienceModule.getReferrerURL()==null)
					{
					return null;
					}
					else
					{
					return experienceModule.getReferrerURL();
					}
					break;
				
				case 'usercountry':
					
					if(experienceModule.getUserCountry()==null)
					{
					return null;
					}
					else
					{
					return experienceModule.getUserCountry();
					}
					break;
				
				case 'url':
					if(experienceModule.getExperienceURL()==null)
					{
					return null;
					}
					else
					{
					return experienceModule.getExperienceURL();
					}
					break;	
				
				case 'playername':
					if(experienceModule.getPlayerName()==null)
					{
					return null;
					}
					else
					{
						return experienceModule.getPlayerName();
					}
					break;
				
				case 'id':
					
					return experienceModule.getExperienceID().toString();
					
					break;
				
				default:
					return null;
			}
			
			return null;
		}
		
		
		
	}
}