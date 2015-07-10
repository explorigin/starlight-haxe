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
#end

class PropertyBuilder {
    public static var fieldMap = new haxe.ds.StringMap<Bool>();

    #if macro
    macro static public function build(): Array<Field> {
        var fields = Context.getBuildFields();
        for (field in fields) {
            switch(field.kind) {
                case FProp(_, _, _, _):
                    PropertyBuilder.fieldMap.set(field.name, true);
                default:
                    PropertyBuilder.fieldMap.set(field.name, false);
            }
        }

        return convertVarsToProperties(fields.map(traverseFunctionCalls.bind(matchSetValueCalls)));
    }

    static function convertVarsToProperties(fields: Array<Field>):Array<Field> {
        var newFields = new Array<Field>();

        for (member in fields) {
            switch (member.kind) {
                case FieldType.FVar(cType, expr):
                    var name = member.name;

                    if (!PropertyBuilder.fieldMap.exists(member.name) || PropertyBuilder.fieldMap.get(member.name) == false) {
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

    static function matchSetValueCalls(e: Expr):Expr {
        switch (e) {
            case {expr: ECall({expr: EConst(CIdent('setValue')), pos: iPos}, params), pos: cPos}: {
                if (params.length != 1) {
                    Context.error("setValue called with wrong number of parameters.", cPos);
                }
                e = {
                    expr: ECall(
                        {expr: EConst(CIdent('setValue')), pos: iPos},
                        [for (p in params) convertPropertyReferenceToSetterForEvents(p)]
                    ),
                    pos: cPos
                };
            }
            default:
        }
        return e.map(matchSetValueCalls);
    }

    static function traverseFunctionCalls(mapper, field: Field) {
        return switch (field.kind) {
            case FieldType.FFun(func):
                func.expr = func.expr.map(mapper);
                field;
            default: field;
        };
    }

    static function convertPropertyReferenceToSetterForEvents(e:Expr) {
        var eventTarget:Expr;

        switch(e) {
            case {expr: EConst(CIdent(potentialProperty)), pos:pPos}:
                if (PropertyBuilder.fieldMap.exists(potentialProperty)) {
                    if (PropertyBuilder.fieldMap.get(potentialProperty) == false) {
                        PropertyBuilder.fieldMap.set(potentialProperty, true);
                    }
                    eventTarget = {expr: EConst(CIdent('set_$potentialProperty')), pos:pPos}
                } else {
                    Context.warning('calling setValue($potentialProperty) where "$potentialProperty" is not a field of this class;', pPos);
                    eventTarget = {expr: EConst(CIdent(potentialProperty)), pos:pPos};
                }
            default:
                e;
        }

        return eventTarget;
    }

    #end
}
