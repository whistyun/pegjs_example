////////////////////////////////////////
// オブジェクト
////////////////////////////////////////
Object
  = root:DataType accesses:( _ access_chip / _ index_chip / _ call_chip )* {
        var buf="";
        for(var i=0; i<accesses.length; ++i){
            buf += accesses[i][1];
        }
        return root + " "  + buf;
    }
  / acs:access_chip accesses:( _ access_chip / _ index_chip / _ call_chip )* 

access_chip
  = "." _ to:Word {
        return access(to) 
    }

index_chip
  = "[" _ expr:Expression _  aexpr:("," _ Expression _ )* "]" {
        var args = [];
        args.push(expr);
        for(var i=0; i<aexpr.length; ++i){
            args.push(aexpr[i][2])
        }
  	    return indexer(args)
    }

call_chip
  = "(" _ ")" {
        return invoke([])
    }
  / "(" _ expr:Expression _  aexpr:("," _ Expression _ )* ")" {
        var args = [];
        args.push(expr);
        for(var i=0; i<aexpr.length; ++i){
            args.push(aexpr[i][2])
        }
  	    return invoke(args)
    }


////////////////////////////////////////
// データタイプ
////////////////////////////////////////
DataType = Boolean / DateTime / TimeSpan / Word / Text / Number

/** 変数とか */
Word "word"
  = [A-Za-z][A-Za-z0-9_]* {
        return makeWord(text());
    } 

/** 日時 */
DateTime "datetime"
  = "#" year:[0-9]+ "/" month:[0-9]+ "/" date:[0-9]+ __ hour:[0-9]+ ":" minute:[0-9]+ ":" second:[0-9]+ "#"

TimeSpan "timespan"
  = "#P" d:([0-9]+ "D" "T"?)? h:([0-9]+ "H")? m:([0-9]+ "M")? s:([0-9]+ "S")? "#"

/** 真偽値 */
Boolean "booleal"
  = [tT][rR][uU][eE]     { return "true" }
  / [fF][aA][lL][sS][eE] { return "false" }

/** 文字列 */
Text "text"
  = '"""' t:(tritext_linner*) '"""' {
        return makeText(t.join(''))
    }
  / '"' t:(dqtext_linner*) '"' {
        return makeText(t.join(''))
	}
  / "'" t:(sqtext_linner*) "'" {
        return makeText(t[1].join(''))
	}
tritext_linner
  = p:(!'"""' .){return p[1];}
dqtext_linner 
  = '\\"' / p:(!'"' .){return p[1];}
sqtext_linner
  = "\\'" / p:(!"'" .){return p[1];}

/** 数値 */
Number "number"
  = _ [0-9]+("."[0-9]+)*( "E" ("-" / "+")? [0-9]+)? {
        return makeNumber(text());
    }


////////////////////////////////////////
// コメント
////////////////////////////////////////
REM "comment"
  = line_comment/block_comment

/** 1行コメント(Cとかの) */
line_comment
  = ("//") p:([^\r\n]*) {
        return null
    }
/** ブロックコメント */
block_comment
  = p:("/*" multi_liner* "*/") {
        return null
    }
multi_liner
  = p:(!"*/" .){return p[1]}

_ "whitespace"
  = [ \t\n\r]*

__ "whitespace"
  = [ \t\n\r]+