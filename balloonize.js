#!./node
'use strict';

/**
 * Balloon Message AA Generator
 * Alternative over https://totuzennosi.sacnoha.com/
 * 'Sudden Death' comes from https://dic.nicovideo.jp/a/%E7%AA%81%E7%84%B6%E3%81%AE%E6%AD%BB
 */

//https://uxmilk.jp/50240
const breaks = /\r\n|\n|\r/;

/**
 * getLengthOstensible
 * http://var.blog.jp/archives/76281025.html
 * @param str
 * @returns {undefined}
 */
function getLengthOstensible( str ) {
  let width = 0;
  str.replace( new RegExp( '[\x09-\x0d\x20-\x7e\uff61-\uff9f]|(.)', 'gu' ), ( _, isFull ) => width += isFull ? 1 : 0.5 );
  return width;
}

const edgeLeft = '＞　';
const edgeRight = '　＜';

/**
 * padding
 *
 * @param str
 * @param distance
 * @param centering
 * @returns {undefined}
 */
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
function build( str ) {

  return str.split( breaks )
    .map( ( l ) => {
      return String().concat( edgeLeft, l, edgeRight );
    } )
    .map( ( l, i, a ) => {
      const maxLength = Math.max( ...a.map( ( _l ) => { return getLengthOstensible( _l ); } ) );
      let ans = '';
      const distance = maxLength - getLengthOstensible( l );
      if( distance > 0 ) {
        ans = padding( l, distance, true );
      } else {
        ans = l;
      }
      return ans;
    } )
    .map( ( l, i, a ) => {
      const maxLength = Math.max( ...a.map( ( _l ) => { return getLengthOstensible( _l ); } ) );
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

  const maxLength = Math.max( ...str.split( breaks ).map( ( _l ) => { return getLengthOstensible( _l ); } ) );
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
 * exec
 *
 * @param str
 * @returns {undefined}
 */
function exec( str ) {
  if( !str ) {
    return null;
  }
  const contents = build( str );
  const uplw     = getUpperLower( contents );

  return [
    uplw[ 0 ],
    contents,
    uplw[ 1 ]
  ].join( '\n' );
}

//this ones works well as above
//http://tanakh.jp/tools/sudden.html
if ( require.main === module ) {
  //console.log( 'called directly' );
  //main();
  //https://www.google.co.jp/search?&tbm=isch&safe=off&q=高橋啓介の8200系個別分散式VVVFはダテじゃねえ+複線ドリフト
  console.log( exec( '複線\nﾄﾞﾘﾌﾄ!!' ) );
  console.log( exec( 'はっえーっ\n高橋啓介の8200系\n個別分散式VVVFは\nダテじゃねえ!' ) );
  console.log( exec( '勝負になんねー\n2000系のフル加速なんて\nまるで止まってるようにしか\n見えねーよｫ!!' ) );
  console.log( exec( 'どうしたんだ\n今日に限って8200が\nやけにノロく感じる!!' ) );
  console.log( exec( 'ｸｿｯﾀﾚが\nﾊﾟﾝﾀ一基\n下がってんじゃねーのか！？' ) );
  console.log( exec( 'だまりゃ！麿は恐れ多くも帝より三位の位を賜わり中納言を務めた身じゃ！\nすなわち帝の臣であって徳川の家来ではおじゃらん！\nその麿の屋敷内で狼藉を働くとは言語道断！\nこの事直ちに帝に言上し、きっと公儀に掛け合うてくれる故、心しておじゃれ！' ) );
  //console.log( exec( '僕アルバイトォォｫｫ!!' ) );

} else {
  //console.log('required as a module');
  //this is for developers, for unit testing framework
  module.exports = {
    getLengthOstensible: getLengthOstensible,
    padding: padding,
    build: build,
    getUpperLower: getUpperLower,
    exec: exec
  };
}
