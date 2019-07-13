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
  const balloonLeft = "＞　";
  const balloonRight = "　＜";

  let maxLength = 0;
  return str.split( breaks )
    .map( ( l ) => {
      return String().concat( balloonLeft, l, balloonRight );
    } )
    .map( ( l, i, a ) => {
      maxLength = Math.max( ...a.map( ( _l ) => { return getOstensibleLength( _l ); } ) );
      let ans = '';
      const distance = maxLength - getOstensibleLength( l );
      if( distance > 0 ) {
        const pad = String().concat( '　'.repeat( Math.ceil( distance ) ) );
        ans = l.replace(
          new RegExp( balloonRight + '$' ),
          ( Number.isInteger( distance ) ? pad : pad.replace( /\s$/, ' ' ) ) + balloonRight
        );
      } else {
        ans = l;
      }
      return ans;
    } )
    .join( '\n' );
}

/**
 * getBalloonUpper
 *
 * @param str
 * @returns {undefined}
 */
function getBalloonUpperLower( str ) {
  const balloonUpper = "人";
  const balloonLower = "^Y";
  const presufffixUpper = "＿";
  const presufffixLower = "￣";

  const maxLength = Math.max( ...str.split( breaks ).map( ( _l ) => { return getOstensibleLength( _l ); } ) );
  const upper = String().concat(
    presufffixUpper,
    balloonUpper.repeat( maxLength - 2 ),
    presufffixUpper
  );
  const lower = String().concat(
    presufffixLower,
    balloonLower.repeat( maxLength - 2 ),
    presufffixLower
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
    getBalloonUpperLower( buildLines( str ) )[ 0 ],
    buildLines( str ),
    getBalloonUpperLower( buildLines( str ) )[ 1 ]
  ].join( '\n' );
}

const arg = '突然の死\n\nSudden Death\nぼくアルバイトぉｫｫｫｫ\n123あああ';
console.log( suddenDeath( arg ) );
