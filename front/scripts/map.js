

// TODO REactify!!


//var directory = "/Users/sebastienvian/Desktop/photos-iphone/"
var directory = "https://s3-eu-west-1.amazonaws.com/la-ballade/videos/"


var mapName = 'stanbienaives.l752j3lk'

var map = L.mapbox.map('map', mapName, {
   accessToken: 'pk.eyJ1Ijoic3RhbmJpZW5haXZlcyIsImEiOiJLREd2TFJrIn0.GM-VhP8yVgBzWrJrMb_8Fw',
   //inertiaDeceleration: 100000,
   //inertiaMaxSpeed: 100,
   
})

var geoJSON;
var raw_data;

var center_map = true;


var video = document.getElementsByTagName('video')[0];

video.onended = function (e){
   playNext();
};


var current_video = 1;

//dynamically add videos to map
//map.featureLayer.loadURL('../videos.json').addTo(map);

map.featureLayer.on('ready', function(e) {
    //document.getElementById('open-popup').onclick = clickButton;
    // local store raw_datas

    geoJSON = map.featureLayer.toGeoJSON()
    raw_data = _.map( geoJSON.features , function ( f ){ return f.properties;} );


    setLayer();
    playVideoFromIndex(getCurrentVideo());


});


//desactivate map centering if user zoom out
map.on('dragstart', function (  ){
   
   center_map = false;
});



// play video
var playVideo  = function ( properties ){
  changePinColor( properties.index );
  centerMap( properties.position , properties.index); 
   startVideo( directory +  properties.name );
  //startVideo( properties.path );
  // store current_video in cookie
  setCurrentVideo(properties.index);
};

// read specific video
var playVideoFromIndex = function ( index ){
  props  = _.find( raw_data, function ( properties ){ return properties.index == index } );
  playVideo( props );
};


// read next
var playNext = function (){
   current_video++;
   playVideoFromIndex( current_video );
};


// center map 
var centerMap = function ( position, index ){
   if( !center_map ) {
      return;
   }
   ( position.latitude )? position.lat = position.latitude : null;
   ( position.longitude )? position.lon = position.longitude : null;
   // fit map to last two points then zoom in
   if( !!index && index !== 1 ) {
      previous_position = _.find( raw_data, function( d ) { return d.index == index - 1; } );
      previous_position = previous_position.position;
      console.log( previous_position );
      //map.setZoom(30);
      if ( !!previous_position ) {
         ( previous_position.latitude )? previous_position.lat = previous_position.latitude : null;
         ( previous_position.longitude )? previous_position.lon = previous_position.longitude : null;
         var bounds = [ position, previous_position];
         console.log( bounds );

         // if the targe pin is inside the bounds then simply center it
         if(  map.getBounds().contains( [position.lat, position.lon] ) && map.getZoom() >= 10 ) {
            map.panTo( position, {
               animate: true,
               duration: 1
            });
         } else {
            // do not fit if distance between points is too small
            map.fitBounds(bounds, { 
               paddingTopLeft: [ 40, 400 ],
               animate: true,
               duration: 1,
               zoom: {
                  animate: true,
                  duration: 1
               },
               //pan: {
                  //animate: true,
                  //duration: 1
               //}
            });
         }
      }
   } 
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

var changePinColor = function ( index ){
   _.each( geoJSON.features , function ( f ){
      f.properties['marker-color'] = '#bbb'
      f.properties['marker-size'] = 'medium'
      if( f.properties.index == index ) {
         f.properties['marker-color'] = '#ff8888'
         f.properties['marker-size'] = 'large'
      }
   });
   setLayer( geoJSON );
}

var setLayer = function ( geoJSON ){
   if( !!geoJSON ) {
      map.featureLayer.setGeoJSON( geoJSON );
   }
   map.featureLayer.eachLayer(function(marker) {
     marker.on('click', function ( e ){
        console.log('clicked');
        console.log( marker.feature.properties.name );
        playVideo( marker.feature.properties );
        center_map = true;
     });
   });

}

