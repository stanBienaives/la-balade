
var player = document.getElementById('player');
var loader = document.getElementById('loader');


var videos = [
   { video: "IMG_0765.MOV_35.mp4" },
   { video: "IMG_0634.MOV_35.mp4"},
   { video: "IMG_1217.MOV_35.mp4"},
   { video: "IMG_1229.MOV_35.mp4"},
   { video: "IMG_0765.MOV_35.mp4"}
]


var getPath = function ( i ){
   console.log('getPath', i );
   return "https://s3-eu-west-1.amazonaws.com/la-ballade/videos/"  + videos[i].video
}


//loader.src = "https://s3-eu-west-1.amazonaws.com/la-ballade/videos/" + videos[0]


//event: 
// - start load
//    attach oncanplaythrough to loader
//
// - oncanplaythrough - [loader] 
//    player playing?
//       attach finish_loading to loader
//    player not playing?
//       switch src to player
//       remove src from loader
//       attach finish_loading to player
//          ( load next )
//
// - finish_loading [ loader ]
//       mark video as loaded
//
// - finish_loading [ player ]
//       start loading next
//       remove finish_loading events
// - start play
// - end play
//
//
//
///Player:
// playing =>                 start ---------------------------------------------------------------------------------------- ended
// loading => start --------- oncanplaythrough  ------------------------------progress------------------------------ *finished
//Loaded
// loading => start --------- oncanplaythrough  ------------------------------ progress ---------------------------  *finished
//
//
//
//
//


logger = [];
logger.log = function (){
   args = [];
   for( i = 0; i < arguments.length ; i++ ) {
      args.push( arguments[i] );
   }
   msg =  args.map( function ( a ){ return a.toString(); } ).join(' : ')
   console.log( msg );
   this.push(  msg );
}

setInterval( function() {
   if( this.buffered.length > 0 ) {
      var ratio = this.buffered.end( this.buffered.length - 1 ) / this.duration;
      //console.log('loader', Math.floor( ratio * 100 ) );
      if( ratio > 0.99 ) {
         this.onfinishedloading()
      }
   }
}.bind(loader), 500 );


loader.start_loading =  function (){

   logger.log("loader" , "start_loading" , this._current);
   this.src = getPath( this._current )
   this.load();
}

loader.loadNext = function (){
   if( this._current >= videos.length ) return false;
   this._current++;
   this.start_loading();
}

loader.onfinishedloading = function ( cb ){
   logger.log("loader", "onfinishedloading" ,  this._current);
   // mark as loaded
   videos[this._current].loaded = true;
   // .....
   //load next
   //this.loadNext();
}

loader.clear = function ( cb ){
   logger.log("loader", "clear" +  this._current);
   loader.src = "";
}


//loader.onprogress = function ( e ){
   //console.log( "loader: progress");
//}

loader.oncanplaythrough = function( e ) {
   logger.log('loader', 'oncanplaythrough' ,  this._current);

   if( !!player.paused ) {
      player._current = loader._current;
      player.catchupplaying();
      loader.clear();
   }
}


player.start_playing = function (){
   logger.log('player', 'start_playing', this._current );
   this.src = getPath( this._current );
}

player.catchupplaying = function(){
   logger.log('player', 'catchupplaying_playing', this._current );
   this.src = getPath( this._current );
}

player.onfinishedloading = function ( cb ){
   logger.log("player", "onfinishedloading" ,  this._current);
   this.onfinishedloading = null;
   loader.loadNext();
}

setInterval( function ( ){
   if( this.buffered.length > 0 ) {
      var ratio = this.buffered.end( this.buffered.length - 1 ) / this.duration;
      //console.log('player', Math.floor( ratio * 100 ) );
      if( ratio > 0.99 ) {
         if ( !!this.onfinishedloading ) this.onfinishedloading();
      }
   }
}.bind(player),500)


player.playNext = function (){
   if( this._current >= videos.length ) return false;
   this._current++;
   this.start_playing();
}

player.onended = function ( e ){
   logger.log("player", "onended", this._current);
   this.playNext();
}

player._current = 0;
loader._current = 0;
loader.start_loading();


//loader.onprogress = function (e) {
   //if( this.buffered.length > 0 ) {
      //var ratio = this.buffered.end( this.buffered.length - 1 ) / this.duration;
      //console.log('loader', Math.floor( ratio * 100 ) );
      //if( ratio > 0.99 ) {
         //console.log(' 99% loaded');
      //}
   //}
//}

//player.oncanplaythrough = function ( e ){
   //console.log('player: oncanplaythrough');
//}

//player.onprogress = function (e) {
   //if( this.buffered.length > 0 ) {
      //var ratio = this.buffered.end( this.buffered.length - 1 ) / this.duration;
      //console.log('player', Math.floor( ratio * 100 ) );
      //if( ratio > 0.99 ) {
         //console.log(' 99% loaded');
      //}
   //}
//}
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

