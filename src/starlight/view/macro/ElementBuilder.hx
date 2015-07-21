package starlight.view.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type as MacroType;

import starlight.core.Types.UnsafeMap;
import starlight.core.Exceptions;
import starlight.view.VirtualElement;
import starlight.view.VirtualElementTools;

using StringTools;
using tink.MacroApi;
using haxe.macro.ExprTools;
using starlight.view.VirtualElementTools;

typedef ObjectField = {field:String, expr:Expr};
typedef ObjectFieldSet = Array<ObjectField>;
#end

class ElementBuilder {
    public static macro function e(params:Array<Expr>) {
        return extractStructure(params);
    }

    #if macro

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
        var struct:VirtualElement;
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
                    Context.error('Cannot preprocess elements that have a dynamic signature ("${paramArray[0]}").', paramArray[0].pos);
            }
        } else {
            Context.error('Cannot preprocess elements that have no parameters', Context.currentPos());
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
                    childrenExpr = macro starlight.view.Component.buildChildren(untyped ${paramArray[1]});

                //  e('signature', [])
                case {expr: EArrayDecl(_), pos: _}:
                    childrenExpr = paramArray[1];
                //  e('signature', ?) -> Assume that the parameter is to be interpreted as a child textNode
                case {expr: EConst(CString(s)), pos: ePos}:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                case {expr: EConst(CIdent(s)), pos: ePos}:
                    matchChildren = false;
                    childrenExpr = macro starlight.view.Component.buildChildren(untyped ${paramArray[1]});
                default:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: Context.currentPos()};
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
                    Context.error('Cannot run compile-time optimization on variable used for element attributes', paramArray[1].pos);
            }

            switch(paramArray[2]) {
                //  e('signature', ?, [])
                case {expr: EArrayDecl(_), pos: _}:
                    childrenExpr = paramArray[2];
                //  e('signature', ?, func())
                case {expr: ECall(_), pos: _}:
                    matchChildren = false;
                    childrenExpr = macro starlight.view.Component.buildChildren(untyped ${paramArray[2]});
                //  e('signature', ?, ?)
                case {expr: EConst(CString(s)), pos: ePos}:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                case {expr: EConst(CIdent(s)), pos: ePos}:
                    matchChildren = false;
                    childrenExpr = macro starlight.view.Component.buildChildren(untyped ${paramArray[2]});
                default:
                    matchChildren = false;
                    childrenExpr = macro starlight.view.Component.buildChildren(untyped ${paramArray[2]});
            }
        }

        var virtualElement = VirtualElementTools.parseSignature(signature);

        var tagName = Context.makeExpr(virtualElement.tag, tagPos);
        var attrObjectFields = new ObjectFieldSet();
        var classObjectFields = new ObjectFieldSet();
        var classes = new Array<String>();
        var runtimeClasses = new Array<Dynamic>();
        var classPos = tagPos;

        function pushTo(objFS: ObjectFieldSet, field:ObjectField) {
            for (f in objFS) {
                if (f.field == field.field) {
                    Context.error('Duplicate object fields: "${f.field}".', field.expr.pos);
                }
            }
            objFS.push(field);
        }

        for (key in virtualElement.attrs.keys()) {
            var value = virtualElement.attrs.get(key);

            if (key == 'class') {
                switch(Type.typeof(value)) {
                    case TObject: {
                        for (cls in cast(value, UnsafeMap).keys()) {
                            classes.push(cls);
                        }
                    }
                    case TClass(s):
                        switch(Type.getClassName(s)) {
                            case 'String':
                                classes.push(value);
                            case 'haxe.ds.StringMap':
                                var val:haxe.ds.StringMap<Bool> = value;
                                for (cls in val.keys()) {
                                    classes.push(cls);
                                }
                            default:
                                Context.error('Don\'t know how to handle ${Type.getClassName(s)}', classPos);
                        }
                    default:
                        Context.error('Don\'t know how to handle ${Type.getClassName(value)}', classPos);
                 }
            } else {
                if (attributes.get(key) != null) {
                    Context.warning('For tag "$tagName", overwriting "$key": "${attributes.get(key)}" -> "${virtualElement.attrs.get(key)}"', Context.currentPos());
                }

                attributes.set(key, makeField(key, value));
            }
        }

        for (key in attributes.keys()) {
            var value = attributes.get(key);

            if (key == "@$__hx__class") {
                switch(value.expr) {
                    case {expr: EObjectDecl(fields), pos: oPos}:
                        for (field in fields) {
                            switch(field.expr) {
                                case {expr: EConst(CIdent(include)), pos: _}:
                                    if (include == "true") {
                                        classes.push(field.field);
                                    } else if (include != "false") {
                                        pushTo(classObjectFields, {field:field.field, expr:field.expr});
                                    }
                                default:
                                    pushTo(classObjectFields, {field:field.field, expr:field.expr});
                            }
                            classPos = oPos;
                        }
                    case {expr: EConst(CString(clsString)), pos: oPos}: {
                        classes = classes.concat(clsString.split(' '));
                        classPos = oPos;
                    }
                    default:
                        // Here we assume that if it's not an object then it will result in a string.
                        runtimeClasses.push(value.expr);
                };
            } else if (key == "@$__hx__checked") {
                switch(value.expr) {
                    case {expr: EConst(CIdent(checked)), pos: oPos}:
                        if (checked == "true") {
                            value.expr = {expr: EConst(CString("checked")), pos: oPos}
                            pushTo(attrObjectFields, value);
                        }
                    default:
                        value.expr = macro if (${value.expr}) "checked" else null;
                        pushTo(attrObjectFields, value);
                }
            } else {
                pushTo(attrObjectFields, value);
            }
        }

        if (classObjectFields.length > 0) {
            var classExpr = {
                expr: EObjectDecl(classObjectFields),
                pos: classPos
            }

            if (classes.length == 0 && runtimeClasses.length == 0) {
                pushTo(
                    attrObjectFields,
                    {
                        field:'class',
                        expr: macro starlight.view.Component.buildClassString(untyped ${classExpr})
                    });
            } else {
                var classStr = Context.makeExpr(classes.join(' '), classPos);
                for (cls in runtimeClasses) {
                    classStr = macro $classStr + ' ' + untyped $cls;
                }

                pushTo(
                    attrObjectFields,
                    {
                        field:'class',
                        expr: macro starlight.view.Component.buildClassString(untyped ${classExpr}, $classStr)
                    });
            }
        } else if (classes.length > 0 || runtimeClasses.length > 0) {
            var classStr = Context.makeExpr(classes.join(' '), classPos);

            for (cls in runtimeClasses) {
                classStr = macro $classStr + ' ' + untyped $cls;
            }

            pushTo(attrObjectFields, {
                field:'class',
                expr: classStr
            });
        }

        var attrExpr = {expr: EObjectDecl(attrObjectFields), pos: classPos};

        if (matchChildren) {
            childrenExpr = childrenExpr.map(matchElementCallsAndStrings);
        }

        return macro ({
            tag: ${tagName},
            attrs: untyped ${attrExpr},
            children: $childrenExpr
        }:starlight.view.VirtualElement);
    }

    static function makeField(key, value) {
        return {
            field: key,
            expr: macro '$value'
        };
    }
    #end
}
