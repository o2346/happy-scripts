
/**
 * vertmap
 *
 * @param str
 * @returns {undefined}
 */
function vertmap( str ) {
  const ignoreChars = [
    /\!/,
    /\?/
  ];
  const containsDoubleWith = ( str.match( /[^\x20-\x7E\xA1-\xDF\s]/ ) );
  const pad = ( containsDoubleWith ? '　' : ' ' );

  return str
    .split( '\n' )
    .map( ( s, i, a ) => {
      const max = Math.max( ...a.map( ( _l ) => _l.length ) );
      return s.concat( pad.repeat( max - s.length ) );
    } )
    .map( ( s ) => {
      return s.split( '' );
    } )
    .map( ( s, index ) => {
      return s.map( ( c, i ) => {
        return {
          char: c,
          x: i,
          y: index
        };
      } );
    } )
    .reduce( ( accum, current ) => {
      const cloneAccum = [...accum]; //https://www.samanthaming.com/tidbits/35-es6-way-to-clone-an-array
      current.forEach( ( curr ) => {
        if( !cloneAccum[ curr.x ] ) {
          cloneAccum[ curr.x ] = [];
        }
        cloneAccum[ curr.x ][ curr.y ] = curr.char;
      } );
      return cloneAccum;
    }, [] )
    .map( ( elm, index, array ) => {
      return elm
        .map( ( c, i ) => {
          if( containsDoubleWith && array[ index + 1 ] && ignoreChars.some( ( ic ) => array[ index + 1 ][ i ].match( ic ) ) && ignoreChars.some( ( ic ) => c.match( ic ) ) ) {
            const ans = '＜ＩＧＨＯＲＥＣＨＡＲＤＯＵＢＬＥ＝' + c + array[ index + 1 ][ i ] + '＞';
            array[ index + 1 ][ i ] = '';
            return ans;
          }
          return c;
        } );
    } )
    .filter( ( elm ) => {
      return !elm.join( '' ).match( new RegExp( '^' + pad + '+$' ) );
    } )
    .map( ( elm ) => {
      return elm.reverse().join( '' ).concat( '\n' );
    } )
    .join( '' )
    .replace( new RegExp( ( containsDoubleWith ? '([\x20-\x7E\xA1-\xDF])' : '$^' ), 'g' ), ' $1' )
    .replace( new RegExp( '＜ＩＧＨＯＲＥＣＨＡＲＤＯＵＢＬＥ＝(.+)＞', 'g' ), ( m, p1 ) => { return p1.replace( /\s/g, '' ); } );
}

console.log( vertmap( '複線\nドリフト!!' ) );
console.log( vertmap( 'Multi-\nTrack\nDrifting!!' ) );
