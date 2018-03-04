 // Simple Arithmetics Grammar
// ==========================
//
// Accepts expressions like "2 * (3 + 4)" and computes their value.
{
    // 予約語
    var RESERVED_WORDS = ["if", "else", "elif", "while", "switch"]

	function inject (cd, vl){
        return cd + " " + vl + "[DECLARE]"
    }
    function access (to){
    	return to + " " + "[ACCESS]"
    } 
    
    function condition(cmd, test , code){
        return test + "[CHK_GOTO(0,"+code.length+")]" + code
    }

    function invoke (operand){
        var buf = ""
        for(var i=0; i<operand.length; ++i){
        	buf += operand[i] + " [APUSH] ";
        }
    	return buf + "[CALL:" + operand.length + "]"
    }
    
    function indexer (operand){
        var buf = ""
        for(var i=0; i<operand.length; ++i){
        	buf += operand[i] + " [APUSH] ";
        }
     	return buf + "[IDX:" + operand.length + "]"
    }

    function operator(operand1, operator, sign, operand2){

        var narray=new Array();

        if(operand1 instanceof Array){
            for(var i=0; i<operand1.length; ++i){
                narray.push(operand1[i]);
            }
        }
        else{
            narray.push(operand1)
        }

        if(operand2 instanceof Array){
            for(var i=0; i<operand2.length; ++i){
                narray.push(operand2[i]);
            }
        }
        else{
            narray.push(operand2)
        }

        if(sign){
            narray.push(sign);
        }
        narray.push(operator);

        return narray;
    }

    function makeWord(text){
        // 予約語チェック
        for(var idx=0; idx<RESERVED_WORDS.length; ++idx){
            if(text==RESERVED_WORDS[idx]){
                error(" '"+RESERVED_WORDS[idx]+"' is reserved word")
            }
        }
        return {"type": "variable", "value": text, "location": location().start}
    }

    function makeTextPattern(ptn, text){
        if(ptn=="r"){
            //正規表現
            return {"type": "regex", "value": text}
        }
        else if(ptn=="d"){
            //日付
            return {"type": "regex", "value": text}
        }
        else{
            // 取扱対象外
            error(" '"+pgn+"' is unknown text prefix")
        }

        return ptn+":"+text
    }

	function makeText(text){
        return {"type": "text", "value": text}
	}

    function makeNumber(text){
    	return {"type": "number", "value": Number(text)}
    }

    function makeBoolean(val){
        return {"type": "boolean", "value": val}
    }

    function solveSig(sigArray){
        var sigFlg = false;
        for(var i=0; i<sigArray.length; ++ i){
            if(sigArray[i]==="-"){
                sigFlg = !sigFlg;
            }
        }
        return sigFlg? "-": null;
    }
}

Code
  =  _ expr:(REM _ / CodeLine _ )*  {
        var buff = []
        for(var i=0; i<expr.length; ++i){
            buff.push(expr[i][0])
        }
        return buff
    }

CodeLine
  =  _ ( Sentence / Injector / MethodCall ) 

// 代入式
Injector 
  = wd:Word _ ("="/"<-"/":=") _ vl:Expression {
        return inject(wd, vl)
    }

// 文
Sentence
  = cmd:Command _ "(" _ test:Expression _ ")" _  cd:CodeLine  {
        return condition(cmd, test, [cd])
    }
  
  / cmd:Command _ "(" _ test:Expression _ ")" _ "{" cd:Code "}" {
        return condition(cmd, test, cd)
    }
  / cmd:"else" _ cd:CodeLine {
        return condition(cmd, )
    }
  / "else" _ "{" cd:Code "}"
  / "foreach" _ "(" _ Word __ "in" __ Expression _ ")" _ "{" cd:Code "}"
  / "foreach" _ "(" _ Word __ "in" __ Expression _ ")" _ cd:CodeLine

Command
  = "if" / "elif" / "while"

// 関数呼出
MethodCall
  = root:(Word/Text/DateTime) accesses:( _ access_chip / _ index_chip / _ call_chip )+ {
        var buf="";
        for(var i=0; i<accesses.length; ++i){
            buf += accesses[i][1];
        }
        return root + " "  + buf;
    }


////////////////////////////////////////
// 数式
////////////////////////////////////////
Expression = Operator8 / Operator9

Operator9
  = head:Expression _ "?" _ whenTrue:Expression _ ":" _ whenFalse:Expression

Operator8
  = head:Operator7 tail:(_ ("|") _ Sign _ Operator7)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator7
  = head:Operator6 tail:(_ ("^") _ Sign _ Operator6)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator6
  = head:Operator5 tail:(_ ("&") _ Sign _ Operator5)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator5
  = head:Operator4 tail:(_ ("!="/"==") _ Sign _ Operator4)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator4
  = head:Operator3 tail:(_ ("<"/">"/"<="/">=") _ Sign _ Operator3)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator3 
  = head:Operator2 tail:(_ ("<<"/">>"/">>>") _ Sign _ Operator2)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator2 
  = head:Operator1 tail:(_ ("+" / "-") _ Sign _ Operator1)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operator1 
  = head:Operand tail:(_ ("*" / "/" / "%") _ Sign _ Operand)* {
        return tail.reduce(function(result, element) {
            return operator(result, element[1], element[3], element[5]);
        }, head);
    }

Operand
  = "(" _ expr:Expression _ ")" {
		return expr
	}
  / Object

/** 符号 */
Sign "sign"
    = sigarray:("-"/"+"/__)* {
        return solveSig(sigarray);
}


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
DataType = TextPattern / Boolean / Word / Text / Number

/** 変数とか */
Word "word"
  = [A-Za-z][A-Za-z0-9_]* {
        return makeWord(text());
    } 

/** 文字列表現の何か */
TextPattern 
  = ptn:[a-z] txt:Text {
        makeTextPattern(ptn, txt)
    }

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

/** 真偽値 */
Boolean "boolean"
  = [tT][rR][uU][eE]     { 
        return makeBoolean(true); 
    }
  / [fF][aA][lL][sS][eE] { 
        return makeBoolean(false);
    }


////////////////////////////////////////
// コメント
////////////////////////////////////////
REM "comment"
  = line_comment/block_comment

/** 1行コメント(Cとかの) */
line_comment
  = ("//"/"#"/"--") p:([^\r\n]*) {
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
              