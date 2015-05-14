

// TODO REactify!!


//var directory = "/Users/sebastienvian/Desktop/photos-iphone/"
var CONSTS = {
   directory: "https://s3-eu-west-1.amazonaws.com/la-ballade/videos/",
}

///////////////////////////////
// Helpers
//////////////////////////////


// panToOffset: credit: https://gist.github.com/missinglink/7620340
L.Map.prototype.panToOffset = function (latlng, offset, options) {
    var x = this.latLngToContainerPoint(latlng).x - offset[0] / 2
    var y = this.latLngToContainerPoint(latlng).y - offset[1] / 2
    var point = this.containerPointToLatLng([x, y])
    return this.setView(point, this._zoom, { pan: options })
}

// cross browser getWidth: credit:
Element.prototype.getElementWidth = function() {
   if (typeof this.clip !== "undefined") {
      return this.clip.width;
   } else {
      if (this.style.pixelWidth) {
         return this.style.pixelWidth;
      } else {
         return this.offsetWidth;
      }
   }
};
Element.prototype.getElementHeight = function() {
   if (typeof this.clip !== "undefined") {
      return this.clip.height;
   } else {
      if (this.style.pixelHeight) {
         return this.style.pixelHeight;
      } else {
         return this.offsetHeight;
      }
}
};

