const balloonLeft = "＞　";
const balloonRight = "　＜";

/**
 * buildLine
 *
 * @param str
 * @returns {undefined}
 */
function buildLines( str ) {
  let maxLength = 0;
  return str.split( /[\r\n]/ )
    .map( ( l ) => {
      return String().concat( balloonLeft, l, balloonRight );
    } )
    .map( ( l, i, a ) => {
      maxLength = Math.max( ...a.map( ( _l ) => { return _l.length; } ) );
      let ans = '';
      if( l.length < maxLength ) {
        const pad = '　'.repeat( maxLength - l.length );
        ans = l.replace( new RegExp( balloonRight + '$' ), pad + '＜' );
      } else {
        ans = l;
      }
      return ans;
    } )
    .join( '\n' ) + maxLength;
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

  const maxLength = Math.max( ...str.split( /[\n\r]/ ).map( ( _l ) => { return _l.length; } ) );
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
  //balloon
  const balloonUpper = "人";
  const balloonLower = "^Y";
  let top = "＿人人人";
  let bottom = "\r\n￣Y^Y^Y";
  let cnt = 0;
  let line = str.match( /\r\n|\n/g );
  if( !line ) {
    line = "";
  }
  line = line.length + 1;
  if( line > 1 ) {
    str = str.split( /\r\n|\r|\n/ );
    for( let i = 0; i < line; i++ ) {
      if( cnt < str[ i ].length ) {
        cnt = str[ i ].length;
      }
      str[ i ] = balloonLeft + str[ i ] + balloonRight;
    }
    str = str.join( "\r\n" );
    str = str.replace( /\r\n$/, "" );
  } else {
    cnt = str.length;
    str = balloonLeft + str + balloonRight;
  }
  //6文字以上でずれるっぽいので調整してもいいかも・全角半角でカウント方法を調整しないと調整不可
  for( let i = 1; i < cnt; i++ ) {
    top += balloonUpper;
    bottom += balloonLower;
  }
  top += "＿\n";
  if( cnt > 1 ) {
    bottom = bottom.replace( /\^Y$/m, "" );
  }
  bottom += "￣";
  str = top + str + bottom;
  //console.log( top + '\n' );
  return str;
}

const arg = '突然の死突然の死突然の死\naaいいいい';
console.log( suddenDeath( arg ) );
console.log( getBalloonUpperLower( buildLines( arg ) )[ 0 ] );
console.log( buildLines( arg ) );
console.log( getBalloonUpperLower( buildLines( arg ) )[ 1 ] );
