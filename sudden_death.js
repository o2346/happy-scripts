/**
 * Balloon Message AA Generator
 * Alternative over https://totuzennosi.sacnoha.com/
 * 'Sudden Death' comes from https://dic.nicovideo.jp/a/%E7%AA%81%E7%84%B6%E3%81%AE%E6%AD%BB
 */

//https://uxmilk.jp/50240
const breaks = /\r\n|\n|\r/;

/**
 * getOstensibleLength
 * http://var.blog.jp/archives/76281025.html
 * @param str
 * @returns {undefined}
 */
function getOstensibleLength( str ) {
  let width = 0;
  str.replace( new RegExp( '[\x09-\x0d\x20-\x7e\uff61-\uff9f]|(.)', 'gu' ), ( _, isFull ) => width += isFull ? 1 : 0.5 );
  return width;
}

const edgeLeft = '＞　';
const edgeRight = '　＜';

function padding( str, distance, centering ) {
  const pad = String().concat( '　'.repeat( Math.ceil( distance ) ) );
  if( centering ) {
    const pads = [
      Math.trunc( pad.length / 2 ),
      Math.ceil( pad.length / 2 )
    ]
      .map( ( p ) => {
        return '　'.repeat( p );
      } );
    pads[ 1 ] = ( Number.isInteger( distance ) ? pads[ 1 ] : pads[ 1 ].replace( /\s$/, ' ' ) ) + edgeRight;
    //console.log( pad.length + ' ' + pads.join( '' ).length );
    return str.replace(
      new RegExp( '^' + edgeLeft ),
      edgeLeft + pads[ 0 ]
    ).replace(
      new RegExp( edgeRight + '$' ),
      pads[ 1 ]
    );
  }

  return str.replace(
    new RegExp( edgeRight + '$' ),
    ( Number.isInteger( distance ) ? pad : pad.replace( /\s$/, ' ' ) ) + edgeRight
  );
}

/**
 * buildLine
 *
 * @param str
 * @returns {undefined}
 */
function buildLines( str ) {

  return str.split( breaks )
    .map( ( l ) => {
      return String().concat( edgeLeft, l, edgeRight );
    } )
    .map( ( l, i, a ) => {
      const maxLength = Math.max( ...a.map( ( _l ) => { return getOstensibleLength( _l ); } ) );
      let ans = '';
      const distance = maxLength - getOstensibleLength( l );
      if( distance > 0 ) {
        ans = padding( l, distance, true );
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
  const edgeUpper    = '人';
  const edgeLower    = '^Y';
  const cornerUpper = '＿';
  const cornerLower = '￣';

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

console.log( suddenDeath( '複線\nﾄﾞﾘﾌﾄ!!' ) );
console.log( suddenDeath( 'ｸｿｯﾀﾚが!!\nﾊﾟﾝﾀ一基下がってんじゃねーのか！？' ) );
console.log( suddenDeath( 'だまりゃ！麿は恐れ多くも帝より三位の位を賜わり中納言を務めた身じゃ！\nすなわち帝の臣であって徳川の家来ではおじゃらん！\nその麿の屋敷内で狼藉を働くとは言語道断！\nこの事直ちに帝に言上し、きっと公儀に掛け合うてくれる故、心しておじゃれ！' ) );
//console.log( suddenDeath( '僕アルバイトォォｫｫ!!' ) );

//this ones works well as above
//http://tanakh.jp/tools/sudden.html
