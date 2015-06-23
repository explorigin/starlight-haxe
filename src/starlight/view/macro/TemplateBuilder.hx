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

typedef ObjectFieldSet = Array<{field:String, expr:Expr}>;
#end

class TemplateBuilder {
    public static var fieldMap = new haxe.ds.StringMap<Bool>();

    #if macro
    macro static public function build(): Array<Field> {
        var fields = Context.getBuildFields();
        for (field in fields) {
            switch(field.kind) {
                case FProp(_, _, _, _):
                    TemplateBuilder.fieldMap.set(field.name, true);
                default:
                    TemplateBuilder.fieldMap.set(field.name, false);
            }
        }

        return convertVarsToProperties(fields.map(findViewFields));
    }

    static function convertVarsToProperties(fields: Array<Field>):Array<Field> {
        var newFields = new Array<Field>();

        for (member in fields) {
            switch (member.kind) {
                case FieldType.FVar(cType, expr):
                    var name = member.name;

                    if (!TemplateBuilder.fieldMap.exists(member.name) || TemplateBuilder.fieldMap.get(member.name) == false) {
                        continue;
                    }

                    var field = ['this', name].drill();
                    var frun = FieldType.FFun({
                        ret: macro :String,
                        params: [],
                        expr: macro return ${field.assign('value'.resolve())},
                        args: [{name: 'value', type: null, opt: false, value: null }]
                    });

                    var setter = {
                        kind: frun,
                        meta: [],
                        name: 'set_$name',
                        doc: null,
                        pos: Context.currentPos(),
                        access: [APrivate]
                    };
                    newFields.push(setter);

                    member.addMeta(':isVar', member.pos);
                    member.kind = FProp('default', 'set_$name', cType, expr);
                default:
            }
        }

        return fields.concat(newFields);
    }

    static function findViewFields(field: Field) {
        return switch (field.kind) {
            case FieldType.FFun(func):
                if (field.meta.toMap().exists(':prerender')) {
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
                    throw new SyntaxException('Cannot preprocess elements that have a dynamic signature ("${paramArray[0]}").');
            }
        } else {
            throw new SyntaxException('Cannot preprocess elements that have no parameters');
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
                    childrenExpr = macro starlight.view.VirtualElementTools.buildChildren(untyped ${paramArray[1]});

                //  e('signature', [])
                case {expr: EArrayDecl(_), pos: _}:
                    childrenExpr = paramArray[1];
                //  e('signature', ?) -> Assume that the parameter is to be interpreted as a child textNode
                case {expr: EConst(CString(s)), pos: ePos}:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                case {expr: EConst(CIdent(s)), pos: ePos}:
                    var expr = buildTextElement(paramArray[1]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
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
                    throw 'Invalid attributes: ${paramArray[1]}';
            }

            switch(paramArray[2]) {
                //  e('signature', ?, [])
                case {expr: EArrayDecl(_), pos: _}:
                    childrenExpr = paramArray[2];
                //  e('signature', ?, func())
                case {expr: ECall(_), pos: _}:
                    matchChildren = false;
                    childrenExpr = macro starlight.view.VirtualElementTools.buildChildren(untyped ${paramArray[2]});
                //  e('signature', ?, ?)
                case {expr: _, pos: ePos}:
                    var expr = buildTextElement(paramArray[2]);
                    childrenExpr = {expr: EArrayDecl([expr]), pos: ePos};
                default:
                    throw 'Invalid children: ${paramArray[2]}';
            }
        }

        var virtualElement = VirtualElementTools.parseSignature(signature);

        var tagName = Context.makeExpr(virtualElement.tag, tagPos);
        var attrObjectFields = new ObjectFieldSet();
        var classObjectFields = new ObjectFieldSet();
        var classes = new Array<String>();
        var classPos = tagPos;

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
                                throw new TypeException('Don\'t know how to handle ${Type.getClassName(s)}');
                        }
                    default:
                        throw new TypeException('Don\'t know how to handle ${Type.typeof(value)}');
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
                            classObjectFields.push({field:field.field, expr:field.expr });
                            classPos = oPos;
                        }
                    default:
                        if (classes.length > 0) {
                            throw new SyntaxException("Cannot combine class statement with selector-specified classes.");
                        }
                        // Here we assume that if it's not an object then it will result in a string.
                        attrObjectFields.push(value);
                };
            } else if (key.indexOf('on') == 0) {
                switch(value.expr) {
                    case {expr: ECall({expr: EConst(CIdent('setValue')), pos: iPos}, params), pos: cPos}:
                        value.expr = {
                            expr: ECall(
                                {expr: EConst(CIdent('setValue')), pos: iPos},
                                [for (p in params) convertPropertyReferenceToSetterForEvents(p)]
                            ),
                            pos: cPos
                        };
                    default:
                };
                attrObjectFields.push(value);
            } else {
                attrObjectFields.push(value);
            }
        }

        if (classes.length > 0 || classObjectFields.length > 0) {
            for (cls in classes) {
                classObjectFields.push({
                    field:cls,
                    expr:macro true
                });
            }
            var classExpr = {expr: EObjectDecl(classObjectFields),
                pos: classPos
            }

            attrObjectFields.push({
                field:'class',
                expr: macro starlight.view.VirtualElementTools.buildClassString(untyped ${classExpr})
            });
        }

        var attrExpr = {expr: EObjectDecl(attrObjectFields),
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

    static function convertPropertyReferenceToSetterForEvents(param:Expr) {
        var eventTarget:Expr;

        switch(param) {
            case {expr: EConst(CIdent(potentialProperty)), pos:pPos}:
                if (TemplateBuilder.fieldMap.exists(potentialProperty)) {
                    if (TemplateBuilder.fieldMap.get(potentialProperty) == false) {
                        TemplateBuilder.fieldMap.set(potentialProperty, true);
                    }
                    eventTarget = {expr: EConst(CIdent('set_$potentialProperty')), pos:pPos}
                } else {
                    Context.warning('calling setValue($potentialProperty) where "$potentialProperty" is not a field of this class;', pPos);
                    eventTarget = {expr: EConst(CIdent(potentialProperty)), pos:pPos};
                }
            default:
                param;
        }

        return eventTarget;
    }

    static function makeField(key, value) {
        return {
            field: key,
            expr: macro '$value'
        };
    }

    #end
}
