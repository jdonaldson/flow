
import com.tenderowls.txml176.*;
import haxe.Template;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;
import haxe.xml.Fast;
import promhx.PublicStream;
import promhx.Stream;

class Flux {

    macro public static function compose<T, U>(template : ExprOf<String>){
        if (template == null) return macro null;
        var exprs = switch(template.expr){
            case EConst(CString(c)) :{
                var tx    = Xml176Parser.parse(c);
                var xml   = tx.document.firstElement();
                bindTemplate(tx, xml);
            }
            case _ : throw("Flux template must be a literal string expression");
        }
        return exprs;
    }


#if macro
    public static function bindTemplate(tx : Xml176Document, xml : Xml): Expr {
        var exprs = new Array<Expr>();
        var attr_links = new Array<Expr>();
        var pool_var = '';

        for (a in xml.attributes()){
            var expr = tx.getAttributeTemplate(xml, a);
            if (expr != null){
                var m_expr =
                    Context.parseInlineString( expr, Context.currentPos());

                var link_expr = switch(m_expr.expr){
                    case EConst(CIdent(s)) :  {
                        macro {
                            o.templateBindings.push({from : $m_expr, to: o.stream.$a});
                        }
                    }
                    case EConst(_), EArrayDecl(_) : macro  {
                        o.stream.$a.setDefaultState($m_expr);
                    }
                    default : null;
                };
                if (link_expr != null) attr_links.push(link_expr);
            } else {
                if (xml.nodeName == "pool"  && a == "val"){
                    pool_var = xml.get(a);
                } else {
                    attr_links.push(macro o.stream.$a.setDefaultState(macro ${xml.get(a)}));
                }
            }
        }

        attr_links.push(macro for (k in o.templateBindings) {
            promhx.base.AsyncBase.link(k.from, k.to, function(x) return x);
        });

        var body_exprs = new Array<Expr>();

        for (c in xml){
            switch(c.nodeType){
                case 'element' : body_exprs.push(Flux.bindTemplate(tx, c));
                default : null;
            }
        }

        var pack = xml.nodeName.split('.');
        var name = pack.pop();
        var typepath = {
            params : [],
            pack : pack,
            name : name
        }

        if (typepath.name == "pool"){
            if (pool_var == "") Context.error("Pool var should be set for pool node", Context.currentPos());
            return macro {
                var o = new flux.Pool(function($pool_var) return $a{body_exprs});
                $b{attr_links}
                o;
            }

        } else {
            return macro {
                var o = new $typepath();
                $b{attr_links}
                for (a in $a{body_exprs}) o.addChild(a);
                o;
            };
        }


    }
#end


}

