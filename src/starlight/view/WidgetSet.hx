package starlight.view;

import starlight.view.macro.ElementBuilder.e;

class WidgetSet {
    public static macro function list(items, tmpl, options) {
        return macro e(
            "ul",
            $options,
            (untyped $items).map($tmpl)
        );
    }
}
