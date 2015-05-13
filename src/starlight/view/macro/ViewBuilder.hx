package starlight.view.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import starlight.view.VirtualElement;
import starlight.view.VirtualElement.VirtualElementTools;

using StringTools;
using tink.MacroApi;
using haxe.macro.ExprTools;
using starlight.view.VirtualElement.VirtualElementTools;

#end

class ViewBuilder {
    #if macro
    macro static public function build(): Array<Field> {
        return Context.getBuildFields().map(findViewFields);
    }

    static function findViewFields(field: Field) {
        return switch (field.kind) {
            case FieldType.FFun(func):
                if (field.meta.toMap().exists(':view')) {
                    func.expr = func.expr.map(matchElementCalls);
                }
                field;
            default: field;
        }
    }

    static function matchElementCalls(e: Expr):Expr {
        return filterElementCalls(e, false);
    }

    static function matchElementCallsAndStrings(e: Expr):Expr {
        return filterElementCalls(e, true);
    }

    static function filterElementCalls(e: Expr, matchString: Bool):Expr {
        return switch (e.expr) {
            case ECall({
                        expr: EConst(CIdent('e')),
                        pos: _
                    },
                    params):
                extractStructure(params);
            case EConst(_)|EField(_):
                if (matchString) buildTextElement(e) else e.map(matchElementCalls);
            case EIf(_)|EBlock(_):
                e.map(matchElementCallsAndStrings);
            default:
                e.map(matchElementCalls);
        }
    }

    static function buildTextElement(expr):Expr {
        var tagName = Context.makeExpr(VirtualElementTools.TEXT_TAG, Context.currentPos());

        return macro untyped {
            tag: ${tagName},
            textValue: $expr
        };
    }

    static function extractStructure(paramArray: Array<Expr>):Expr {
        var struct:starlight.view.VirtualElement;
        var signature:String;
        var attributes = new haxe.ds.StringMap<{ field : String, expr : haxe.macro.Expr }>();
        var childrenExpr;
        var tagName:String;
        var tagPos:haxe.macro.Position;
        var matchChildren = true;

        if (paramArray.length >= 1) {
            switch(paramArray[0]) {
                case {expr: EConst(CString(str)), pos: tPos}:
                    signature = str;
                    tagPos = tPos;
                    childrenExpr = {expr: EArrayDecl([]), pos: tPos};
                default:
                    throw 'Invalid signature: ${paramArray[0]}';
            }
        }

        if (paramArray.length == 2) {
            switch(paramArray[1]) {
                //  e('signature', {class: 'something'})
                case {expr: EObjectDecl(objArray), pos: _}:
                    for (obj in objArray) {
                        attributes.set(obj.field, obj);
                    }
                //  e('signature', {})
                case {expr: EBlock(_), pos: _}:
                //  e('signature', func())
                case {expr: ECall(_), pos: _}:
                    matchChildren = false;
                    childrenExpr = paramArray[1];
                //  e('signature', [])
                case {expr: EArrayDecl(_), pos: _}:
                    childrenExpr = paramArray[1];
                //  e('signature', ?)
                case {expr: EConst(CString(s)), pos: ePos}:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                case {expr: EConst(CIdent(s)), pos: ePos}:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                default:
                    throw 'Invalid attributes: ${paramArray[1]}';
            }
        }

        if (paramArray.length == 3) {
            switch(paramArray[1]) {
                //  e('signature', {class: 'something'})
                case {expr: EObjectDecl(objArray), pos: _}:
                    for (obj in objArray) {
                        attributes.set(obj.field, obj);
                    }
                //  e('signature', {})
                case {expr: EBlock(_), pos: _}:
                default:
                    throw 'Invalid attributes: ${paramArray[1]}';
            }

            switch(paramArray[2]) {
                //  e('signature', ?, [])
                case {expr: EArrayDecl(_), pos: _}:
                    childrenExpr = paramArray[2];
                //  e('signature', ?, func())
                case {expr: ECall(_), pos: _}:
                    matchChildren = false;
                    childrenExpr = paramArray[1];
                //  e('signature', ?, ?)
                case {expr: _, pos: ePos}:
                    var expr = buildTextElement(paramArray[2]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                default:
                    throw 'Invalid children: ${paramArray[2]}';
            }
        }

        var virtualElement = starlight.view.VirtualElementTools.element(signature);

        var tagName = Context.makeExpr(virtualElement.tag, tagPos);
        var objfields = new Array<{field:String, expr:Expr}>();
        for (key in virtualElement.attrs.keys()) {
            var value = virtualElement.attrs.get(key);

            if (attributes.exists(key) || attributes.exists("@$__hx__" + key)) {
                Context.warning('overwriting $key', Context.currentPos());
            }

            attributes.set(key, makeField(key, value));
        }
        for (key in attributes.keys()) {
            var value = attributes.get(key);
            if (key == "@$__hx__class") {
                switch(value.expr) {
                    case {expr: EObjectDecl(fields), pos: oPos}:
                        value = {
                            field:'class',
                            expr: macro buildClassString(untyped ${value.expr})
                        }
                    default:
                };
                objfields.push(value);
            } else {
                objfields.push(value);
            }
        }
        var attrExpr = {expr: EObjectDecl(objfields),
            pos: Context.currentPos()
        };

        if (matchChildren) {
            childrenExpr = childrenExpr.map(matchElementCallsAndStrings);
        }

        return macro untyped {
            tag: ${tagName},
            attrs: $attrExpr,
            children: $childrenExpr
        };
    }

    static function makeField(key, value) {
        return {
            field: key,
            expr: Context.makeExpr(value, Context.currentPos())
        };
    }

    #end
}
