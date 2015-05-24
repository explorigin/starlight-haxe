package starlight.view;

import starlight.core.Types.UnsafeMap;

typedef VirtualElementAttributes = UnsafeMap;
typedef VirtualElementChildren = Array<VirtualElement>;
typedef VirtualElement = {
    tag:String,
    ?children:VirtualElementChildren,
    ?id:Int,
    ?attrs:VirtualElementAttributes,
    ?textValue:String
}
