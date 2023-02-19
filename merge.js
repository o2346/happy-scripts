//usage: node % file1 file2
//https://stackoverflow.com/a/16178864
const fs = require( 'fs' );
/*
    Recursively merge properties and return new object
    obj1 &lt;- obj2 [ &lt;- ... ]
*/
function merge () {
    var dst = {}
        ,src
        ,p
        ,args = [].splice.call(arguments, 0)
    ;

    while (args.length > 0) {
        src = args.splice(0, 1)[0];
        if (toString.call(src) == '[object Object]') {
            for (p in src) {
                if (src.hasOwnProperty(p)) {
                    if (toString.call(src[p]) == '[object Object]') {
                        dst[p] = merge(dst[p] || {}, src[p]);
                    } else {
                        dst[p] = src[p];
                    }
                }
            }
        }
    }

   return dst;
}

const obj1 = { food: 'pizza', car: 'ford', hoge: { fuga: 'fuga', piyo: 'piyo' } };
const obj2 = { animal: 'dog', hoge: { fuga: 'fugafuga' } };

const f1 = fs.readFileSync( process.argv[ 2 ] ).toString();
const f2 = fs.readFileSync( process.argv[ 3 ] ).toString();

//const merged =  { ...obj1, ...obj2 };
//const merged = Object.assign( obj1, obj2 );
//const merged = merge( obj1, obj2 );
const merged = merge(
  JSON.parse( f1 ),
  JSON.parse( f2 )
);

process.stdout.write( JSON.stringify( merged ) );
