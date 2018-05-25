#!/usr/bin/node

const fs = require( 'fs' );
const path = require( 'path' );
const { exec } = require( 'child_process' );
const { execSync } = require( 'child_process' );

const dir   = process.argv[ 2 ];
const files = process.argv[ 3 ].split( ' ' );
const args  = process.argv[ 4 ];

console.dir( files );

/**
 * isUp check state is updated
 *
 * @returns {Boolean}
 */
function isUp() {
  const answer = execSync( 'make -n' ).toString();
  return [
    'Nothing to be done for',
    'is up to date'
  ].some( ( keyword ) => {
    return answer.match( new RegExp( keyword ) );
  } );
}

/**
 * isMakefile
 *
 * @param   {String}    file
 * @returns {Boolean}
 */
function isMakefile( file ) {
  return file.match( /makefile/i );
}

files.forEach( ( f ) => {
  fs.watchFile( path.join( dir, f ), () => {
    if( isUp() && !isMakefile( f ) ) {
      return 0;
    }
    console.log( '[modified] ' + f );
    exec( 'make ' + ( isMakefile( f ) ? '-B' : '' ) + args, ( err, stdout, stderr ) => {
      if( err ) {
        console.error( 'Error: ' + err );
        return;
      }
      if( stdout ) {
        process.stdout.write( stdout );
      }
      if( stderr ) {
        console.error( stderr );
      }
    } );
    return 0;
  } );
} );

