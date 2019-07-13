
function suddenDeath( str ) {
  if( !str ) {
    return null;
  }
  //吹き出す 
  var balloonUpper = "人";
  var balloonLeft = "＞　";
  var balloonRight = "　＜";
  var balloonLower = "^Y";
  var top = "＿人人人";
  var bottom = "\r\n￣Y^Y^Y"
  var cnt = 0;
  var line = str.match(/\r\n|\n/g);
  if(!line) var line = "";
  line = line.length + 1;
  if(line > 1) {
  str = str.split(/\r\n|\r|\n/);
  for(i=0;i<line;i++) {
    if(cnt < str[i].length) cnt = str[i].length;
    str[i] = balloonLeft + str[i] + balloonRight;
  }
  str = str.join("\r\n");
  str = str.replace(/\r\n$/, "");
  } else {
  cnt = str.length;
  str = balloonLeft + str + balloonRight;
  }
  //6文字以上でずれるっぽいので調整してもいいかも・全角半角でカウント方法を調整しないと調整不可
  for(i=1;i<cnt;i++) {
  top += balloonUpper;
  bottom += balloonLower;
  }
  top += "＿\n";
  if(cnt > 1) bottom = bottom.replace(/\^Y$/m,"");
  bottom += "￣";
  str = top + str + bottom;
  //console.log( top + '\n' );
  console.log( str );
}

suddenDeath( '突然の死\naaaa' );
