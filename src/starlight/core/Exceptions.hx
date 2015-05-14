package starlight.core;

/*
 * Used to express improper Type usage at runtime.
 */
abstract TypeException(String) {
    public inline function new(i:String) {
        this = i;
    }
}

/*
 * Used to express improper Type usage at runtime.
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