//cookie reader. credit: http://stackoverflow.com/users/311572/jeffery-to
var readCookie = function (n) {return(n=new RegExp('(?:^|;\\s*)'+(''+n).replace(/[-[\]{}()*+?.,\\^$|#\s]/g,'\\$&')+'=([^;]*)').exec(document.cookie))&&n[1];}

var getPlayerOffset = function (  ){
   var safeMargin = 20;
   var position = {
      //width: document.getElementById('player').offsetWidth,
      //height: document.getElementById('player').offsetHeight
      width: document.getElementById('player').getElementWidth() + safeMargin,
      height: document.getElementById('player').getElementHeight() + safeMargin
   }
   var overall  = {
      width: window.innerWidth,
      height: window.innerHeight
   }


   var offset = {
      right: overall.width - position.width,
      bottom: overall.height - position.height
   }

   if ( offset.right > offset.bottom ) {
      console.log('diplay right');
      return [ position.width , 0 ];
   } else {
      console.log('display below');
      return [ 0 , position.height ];
   }

}




/////////////////////////////
//       Player
////////////////////////////

var Player = function (){
   this.init.apply(this, arguments);
};

Player.prototype = {
   init: function () {
      this.initPlayer();
      this.initLoader();

   },
   initPlayer: function (){
      this._player = document.getElementById('player');

      this._player.onclick = function ( e ){
         console.log('clicked');
         this.play();
      }

      this._player.onended = function ( e ){
         spinner.show();
         controller.next();
      }
      this._player.onplaying = function ( e ) {
         spinner.hide();
      }

      this._player.onwaiting = function ( e ){
         spinner.show();
      }
   },
   initLoader: function (){
      this._loader = document.getElementById('loader');

       setInterval( function (){
         if( this.buffered.length > 0 ) {
            var ratio = this.buffered.end( this.buffered.length - 1 ) / this.duration;
            //console.log(ratio, 'loaded');
            if( ratio > 0.99 ) {
               console.log(' 99% loaded');
               if(  !!this.onallloaded ) {
                  this.onallloaded();
                  this.onallloaded = null;
               }
            }
         }
       }.bind(this._loader), 500 )
   },

   loadVideo: function ( index, cb ){
      this._loader.src = videos.getPath( index );
      this._loader.load();

      // oncanplaythrough is not restrictive enought we would like the playing to start when the whole video is loaded..
      // onprogress looks like a better solution ( > 0.99 ) but cannot make it work... still digging
      //this._loader.oncanplaythrough  = cb;
      //
      this._loader.onallloaded = cb
      //this._loader.onloadeddata = function ( e ){
         ////Check if videos is fully loaded ( already in the cache ) in this case the onprogress event won't be triggered. #IhateHTML5VideoAPI
         //var isFullyLoaded =  ( this.buffered.length > 0 )  && ( this.buffered.end( this.buffered.length - 1 ) == this.duration );
         //if ( !isFullyLoaded ) {
            //return;
         //} else {
            //this.onprogress = null;
            //console.log('fully loaded');
            //( !!cb )? cb() : null;
         //}
      //}


   },

   playVideo: function ( video ){
     try {
        if( video.loaded ) {
           console.log('video already loaded');
           this._player.src = videos.getPath( video );
           this._player.play();
           this.loadVideo( video.index + 1 );
        } else {
           console.log('preloading video');
           // loadVideo with cb
           this.loadVideo( video.index , function (e){

              //console.log('ok loaded');
              video.loaded = true;
              this.playVideo( video );

           }.bind(this));
        }
      } catch(err) {
         console.warn('video not found: skipping')
      }
   },

   clear: function () {
      this._player.src = "";
      this._loader.src = "";
   }

}


/////////////////////////////////////
//     DataSource
/////////////////////////////////////

var VideoDataSource = function() {};
VideoDataSource.prototype = {
   all: function (){
      return this._raw_data;
   },
   init: function ( geoJSON ){
      // this should not be here..
      this._raw_data =  _.map( geoJSON.features , function ( f ){ return f.properties;} );

   },
   findByIndex: function ( index ){
      return _.find( this._raw_data, function ( properties ){ return properties.index == index } );
   },

   getPath: function( index_or_video ) {
      var video = ( !!index_or_video.index )? index_or_video : this.findByIndex( index_or_video );
      //return video.path;
      return CONSTS.directory + video.name + "_35.mp4";
   },

   markAsLoaded: function ( index ){
      this.findByIndex( controller.current + 1 ).loaded = true;
   }
}


//////////////////////////////
//      Controller
/////////////////////////////
var Controller = function (){
   this.init.apply(this, arguments);
};
Controller.prototype = {
   current: 1,
   init: function() {
      this.player = new Player();
      this.map = new Map( function ( geoJSON ){
          videos.init( geoJSON );
          this.play();
      }.bind( this ));
   },

   play: function ( index ){
     if( !index ) {
        index = this._getCurrent();
     } else {
        this.player.clear();
     }

     var video = videos.findByIndex( index );
     this._setCurrent(video.index);

     this.player.playVideo( video );
     this.map.highlight( video );
   },

   next: function (){
      this.current++;
      this.play();
   },

   pause: function (){},

   _setCurrent: function ( index ){
      this.current = index;
      // still to be tested
      document.cookie = 'last_read_video='+ index;
      console.log( document.cookie );
   },

   _getCurrent: function (){
      if( this.current != 1 ) {
         return this.current;
      }

      var current = readCookie('last_read_video');

      if ( !!current ) {
         return current;
      } else {
         return this.current;
      }
   }

};


/////////////////////////////////
//       Map
////////////////////////////////

var Map = function (){
   this.init.apply(this, arguments);
};

Map.prototype =  {
   mapName: 'stanbienaives.l752j3lk',
   accessToken: 'pk.eyJ1Ijoic3RhbmJpZW5haXZlcyIsImEiOiJLREd2TFJrIn0.GM-VhP8yVgBzWrJrMb_8Fw',
   center_map: true,
   simple_center: true,
   init: function( cb ) {

      // initializing map
      this._map = L.mapbox.map.call( this, 'map', this.mapName, {
         accessToken: this.accessToken
         //inertiaDeceleration: 100000,
         //inertiaMaxSpeed: 100,
      })

      this._map.setZoom(3);

      // Retrive geoJSON from mapbox when ready
      // TODO: better to dynamically fill up from url?: https://www.mapbox.com/mapbox.js/example/v1.0.0/geojson-marker-from-url/
      this._map.featureLayer.on('ready', function(e) {

          this.geoJSON = this._map.featureLayer.toGeoJSON()
          this.setLayer();
          cb( this.geoJSON );

      }.bind(this));

      //desactivate map centering if user zoom out
      this._map.on('dragstart', function () {

         this.center_map = false;
         // reactivate center_map after 20sec
         setTimeout( function ( ){
            this.center_map = true;
         }.bind(this), 20000 );

      }.bind(this));

   },
   setLayer: function () {

      if( !!this.geoJSON ) {
         this._map.featureLayer.setGeoJSON( this.geoJSON );
      }
      this._map.featureLayer.eachLayer(function(marker) {

        marker.on('click', function ( e ){
           console.log('clicked');
           console.log( marker.feature.properties.name );
           controller.play( marker.feature.properties.index );
           this.center_map = true;
        });

      });

   },


   highlight: function( video ) {
     this._changePinColor( video.index );
     this._centerMap( video.position , video.index);
   },

   _changePinColor: function ( index ){

      _.each( this.geoJSON.features , function ( f ){
         f.properties['marker-color'] = '#bbb'
         f.properties['marker-size'] = 'medium'
         if( f.properties.index == index ) {
            f.properties['marker-color'] = '#ff8888'
            f.properties['marker-size'] = 'large'
         }
      });
      this.setLayer( this.geoJSON );
   },

   _centerMap: function ( position, index ){
      if( !this.center_map ) {
         return;
      }

      ( position.latitude )? position.lat = position.latitude : null;
      ( position.longitude )? position.lon = position.longitude : null;

      if( this.simple_center ){
         this._map.panToOffset( position, getPlayerOffset(), {
            animate: true,
            duration: 1
         });
         return;
      }

      //  automated centering #overkill
      // fit map to last two points then zoom in
      if( !!index && index !== 1 ) {
         var previous_position = videos.findByIndex( index - 1 );
         previous_position = previous_position.position;

         if ( !!previous_position ) {
            ( previous_position.latitude )? previous_position.lat = previous_position.latitude : null;
            ( previous_position.longitude )? previous_position.lon = previous_position.longitude : null;
            var bounds = [ position, previous_position];

            // if the targe pin is inside the bounds then simply center it
            if(  this._map.getBounds().contains( [position.lat, position.lon] ) && this._map.getZoom() >= 5 ) {
               //this._map.panTo( position, {
                  //animate: true,
                  //duration: 1
               //});
               this._map.panToOffset( position, getPlayerOffset(), {
                  animate: true,
                  duration: 1
               });
            } else {
               // do not fit if distance between points is too small
               this._map.fitBounds(bounds, {
                  paddingTopLeft: getPlayerOffset(),
                  animate: true,
                  duration: 1000,
                  //zoom: {
                     //animate: true,
                     //duration: 1
                  //},
                  //pan: {
                     //animate: true,
                     //duration: 1
                  //}
               });
               console.log( 'fitted' );
            }
         }
      }
   }
}



////////////////////////////////
//     loader
///////////////////////////////
var Loader = function (){
   this.init.apply(this,arguments);
}

Loader.prototype = {
   init: function() {
      this._spinner = document.getElementById('spinner');

      this._spinner.onclick = function ( e ){
         // delegate click to player
         document.getElementById('player').click();
      }

      this.show();
   },

   show: function (){
      this._spinner.style.display = 'block';
   },

   hide: function (){
      this._spinner.style.display = 'none';
   }
}




/////////////////////////////////
//     initializing
/////////////////////////////////


var spinner = new Loader();
var videos = new VideoDataSource();
var controller = new Controller();
