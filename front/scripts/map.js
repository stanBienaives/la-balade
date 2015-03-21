

// TODO REactify!!


//var directory = "/Users/sebastienvian/Desktop/photos-iphone/"
//var directory = "https://s3-eu-west-1.amazonaws.com/la-ballade/videos/"


var mapName = 'stanbienaives.l752j3lk'

var map = L.mapbox.map('map', mapName )


var data;


var video = document.getElementsByTagName('video')[0];

video.onended = function (e){
   playNext();
};


var current_video = 1;

map.featureLayer.on('ready', function(e) {
    //document.getElementById('open-popup').onclick = clickButton;
    // local store datas
    data = _.map( map.featureLayer.toGeoJSON().features , function ( f ){ return f.properties;} );


    playVideoFromIndex(getCurrentVideo());


    map.featureLayer.eachLayer(function(marker) {
      marker.on('click', function ( e ){
         console.log('clicked');
         console.log( marker.feature.properties.name );
         playVideo( marker.feature.properties );
      });
    });
});



// play video
var playVideo  = function ( properties ){
  centerMap( properties.position ); 
   //startVideo( directory +  properties.name );
  startVideo( properties.path );
  // store current_video in cookie
  setCurrentVideo(properties.index);
};

// read specific video
var playVideoFromIndex = function ( index ){
  props  = _.find( data, function ( properties ){ return properties.index == index } );
  playVideo( props );
};


// read next
var playNext = function (){
   current_video++;
   playVideoFromIndex( current_video );
};


// center map 
var centerMap = function ( position ){
   ( position.latitude )? position.lat = position.latitude : null;
   ( position.longitude )? position.lon = position.longitude : null;
   // position format: { lat: 'xxx' , lon: 'xxx' }
   map.panTo( position );
};


// play video
var startVideo = function ( src ){
   document.querySelector("#video").src = src;
};

var setCurrentVideo = function ( index ){
  current_video = index;
  document.cookie = 'last_read_video='+ index;
  console.log( document.cookie );
};

var getCurrentVideo = function ( index ){
   var cookie = document.cookie
   console.log( cookie );
   if ( cookie !== '' ) {
      return cookie.split('=')[1];
   } else {
      return current_video;
   }
};

