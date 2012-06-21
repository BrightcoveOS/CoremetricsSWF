/**
 *
 *    @author     Sapient
 *    @copyright  " "
 *    @version    1.0
 *
 */

package {
	
	import com.brightcove.api.APIModules;
	import com.brightcove.api.CustomModule;
	import com.brightcove.api.dtos.RenditionAssetDTO;
	import com.brightcove.api.dtos.VideoCuePointDTO;
	import com.brightcove.api.dtos.VideoDTO;
	import com.brightcove.api.events.AdEvent;
	import com.brightcove.api.events.CuePointEvent;
	import com.brightcove.api.events.EmbedCodeEvent;
	import com.brightcove.api.events.ExperienceEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.MenuEvent;
	import com.brightcove.api.events.ShortenedLinkEvent;
	import com.brightcove.api.modules.AdvertisingModule;
	import com.brightcove.api.modules.CuePointsModule;
	import com.brightcove.api.modules.ExperienceModule;
	import com.brightcove.api.modules.MenuModule;
	import com.brightcove.api.modules.SocialModule;
	import com.brightcove.api.modules.VideoPlayerModule;
	import com.brightcove.opensource.CoremetricsEventsMap;
	import com.brightcove.opensource.DataBinder;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Video;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.utils.Timer;
	

	
	public class Coremetrics extends CustomModule
	{	
		private var _experienceModule:ExperienceModule;
		private var _videoPlayerModule:VideoPlayerModule;
		private var _advertisingModule:AdvertisingModule;
		private var _socialModule:SocialModule;
		private var _menuModule:MenuModule;
		private var _cuePointsModule:CuePointsModule;
		private var _mapEvents:CoremetricsEventsMap = new CoremetricsEventsMap();
		private var _dataBinder:DataBinder = new DataBinder();
		private var _debug:Boolean = false;
		private var _currentVideo:VideoDTO;
		private var _customID:String;
		private var _trackinginfo:Object;
		private var _currentVolume:Number;
		private var _currentRendition:RenditionAssetDTO;
		private var _storedTimeWatched:SharedObject = SharedObject.getLocal("previousVideo");
		private var _currentPosition:Number;
		private var _previousTimestamp:Number;
		private var _timeWatched:Number;
		private var _mediaBegin:Boolean = false;
		private var _mediaComplete:Boolean = false;
		private var _videoMuted:Boolean = false;
		private var _trackSeekForward:Boolean = false;
		private var _trackSeekBackward:Boolean = false;
		private var _positionBeforeSeek:Number;
		private var _seekCheckTimer:Timer = new Timer(1000);
		private var _mediaSeeking:Boolean = false;
		
	
		/**
		 *Constructor 
		 */	
		public function Coremetrics():void
		{
			trace("@project Coremetrics");
			trace("@author Sapient");
			trace("@version 1.0.0");
			Security.allowDomain('*');
			
		}
		
		/**
		 *Overriding Initialize function.This will startup the process.  
		 */	
		override protected function initialize():void
		{			
			
			//Modules
			_experienceModule = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
			_videoPlayerModule = player.getModule(APIModules.VIDEO_PLAYER) as VideoPlayerModule;
			_advertisingModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
			_socialModule = player.getModule(APIModules.SOCIAL) as SocialModule;
			_menuModule = player.getModule(APIModules.MENU) as MenuModule;
			_cuePointsModule = player.getModule(APIModules.CUE_POINTS) as CuePointsModule;
			
			//Initialization of some important variables
			setupEventListeners();	
			
			_currentVideo = _videoPlayerModule.getCurrentVideo();
			_currentVolume = _videoPlayerModule.getVolume();
			_debug = (getParamValue("debug") == "true") ? true : false;
			_storedTimeWatched.data.abandonedVideo = _currentVideo;
			
			var _trackinginfo:Object = findEventInformation("playerLoaded", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
			//Maps with XML.
			var xmlURL:String = getParamValue('eventsMap');
			
			if(xmlURL)
			{
				_mapEvents = new CoremetricsEventsMap(xmlURL);
				_mapEvents.addEventListener(Event.COMPLETE, onEventsMapParsed);
			}
			else
			{
				onEventsMapParsed(null);
			}
		}
		
		/**
		 *Setting Up Event Listeners.  
		 */	
		private function setupEventListeners():void
		{
			_experienceModule.addEventListener(ExperienceEvent.ENTER_FULLSCREEN, onEnterFullScreen);//EnterFullScreen
			_experienceModule.addEventListener(ExperienceEvent.EXIT_FULLSCREEN, onExitFullScreen);//ExitFullScreen
			_experienceModule.addEventListener(ExperienceEvent.ADDED_TO_STAGE, onAddedToStage);//AddedToStage
			_experienceModule.addEventListener(ExperienceEvent.MODULES_LOADED, onModulesLoaded);//ModulesLoaded
			_experienceModule.addEventListener(ExperienceEvent.TEMPLATE_LOADED, onTemplateLoaded);//TemplateLoaded
			_experienceModule.addEventListener(ExperienceEvent.TEMPLATE_READY, onTemplateReady);//TemplateReady
			_experienceModule.addEventListener(ExperienceEvent.USER_MESSAGE, onUserMessage);//UserMessage
			
			_videoPlayerModule.addEventListener(MediaEvent.CHANGE, onMediaChange);//MediaChange
			_videoPlayerModule.addEventListener(MediaEvent.BEGIN, onMediaBegin);//MediaBegin
			_videoPlayerModule.addEventListener(MediaEvent.PLAY, onMediaPlay);//MediaPlay
			_videoPlayerModule.addEventListener(MediaEvent.PROGRESS, onMediaProgress);//MediaProgress
			_videoPlayerModule.addEventListener(MediaEvent.SEEK, onMediaSeek);//MediaSeek
			_videoPlayerModule.addEventListener(MediaEvent.STOP, onMediaStop);//MediaStop
			_videoPlayerModule.addEventListener(MediaEvent.COMPLETE, onMediaComplete);//MediaComplete
			_videoPlayerModule.addEventListener(MediaEvent.MUTE_CHANGE, onMuteChange);//MuteChange
			_videoPlayerModule.addEventListener(MediaEvent.VOLUME_CHANGE, onVolumeChange);//VolumeChange
			_videoPlayerModule.addEventListener(MediaEvent.RENDITION_CHANGE_REQUEST, onRenditionChangeRequest);//RenditionChangeRequest
			_videoPlayerModule.addEventListener(MediaEvent.RENDITION_CHANGE_COMPLETE, onRenditionChangeComplete);//RenditionChangeComplete
			_videoPlayerModule.addEventListener(MediaEvent.BUFFER_BEGIN, onBufferBegin);//Buffer Begin
			_videoPlayerModule.addEventListener(MediaEvent.BUFFER_COMPLETE, onBufferComplete);//Buffer Complete
			_videoPlayerModule.addEventListener(MediaEvent.ERROR, onMediaError);//Media Error
			_videoPlayerModule.addEventListener(MediaEvent.EDGE, onMediaEdge);//Media Edge
			_videoPlayerModule.addEventListener(MediaEvent.SEEK_NOTIFY, onSeekNotify);//Media Seek Notify
			
			if(_advertisingModule)
			{
				_advertisingModule.addEventListener(AdEvent.AD_START, onAdStart);//AdStart
				_advertisingModule.addEventListener(AdEvent.AD_PAUSE, onAdPause);//AdPause
				_advertisingModule.addEventListener(AdEvent.AD_RESUME, onAdResume);//AdResume
				_advertisingModule.addEventListener(AdEvent.EXTERNAL_AD, onExternalAd);//ExternalAd
				_advertisingModule.addEventListener(AdEvent.AD_COMPLETE, onAdComplete);//AdComplete
				_advertisingModule.addEventListener(AdEvent.AD_CLICK, onAdClick);//AdClick
				_advertisingModule.addEventListener(AdEvent.AD_POSTROLLS_COMPLETE, onAdPostrollsComplete);//AdPostrollsComplete
				_advertisingModule.addEventListener(AdEvent.AD_PROGRESS, onAdProgress);//AdProgress
				_advertisingModule.addEventListener(AdEvent.AD_RECEIVED, onAdReceived);//AdReceived
				_advertisingModule.addEventListener(AdEvent.AD_RULES_READY, onAdRulesReady);//AdRulesReady
			}
			
			_socialModule.addEventListener(EmbedCodeEvent.EMBED_CODE_RETRIEVED, onEmbedCodeRetrieved);//EmbedCodeRetrieved
			_socialModule.addEventListener(ShortenedLinkEvent.LINK_GENERATED, onLinkGenerated);//LinkGenerated
			
			_menuModule.addEventListener(MenuEvent.COPY_CODE, onCopyCode);//CopyCode
			_menuModule.addEventListener(MenuEvent.COPY_LINK, onCopyLink);//CopyLink
			_menuModule.addEventListener(MenuEvent.BLOG_POST_CLICK, onBlogPostClick);//BlogPostClick
			_menuModule.addEventListener(MenuEvent.MENU_PAGE_OPEN, onMenuPageOpen);//MenuPageOpen
			_menuModule.addEventListener(MenuEvent.MENU_PAGE_CLOSE, onMenuPageClose);//MenuPageClose
			_menuModule.addEventListener(MenuEvent.SEND_EMAIL_CLICK, onSendEmailClick);//SendEmailClick
			_menuModule.addEventListener(MenuEvent.OVERLAY_MENU_OPEN, onOverlayMenuPageOpen);//OverlayMenuPageOpen
			_menuModule.addEventListener(MenuEvent.OVERLAY_MENU_CLOSE, onOverlayMenuPageClose);//OverlayMenuPageClose
			_menuModule.addEventListener(MenuEvent.OVERLAY_MENU_PLAY_CLICK, onOverlayMenuPageClick);//OverlayMenuPageClick
			_menuModule.addEventListener(MenuEvent.VIDEO_REQUEST, onVideoRequest);//VideoRequest
			
			_cuePointsModule.addEventListener(CuePointEvent.CUE, onCuePoint);//CuePoint
			
			
			_seekCheckTimer.addEventListener(TimerEvent.TIMER, onSeekCheckTimer);//SeekCheckTimer
			
		}
		
		/**
		 *Configure the Default values for Coremetrics.  
		 */	
		private function configureCoremetricsDefaults():void
		{
			//Coremetrics Details
			debug("Coremetrics ClientID:"+_mapEvents.coremetricsClientID);
			debug("Coremetrics VN2:"+_mapEvents.coremetricsVN2);
			debug("Coremetrics DCD:"+_mapEvents.coremetricsDCD);
			debug("Coremetrics Cookie Domain:"+_mapEvents.coremetricsCookieDomain);

}
		
		/**
		 *EXPERIENCE EVENTS
		 */	
		private function onEnterFullScreen(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("enterFullScreen", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onExitFullScreen(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("exitFullScreen", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAddedToStage(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("addedToStage", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onModulesLoaded(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("modulesLoaded", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onTemplateLoaded(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("templateLoaded", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onTemplateReady(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("templateReady", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onUserMessage(event:ExperienceEvent):void
		{
			var _trackinginfo:Object = findEventInformation("userMessage", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
	
		//----------------------End EXPERIENCE EVENTS------------------------
		
		/**
		 *VIDEO PLAYER EVENTS
		 */	
		private function onMediaChange(event:MediaEvent):void
		{
			_mediaBegin = false;
			_mediaComplete = false;
			updateInfoVideo(); 
		}
		
		private function onMediaBegin(event:MediaEvent):void
		{
			if(!_mediaBegin)
			{	
				updateInfoVideo();
				
				var _trackinginfo:Object = findEventInformation("mediaBegin", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
				
				_mediaBegin = true;
				_mediaComplete = false;
			}
		}
		
		private function onMediaPlay(event:MediaEvent):void
		{
			
			if(!_mediaBegin)
			{
				onMediaBegin(event);
			}
			else
			{
				var _trackinginfo:Object = findEventInformation("mediaResume", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
			}
		}
		
		private function onMediaProgress(event:MediaEvent):void
		{
			
			_currentPosition = event.position;
			updateTimeTracked();	
			/*This will track the media complete event when the user has watched 98% or more of the video.*/
			if(event.position/event.duration > .98 && !_mediaComplete)
			{
				onMediaComplete(event);
			}
			
			var _trackinginfo:Object = findEventInformation("mediaProgress", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
			
		}
		
		private function onMediaSeek(event:MediaEvent):void
		{
			if(!_positionBeforeSeek)
			{
				_positionBeforeSeek = _currentPosition;
			}
			if(event.position > _positionBeforeSeek)
			{
				_trackSeekForward = true;
				_trackSeekBackward = false;
			}
			else
			{
				_trackSeekForward = false;
				_trackSeekBackward = true;
			}
			_seekCheckTimer.stop();
			_seekCheckTimer.start();
		}
		
		private function onMediaStop(event:MediaEvent):void
		{
			if(!_mediaComplete)
			{
				var _trackinginfo:Object = findEventInformation("mediaPause", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
			}
		}
		
		private function onMediaComplete(event:MediaEvent):void
		{
			if(!_mediaComplete)
			{
				var _trackinginfo:Object = findEventInformation("mediaComplete", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
				_mediaBegin = false;
				_mediaComplete = true;
			}
			
		}
		
		private function onMuteChange(event:MediaEvent):void
		{
			var _trackinginfo:Object;
			
			if(_videoPlayerModule.isMuted())
			{
				_videoMuted = false;
				_trackinginfo = findEventInformation("mediaMuted", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
			}
			else
			{
				_videoMuted = true;
				_trackinginfo = findEventInformation("mediaUnmuted", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
			}
		}
		
		private function onVolumeChange(event:MediaEvent):void
		{
			_videoMuted = false;
			if(_videoPlayerModule.getVolume() !== _currentVolume) //have to check this, otherwise the event fires twice for some reason
			{
				_currentVolume = _videoPlayerModule.getVolume();
				var _trackinginfo:Object = findEventInformation("volumeChanged", _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
			}
		}
		
		private function onRenditionChangeRequest(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("renditionChangeRequest", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onRenditionChangeComplete(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("renditionChangeComplete", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
	
		private function onBufferBegin(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("bufferBegin", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onBufferComplete(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("bufferComplete", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onMediaEdge(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("mediaEdge", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onMediaError(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("mediaError", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onSeekNotify(event:MediaEvent):void
		{
			var _trackinginfo:Object = findEventInformation("seekNotify", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		
		
		
		//----------------------End VIDEO PLAYER EVENTS------------------------
		
		/**
		 *ADVERTISING EVENTS
		 */	
		private function onAdStart(event:AdEvent):void
		{			
			var _trackinginfo:Object = findEventInformation("adStart", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdPause(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adPause", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdResume(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adResume", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onExternalAd(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("externalAd", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdComplete(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adComplete", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdClick(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adClick", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdPostrollsComplete(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adPostrollsComplete", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdProgress(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adProgress", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdReceived(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adReceived", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onAdRulesReady(event:AdEvent):void
		{
			var _trackinginfo:Object = findEventInformation("adRulesReady", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		//----------------------End ADVERTISING EVENTS------------------------

		/**
		 *SOCIAL EVENTS
		 */
		private function onEmbedCodeRetrieved(event:EmbedCodeEvent):void
		{
			var _trackinginfo:Object = findEventInformation("embedCodeRetrieved", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onLinkGenerated(event:ShortenedLinkEvent):void
		{	
			var _trackinginfo:Object = findEventInformation("linkGenerated", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		//----------------------End SOCIAL EVENTS------------------------
		
		/**
		 *MENU EVENTS
		 */
		private function onCopyCode(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("codeCopied", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onCopyLink(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("linkCopied", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onBlogPostClick(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("blogPosted", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onMenuPageOpen(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("menuPageOpened", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onMenuPageClose(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("menuPageClosed", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onSendEmailClick(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("emailSent", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		private function onOverlayMenuPageOpen(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("overlayMenuOpen", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onOverlayMenuPageClose(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("overlayMenuClose", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onOverlayMenuPageClick(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("overlayMenuClick", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		private function onVideoRequest(event:MenuEvent):void
		{
			var _trackinginfo:Object = findEventInformation("videoRequest", _mapEvents.map, _currentVideo);
			trackEvent(_trackinginfo);
		}
		
		
		//----------------------End MENU EVENTS------------------------
		
		/**
		 *CUE POINT EVENTS
		 */	
		private function onCuePoint(event:CuePointEvent):void
		{
			var cuePoint:VideoCuePointDTO = event.cuePoint;
			var _trackinginfo:Object = {};
			
			if(cuePoint.type == 1 && cuePoint.name == "coremetrics-milestone")
			{   
				var metadataSplit:Array;
				if(cuePoint.metadata.indexOf('%') !== -1) //percentage
				{
					metadataSplit = cuePoint.metadata.split('%');
					_trackinginfo = findEventInformation("milestone", _mapEvents.map, _currentVideo, "percent", metadataSplit[0]);
					_cuePointsModule.removeCodeCuePointsAtTime(_currentVideo.id, cuePoint.time);
				}
				else if(cuePoint.metadata.indexOf('s') !== -1) //seconds
				{
					metadataSplit = cuePoint.metadata.split('s');
					_trackinginfo = findEventInformation("milestone", _mapEvents.map, _currentVideo, "time", metadataSplit[0]);
					_cuePointsModule.removeCodeCuePointsAtTime(_currentVideo.id, cuePoint.time);
					
				}
				trackEvent(_trackinginfo);
			}
		}
		//----------------------End CUE POINT EVENTS------------------------

		/**
		 *LOCAL OBJECT EVENTS
		 */	
		private function onEventsMapParsed(event:Event):void
		{
			
			
			configureCoremetricsDefaults();
		}
		
		private function onSeekCheckTimer(event:TimerEvent):void
		{
			if(_trackSeekBackward || _trackSeekForward)
			{
				var eventName:String = (_trackSeekForward) ? "seekForward" : "seekBackward";
				var _trackinginfo:Object = findEventInformation(eventName, _mapEvents.map, _currentVideo);
				trackEvent(_trackinginfo);
				//reset values
				_trackSeekForward = false;
				_trackSeekBackward = false;
				_positionBeforeSeek = new Number();
			}
			
			_seekCheckTimer.stop();
		}
		//----------------------End LOCAL OBJECT EVENTS------------------------
		
		/**
		 *Helper Functions 
		 */		
		
		 /*Sends Data to Coremetrics Server*/
		private function trackCoremetricsData(strData:String):void
		{
			var _url:String=_mapEvents.coremetricsDCD;
			var _tid:Number=15;
			var _clientID:Number=Number(_mapEvents.coremetricsClientID);
			var _DCM:String=_mapEvents.coremetricsCookieDomain;
			
			//url to send
			var _urlSend:String=_url+
				"/eluminate?tid="+_tid+
				"&ci="+_clientID+
				"&vn2="+_mapEvents.coremetricsVN2 +
				"&st=1209682762203&vn1=4.1.8&ec=UTF8&cg=enContent3"+
				"&ul="+_DCM+
				"&rf="+_DCM+
				strData;
			
			debug("URL String"+_urlSend);
			
			var imageLoader:Loader = new Loader();
			addChild(imageLoader);
			imageLoader.load(new URLRequest(_urlSend));
			
		}
		
		
		 /*Tracks Event*/
		private function trackEvent(objTrackingInfo:Object, mediaTrack:Boolean = true):void
		{			
			if(objTrackingInfo) //coremetrics won't send anything anyway, but I'm checking to make sure this isn't null just to be sure
			{
				setupSourceVariables(objTrackingInfo);
			}
		}
		
		/*Update Video Info*/	
		private function updateInfoVideo():void
		{
			_currentVideo = _videoPlayerModule.getCurrentVideo();
			_customID = getCustomVideoName(_currentVideo);
			if(!_mediaBegin) //we only want to call this once per video
			{
				cuePointCreation(_mapEvents.milestones, _currentVideo);
			}
		}
		
		/*Update Tracked Time*/	
		private function updateTimeTracked():void
		{
			var currentTimestamp:Number = new Date().getTime();
			var timeElapsed:Number = (currentTimestamp - _previousTimestamp)/1000;
			_previousTimestamp = currentTimestamp;
			if(timeElapsed < 2) 
			{
				_timeWatched += timeElapsed;
			} 
		}
		
		/*Setup Actionscript Video*/	
		private function setupSourceVariables(objTrackingInfo:Object):void
		{
			var _categoryName:String='';
			
			//if category name exists in custom field then pick from there
			if(_currentVideo.customFields['categoryname'])
			{
				_categoryName=_currentVideo.customFields['categoryname'];
			}
				//if not then pick from xml
			else
			{
				_categoryName=_mapEvents.coremetricsCategoryName;
			}
			
			var _attributes:String="&eid="+_currentVideo.id+"&ecat="+_categoryName+"&pflg=0";
		
			for(var trackType:Object in objTrackingInfo)
			{
				//takes the prop and tracks on the proper number and assigns the proper value
				if(trackType == 'prop')
				{
					for(var property:* in objTrackingInfo[trackType])
					{
						var propertyValue:String = objTrackingInfo[trackType][property]; //e.g. value for prop5
						_attributes=_attributes+"&e_a"+property+"="+propertyValue;
						
					}
				}
				
			}
		
			var _currentTime:String="&e_a49="+_currentPosition.toString();
			var _volume:String="&e_a50="+_currentVolume.toString();
			_attributes=_attributes+_currentTime+_volume;
			
			trackCoremetricsData(_attributes);
		}
		
		/*creates a cue point*/
		private function cuePointCreation(milestones:Array, video:VideoDTO):void
		{
			if(milestones)
			{
				var cuePoints:Array = new Array();
				for(var i:uint = 0; i < milestones.length; i++)
				{
					var milestone:Object = milestones[i];
					var cuePoint:Object = {};
					if(milestone.type == 'percent')
					{
						cuePoint = {
							type: 1, //code cue point
							name: "coremetrics-milestone",
							metadata: milestone.marker + "%", //percent
								time: (video.length/1000) * (milestone.marker/100)
						};
					}
					else if(milestone.type == 'time')
					{
						cuePoint = {
							type: 1, //code cue point
							name: "coremetrics-milestone",
							metadata: milestone.marker + "s", //seconds
								time: milestone.marker
						};
					}
					cuePoints.push(cuePoint);
				}
				//clear out existing coremetrics cue points if they're still around after replay
				var existingCuePoints:Array = _cuePointsModule.getCuePoints(video.id);
				if(existingCuePoints)
				{
					for(var j:uint = 0; j < existingCuePoints.length; j++)
					{
						var existingCuePoint:VideoCuePointDTO = existingCuePoints[j];
						if(existingCuePoint.type == 1 && existingCuePoint.name == 'coremetrics-milestone')
						{
							_cuePointsModule.removeCodeCuePointsAtTime(video.id, existingCuePoint.time);
						}
					}
				}
				_cuePointsModule.addCuePoints(video.id, cuePoints);
			}
		}
		
		/*finds Event Information*/	
		private function findEventInformation(eventName:String, map:Array, video:VideoDTO, milestoneType:String = null, milestoneMarker:uint = 0):Object
		{
		
			for(var i:uint = 0; i < map.length; i++)
			{
				//sets up shell object for the tracking info so we can easily add values to each inner object
				var eventInfo:Object = {
					prop: {},
					event: null
				};
				
				var props:Array = map[i].props;
				eventInfo.event = map[i].events; //just add the events as an array
				eventName = eventName.toLowerCase(); //if you have to trim this, it means you fat fingered something in the code somewhere
				var mappedEventName:String = trim(map[i].name.toLowerCase(), ' ');
				//if it's a milestone, head into the first inner if block. or enter if the argument name passed in matches the mapped event name
				if(eventName == "milestone" || eventName == mappedEventName)
				{
					if(eventName == "milestone")
					{
						for(var l:uint = 0; l < _mapEvents.milestones.length; l++)
						{
							var milestone:Object = _mapEvents.milestones[l];
							
							if(milestone.type.toLowerCase() == milestoneType.toLowerCase() && milestone.marker == milestoneMarker)
							{
								props = milestone.props;
								eventInfo.event = milestone.events;
								
								break;
							}							
						}
					}
					
					//add prop numbers as the key, and their value as the value
					for(var j:uint = 0; j < props.length; j++)
					{
						var prop:Object = props[j];						
						eventInfo.prop[prop.number] = _dataBinder.getValue(prop.value, _experienceModule, _currentVideo);
					}
					
					debug("Event Name:"+eventName);
					return eventInfo;
					
				}
			}
			return null;
		}
		
		/*	get Custom Video Name*/
		public function getCustomVideoName(video:VideoDTO):String
		{
			return video.id + " | " + video.displayName;
		}
		
		/*debugs*/
		private function debug(message:String):void
		{
			_experienceModule.debug("Brightcove-Coremetrics-Plugin:Debug  : " + message);
		}
		
		/*Get Params Value*/
		private function getParamValue(key:String):String
		{
			//1: check url params for the value
			var url:String = _experienceModule.getExperienceURL();
			if(url.indexOf("?") !== -1)
			{
				var urlParams:Array = url.split("?")[1].split("&");
				for(var i:uint = 0; i < urlParams.length; i++)
				{
					var keyValuePair:Array = urlParams[i].split("=");
					if(keyValuePair[0] == key)
					{
						return keyValuePair[1];
					}
				}
			}
			//2: check player params for the value
			var playerParam:String = _experienceModule.getPlayerParameter(key);
			if(playerParam)
			{
				return playerParam;
			}
			//3: check plugin params for the value
			var pluginParams:Object = LoaderInfo(this.root.loaderInfo).parameters;
			for(var param:String in pluginParams)
			{
				if(param == key)
				{
					return pluginParams[param];
				}
			}
			return null;
		}
		
		/**
		 *string helpers pulled from the AS3 docs
		 */	
	
		public function trim(str:String, char:String):String 
		{
			return trimBack(trimFront(str, char), char);
		}
		
		public function trimFront(str:String, char:String):String 
		{
			char = stringToCharacter(char);
			if(str.charAt(0) == char)
			{
				str = trimFront(str.substring(1), char);
			}
			
			return str;
		}
		
		public function trimBack(str:String, char:String):String 
		{
			char = stringToCharacter(char);
			
			if(str.charAt(str.length - 1) == char) 
			{
				str = trimBack(str.substring(0, str.length - 1), char);
			}
			return str;
		}
		
		public function stringToCharacter(str:String):String 
		{
			if(str.length == 1) 
			{
				return str;
			}
			return str.slice(0, 1);
		}
	}
}

/*End of Code*/