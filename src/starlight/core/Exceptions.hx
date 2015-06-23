package starlight.core;

/*
 * Used to express improper Type usage.
 */
abstract TypeException(String) {
    public inline function new(i:String) {
        this = i;
    }
}


/*
 * Used to express conflicting syntax.
 */
abstract SyntaxException(String) {
    public inline function new(i:String) {
        this = i;
    }
}


/*
 * Used to express improper Subclass usage.
 */
abstract AbstractionException(String) {
    public inline function new(i:String) {
        this = i;
    }
}


/*
 * Used to express a missing feature.
 */
abstract NotImplementedException(String) {
    public inline function new(i:String) {
        this = i;
    }
}
