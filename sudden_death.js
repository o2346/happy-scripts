const breaks = /\r\n|\n|\r/;
/**
 * getOstensibleLength
 *
 * @param str
 * @returns {undefined}
 */
function getOstensibleLength( str ) {
  let width = 0;
  str.replace( new RegExp( '[\x09-\x0d\x20-\x7e\uff61-\uff9f]|(.)', 'gu' ), ( _, isFull ) => width += isFull ? 1 : 0.5 );
  return width;
}

/**
 * buildLine
 *
 * @param str
 * @returns {undefined}
 */
function buildLines( str ) {
  const edgeLeft = "＞　";
  const edgeRight = "　＜";

  return str.split( breaks )
    .map( ( l ) => {
      return String().concat( edgeLeft, l, edgeRight );
    } )
    .map( ( l, i, a ) => {
      const maxLength = Math.max( ...a.map( ( _l ) => { return getOstensibleLength( _l ); } ) );
      let ans = '';
      const distance = maxLength - getOstensibleLength( l );
      if( distance > 0 ) {
        const pad = String().concat( '　'.repeat( Math.ceil( distance ) ) );
        ans = l.replace(
          new RegExp( edgeRight + '$' ),
          ( Number.isInteger( distance ) ? pad : pad.replace( /\s$/, ' ' ) ) + edgeRight
        );
      } else {
        ans = l;
      }
      return ans;
    } )
    .map( ( l, i, a ) => {
      const maxLength = Math.max( ...a.map( ( _l ) => { return getOstensibleLength( _l ); } ) );
      return Number.isInteger( maxLength ) ? l : l.replace( new RegExp( edgeRight + '$' ), ' ＜' );
    } )
    .join( '\n' );
}

/**
 * getUpper
 *
 * @param str
 * @returns {undefined}
 */
function getUpperLower( str ) {
  const edgeUpper    = "人";
  const edgeLower    = "^Y";
  const cornerUpper = "＿";
  const cornerLower = "￣";

  const maxLength = Math.max( ...str.split( breaks ).map( ( _l ) => { return getOstensibleLength( _l ); } ) );
  const upper = String().concat(
    cornerUpper,
    edgeUpper.repeat( maxLength - 2 ),
    cornerUpper
  );
  const lower = String().concat(
    cornerLower,
    edgeLower.repeat( maxLength - 3 ),
    cornerLower
  )
    .replace(
      new RegExp( '^' + cornerLower + '\\' + edgeLower ),
      ' ' + cornerLower + 'Y'
    );

  return [ upper, lower ];
}
/**
 * suddenDeath
 *
 * @param str
 * @returns {undefined}
 */
function suddenDeath( str ) {
  if( !str ) {
    return null;
  }
  return [
    getUpperLower( buildLines( str ) )[ 0 ],
    buildLines( str ),
    getUpperLower( buildLines( str ) )[ 1 ]
  ].join( '\n' );
}

const arg = '突然の死\n\nSudden Death!!!\nぼくアルバイトぉｫｫｫｫ\n123あああ\n' + 'う'.repeat( 30 ) + 'X';
//const arg = '突然の死';
console.log( suddenDeath( arg ) );
