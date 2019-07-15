/**
 * vertmap
 *
 * @param str
 * @returns {undefined}
 */
function vertmap( str ) {
  const containsDoubleWith = ( str.match( /[^\x20-\x7E\xA1-\xDF\s]/ ) );
  //console.log( containsDoubleWith );
  return str
    .split( '\n' )
    .map( ( s, i, a ) => {
      const max = Math.max( ...a.map( ( _l ) => _l.length ) );
      const pad = ( containsDoubleWith ? '　' : ' ' );
      return s.concat( pad.repeat( max - s.length ) );
    } )
    .map( ( s ) => {
      return s.split( '' );
    } )
    .map( ( s, index ) => {
      return s.map( ( c, i ) => {
        return {
          char: c,
          x: parseInt( i, 10 ),
          y: parseInt( index, 10 )
        };
      } );
    } )
    //.forEach( ( elm ) => {
    //  elm.forEach( ( e ) => {
    //    console.log( 'arr[' + e.x + '][' + e.y + ']=' + e.char );
    //  } );
    //} );
    .reduce( ( accum, current ) => {
      //console.log( accum );
      const cloneAccum = [...accum]; //https://www.samanthaming.com/tidbits/35-es6-way-to-clone-an-array
      current.forEach( ( curr ) => {
        if( !cloneAccum[ curr.x ] ) {
          cloneAccum[ curr.x ] = [];
        }
        cloneAccum[ curr.x ][ curr.y ] = curr.char;
        //console.log( 'arr[' + curr.x + '][' + curr.y + ']=' + curr.char );
      } );
      //console.log( cloneAccum );
      return cloneAccum;
    }, [] )
    .map( ( elm ) => {
      return elm.reverse().join( '' ).concat( '\n' );
    } )
    .join( '' )
    .replace( new RegExp( ( containsDoubleWith ? '([\x20-\x7E\xA1-\xDF])' : '$^' ), 'g' ), ' $1' );
}

const input = '複線\nドリフト!!';
console.log( vertmap( input ) );
console.log( vertmap( 'Multi-\nTrack\nDrifting!!' ) );
