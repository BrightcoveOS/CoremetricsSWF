About
=====

This project provides a Flash plug-in for reporting events from within Brightcove video players to Coremetrics. Reports can be rolled up using the Coremetrics Server. It can be used out-of-the-box or as a jumping off point for customizing your analytics plug-in.By setting up an XML file, you can access all of the necessary details of client and domain details that fire inside the Brightcove player. You can configure that XML file to pull from any of the available video fields and player properties (see full list below), giving you much greater control over the data in your reports.Please note that by doing it this way, you're introducing the risk of latency. If the file doesn't load up in time and the video starts, the tracking methods will not have initialized properly and information won't be tracked for that viewing. With that in mind, please make sure that if you're going to use this method to host the XML file on a content delivery network (CDN) to mitigate the risk of latency.


Setup
=====
There are two methods to getting your plug-in ready. The recommended option is to modify the events_map.xml file to match your requirements and then compile your own SWF. That sounds scarier than it really is. All you need is a copy of FlashBuilder (and you can get a free trial from Adobe https://www.adobe.com/cfusion/tdrc/index.cfm?product=flash_builder) and you can follow the instructions below. However, if you're really averse to that or just want to get something up and running quickly, you can pass in your events map XML file as a URL parameter (there are a few different options for how to pass that in - see below). With that in mind, you can send this information by HTML page using `<param name>` or function parameters.


Recommended: Creating Your Custom SWF
-------------------------------------
If you want to eliminate latency problems by compiling your own SWF, or if you want to make modifications to the SWF/codebase, follow these steps:

1.  Import the project into either FlexBuilder or FlashBuilder. Go to File > Import... > and under General choose "Existing Projects into Workspace." Choose the location of the project you downloaded from the **XYZ location**page.
2.  Modify the events_map.xml inside the assets folder to match your needs. See below for more instructions.
3.  Compile the SWF by using "Export Release Build..." under the Projects menu to get an optimized file size.
4.  Upload the SWF to a server that's URL addressable and make note of the URL.
5.  Log in to your Brightcove account.
6.  Edit your Brightcove player and in the **Settings > Plugin** tab to pass the URL for the Plugin swf that was generated.
7.  Save your player changes.
8.  Follow the steps below to get the code:  
9.  Click **Get Code** button and select HTML to embed. Select the option Copy Code and the code for plugin will be available for use.

After you are done you can view the Video file as it sends attributes to
the Coremetrics Server on play, pause, resume, and completion of video.
Test it, by logging to Coremetrics ITT Test Tool or Tag Bar Plugin to
see the tags that you just sent


Optional: Using the Existing SWF 
--------------------------------
If you don't want to compile your own SWF, follow these steps (please keep in mind potential latency issues - see above):

1. Choose the latest download from the **XYZ location** page.
2. Modify the events_map.xml inside the assets folder to match your
needs.  See below for more instructions. Upload both the SWF file and **events_map.xml** file to a server that's URL addressable; make note of those URLs.
3. At this stage you can add the reference to your event map XML file.

-  **Recommended**: Add `?eventsMap=http://mydomain.com/my-events-map.xml` to the URL of the SWF file (http://mydomain.com/my-events-map.xml will be replaced  with the location of your events map XML file). For example, http://mydomain.com/CoremetricsSWF.swf?eventsMap=http://mydomain.com/my-events-map.xml
-   If you are using a javascript publishing code for the player, you could specify a parameter in the JavaScript as `<paramname="eventsMap"value="http://mydomain.com/my-events-map.xml"/>`You could also use this method to override the XML file specified with the above method.
-   It's doubtful you'll use this option for anything other than testing, but you can also pass in your events map XML file as a parameter to the URL of the page. Similar to the recommended option, you would append `?eventsMap=http://mydomain.com/my-events-map.xml` to the current URL in the browser's address bar. This option will override the above two methods if either or both are being used.

4. Log in to your Brightcove account.

5. Edit your Brightcove player and in the **Settings > Plugin** tab pass the URL for the Plugin swf and include a reference to the event map XML file as described above. 

6. Save your player changes.


Setting Up Your Events Map XML File 
-----------------------------------
Included in each zip on the location [project's downloads page](https://github.com/BrightcoveOS/CoremetricsSWF/downloads) page is a sample `events\_map.xml` file.  If you’re using the recommended setup option above, do not change the name of the file or change its location from the assets folder. Otherwise, the name of the file can be changed.  All of the available events that you can tap into are in the sample XML file. All event nodes existing in the xml will track by default the 4 mandatory attributes – video id, category name, current time stamp and volume. User can remove the event nodes in case he does not want to track them.  


#### Account Level Settings

At the top of the sample XML file, you’ll see a section called initialization.  Inside of that is where you can specify your Coremetrics parameters.  If you’re not sure where to find that information, you can check with your IBM Coremetrics support team. However below are the Coremetrics parameters with their possible values for reference. Coremetrics tag can be passed this way:

`<initialization>`
`<clientID>[CoremetricsAcc ID]</clientID>`
`<VN2>e4.0</VN2>`    
`<DCD>Data Collection Domain </DCD>`
`<cookieDomain> Cookie Domain </cookieDomain>`
`<categoryName> Video Category Name </categoryName>`
`</initialization>`

Detailed Explanation:

1. ClientID: Default Coremetrics Client ID.If you want to send data to
multiple coremetrics account then you must have to give multiple Client
IDs. This way:

`<clientID>11111111;99999999</clientID>`

2. VN2: VN2 is the parameter which defines where we are sending the data.
Default value is ”e4.0” for sending the data. For Mobile the value
should be “mobile”    

3. DCD: DCD defines Data Collection Domain. Default value of domain is:

`<DCD>http://testdata.coremetrics.com</DCD>`

4. cookieDomain: It defined the domain from where we are sending the
data. It’s the website of your domain normally.
`<cookieDomain>www.sapient.com</cookieDomain>`

5. categoryName: Default  Category of Videos.
`<categoryName> Brightcove Videos </categoryName>`



#### Events
In the sample file, you'll see a long list of events. Each event entry can have any number of **prop** XML nodes inside of it. For **prop**, the **number** attribute will map to that particular prop, and the value attribute will get assigned to those props. For instance, `<prop number="3" value="{video.displayName}" />` will convert to **prop3= My Video Name** ("My Video Name" is an example of what the video's name could be). 

*****Note 1:  
All the nodes in the xml file would be sent based on the number that is
defined on the prop tag of it. For example:


`<event name="mediaPause">`
         `<prop number="2" value="{experience.referrerURL}" />`
		`<prop number="1" value="{experience.publisherID}" />`
		`<prop number="3" value="{experience.userCountry}" />`

`</event>`

This will send the details to the coremetrics server by matching with
the sequence of number such as, 

1->PublisherID

2->ReferrerURL

3->userCountry


*****Note 2:
If the user wants to send attribute 1 in position 1 and attribute 2 in
position 4, then he simply adds two nodes and changes the number and
value in it. For example:


`<prop number="1" value="Event Name: Media Complete" \>`
`<prop number="4" value="ExpID:{experience.id}" \>`

*****Note 3:
The list can have a maximum of 48 entries/props which can be used to track events

*****Note 4
No element name or element category may be over 50 characters in length
No event attribute field may be over 100 characters in length


Current Supported Data Binding Fields
=====================================

If you want to use data-binding, make sure to surround the below values with curly braces. You can even bind multiple fields for the same prop. See the events\_map.xml sample file for an example. When data-binding to custom fields, you'll be using the internal name gets automatically created when you make the custom field. If you're unsure what that internal name is, please check the 'Video Fields' section under your account settings in the Brightcove Studio.


Experience Data-Bindings
------------------------
*   experience.playerName : The name of the player the plugin is currently being server from. 
*   experience.url : The current URL of the page. This may not be available if using the HTML embed code. 
*   experience.id : The ID of the player. 
*   experience.publisherID : The ID of the publisher to which the media item belongs. 
*   experience.referrerURL : The url of the referrer page where the player is loaded. 
*   experience.userCountry : The country the user is coming from. 


Video Data-Bindings
-------------------
*   video.adKeys : Key/value pairs appended to any ad requests during media's playback. 
*   video.customFields['customfieldname'] : Publisher-defined fields for  media. 'customfieldname' would be the internal name of the custom field you wish to use. 
*   video.displayName : Name of media item in the player. 
*   video.economics : Flag indicating if ads are permitted for this media item. 
*   video.id : Unique Brightcove ID for the media item. 
*   video.length : The duration on the media item in milliseconds. 
*   video.lineupId : The ID of the media collection (ie playlist) in the player containing the media, if any. 
*   video.linkText : The text for a related link for the media item. 
*   video.linkURL : The URL for a related link for the media item. 
*   video.longDescription : Longer text description of the media item. 
*   video.publisherId : The ID of the publisher to which the media item belongs. 
*   video.referenceId : Publisher-defined ID for the media item. 
*   video.shortDescription : Short text description of the media item. 
*   video.thumbnailURL : URL of the thumbnail image for the media item. 


**Events Lists:**

 **Experience Events:**
-   EnterFullScreen
-   ExitFullScreen
-   ModulesLoaded
-   AddedToStage
-   TemplateLoaded
-   TemplateReady
-   UserMessage

**Media Events:**
-   MediaChange
-   MediaBegin
-   MediaPlay
-   MediaProgress
-   MediaSeek
-   MediaStop
-   MediaComplete
-   MuteChange
-   VolumeChange
-   MediaRenditionChangeRequest
-   MediaRenditionChangeComplete
-   BufferBegin
-   BufferComplete
-   MediaEdge
-   MediaError
-   MediaSeekNotify

 **Advertising Events:**
-   AdStart
-   AdPause
-   AdResume
-   ExternalAd
-   AdComplete
-   AdClick
-   AdPostrollsComplete
-   AdProgress
-   AdReceived
-   AdRulesReady

  **Social Events:**
-   EmbedCodeRetrieved
-   LinkGenerated

   **Menu Events:**
-   CopyCode
-   CopyLink
-   BlogPostClick
-   MenuPageOpen
-   MenuPageClose
-   SendEmailClick
-   OverlayMenuPageOpen
-   OverlayMenuPageClose
-   OverlayMenuPageClick
-   VideoRequest

 **Cue Point Events:**
 -   CuePoint
 

**Pre-Configured (in code) Fields:**

Following fields are pre-configured in the code and cannot be configured (added or removed) in XML. 
-   **Video ID**: Video ID is the unique identifier of the Video as stored in Brightcove .This is the mandatory field which is passed  with embed tag. 

The value for this field will go in the **Element ID** column in Coremetrics.
-   **Current Time Stamp**: The current time position of the video. Value for this filed is populated in the 49^th^ position in the 50 attribute list.
-   **Volume**: Current volume of the video being run. Value for this filed is populated in the 50^th^ position in the 50 attributes list.

Following fields are mandatory and the default value of which can be configured in XML. 
-   **Category Name**: The element category is pulled from the custom field categoryName from the brightcove account. Preferably, this custom field should be added in the Brightcove account as a mandatory field. If its defined as non-mandatory field in brightcove then, the default string “Brightcove video” (pulled from xml) is used. Since this is being pulled from XML, it can be modified. For example: the default value can be changed from “Brightcove video” to “football league video” in the `events\_map.xml` as `<categoryName>Football league video</categoryName>`.  
Note: don’t’ keep this node blank. This is the mandatory field which required to be is passed with embed tag. The value for this field will go in the **Element Category** column of Coremetrics.


