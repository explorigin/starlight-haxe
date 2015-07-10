package starlight.view;

class WidgetSet {
    public static macro function list(items, tmpl, options) {
        return macro starlight.view.macro.ElementBuilder.e(
            "ul",
            $options,
            (untyped $items).map($tmpl)
        );
    }
}
