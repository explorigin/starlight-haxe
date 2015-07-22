package starlight.view;

import haxe.macro.Expr;
import starlight.core.Exceptions.TypeException;

using Lambda;

class WidgetTools {
    public static function extractExprOption<T>(objExpr:ExprOf<{}>, fieldName, defaultValue:T):T {
        switch(objExpr) {
            case {expr: EObjectDecl(fields), pos: _}:
                for (field in fields) {
                    if (field.field != fieldName) {
                        continue;
                    }

                    return untyped switch(field.expr) {
                        case {expr: EConst(CIdent("true")), pos: _}:
                            true;
                        case {expr: EConst(CIdent("false")), pos: _}:
                            false;
                        case {expr: EConst(CString(s)), pos: _}:
                            s;
                        case {expr: EConst(CInt(i)), pos: _}:
                            i;
                        default:
                            throw new TypeException("Cannot evaluate runtime expressions.");
                    };
                }
            case {expr: EBlock([]), pos: _}:
            default:
                throw new TypeException("Must receive an object expression");
        }

        return defaultValue;
    }


    public static function removeExprFields(objExpr:ExprOf<{}>, removeFields:Array<String>) {
        switch(objExpr) {
            case {expr: EObjectDecl(fields), pos: fPos}:
                return {expr: EObjectDecl([for (f in fields) if (removeFields.indexOf(f.field) == -1) f]), pos: fPos};
            case {expr: EBlock([]), pos: oPos}:
                return {expr: EObjectDecl([]), pos: oPos};
            default:
                throw new TypeException("Must receive an object expression");
        }
    }
}
