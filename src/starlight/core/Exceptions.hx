package starlight.core;

/*
 * Used to express improper Type usage at runtime.
 */
abstract TypeException(String) {
    public inline function new(i:String) {
        this = i;
    }
}
