package todomvc;

import starlight.lens.Lens;
import js.html.InputElement;
import js.html.DOMElement;

using StringTools;

class App extends Lens {
    static inline var ENTER_KEY = 13;

    public var filter:String = 'all';
    var editingIndex:Int = -1;
    var todos:Array<Todo> = new Array<Todo>();

    function getFilteredTodos() {
        return todos.filter(function(todo) {
            return switch (filter) {
                case 'all': true;
                case 'completed': todo.completed;
                case 'active': !todo.completed;
                default: true;
            }
        });
    }

    function getActiveTodos() {
        return todos.filter(function(todo) {
            return !todo.completed;
        });
    }

    function findParent(el:DOMElement, parentTagName:String) {
        el = el.parentElement;
        parentTagName = parentTagName.toUpperCase();

        while (true) {
            if (el.tagName == parentTagName) {
                return el;
            }

            el = el.parentElement;

            if (el == js.Browser.document.body) {
                throw "No element by that tag.";
            }
        }
    }

    function indexFromEl(el:DOMElement) {
        var id:Int = Std.parseInt(findParent(el, 'li').dataset.id);
        var i = todos.length;

        while (i-- != 0) {
            if (todos[i].id == id) {
                return i;
            }
        }
        return -1;
    }

    public function onNewTodoKeyUp(evt:js.html.KeyboardEvent) {
        var _input = cast(evt.target, InputElement);
        var val:String = _input.value;

        if (evt.which != ENTER_KEY || val == "") {
            return;
        }

        var todo = new Todo(val);

        // if(store.add(todo)) {
            todos.push(todo);
        // }

        _input.value = '';
        render();
    }

    function onToggleAllChange(evt:Dynamic) {
        var el = cast(evt.target, js.html.InputElement);

        var isChecked = el.checked;

        for (todo in todos) {
            todo.completed = isChecked;
        }
        // store.overwrite(
        // todos = todos.map(function (todo:Todo):Todo {
        //     todo.completed = isChecked;
        //     return todo;
        // });
        // );

        render();
    }

    function onClearClick(evt:Dynamic) {
        // if (store.overwrite(getActiveTodos())) {
        //     todos = store.findAll();
        // }
        todos = getActiveTodos();
        filter = 'all';
        render();
    }

    function onToggleChange(evt:Dynamic) {
        var el = cast(evt.target, js.html.InputElement);
        var i = indexFromEl(el);
        todos[i].completed = el.checked;
        // store.update(todos[i]);
        render();
    }

    function onLabelDoubleClick(evt:Dynamic) {
        var el = cast(evt.target, js.html.InputElement);
        editingIndex = indexFromEl(el);
        // var _input = new JQuery(evt.target).closest('li').addClass('editing').find('.edit');
        // _input.val(cast _input.val()).focus();
        render();
    }

    function onEditKeyUp(evt:Dynamic) {
        // if (evt.which == ENTER_KEY) {
        //     new JQuery(evt.target).blur();
        // }

        // if (evt.which == ESCAPE_KEY) {
        //     new JQuery(evt.target).data('abort', true).blur();
        // }
    }

    function onEditBlur(evt:Dynamic) {
        // var el:Element = cast evt.target;
        // var _el = new JQuery(el);
        // var val = _el.val().trim();

        // if (_el.data('abort')) {
        //     _el.data('abort', false);
        //     render();
        //     return;
        // }

        // var i = indexFromEl(el);

        // if (val != '') {
        //     todos[i].title = val;
        // } else {
        //     todos.splice(i, 1);
        // }

        // store.update(todos[i]);

        render();
    }

    function onDestroyClick(evt:Dynamic) {
        var el = cast(evt.target, js.html.DOMElement);
        var i = indexFromEl(el);
        // if (store.remove(todos[i].id)) {
            todos.splice(i, 1);
        // }
        render();
    }

    // public function bindEvents() {
    //     _newTodo.on('keyup', onNewTodoKeyUp);
    //     _toggleAll.on('change', onToggleAllChange);
    //     _footer.on('click', '#clear-completed', onClearClick);

    //     _todoList.on('change', '.toggle', onToggleChange);
    //     _todoList.on('dblclick', 'label', onLabelDoubleClick);
    //     _todoList.on('keyup', '.edit', onEditKeyUp);
    //     _todoList.on('focusout', '.edit', onEditBlur);
    //     _todoList.on('click', '.destroy', onDestroyClick);
    // }

    override public function view() {
        var todoCount = todos.length;
        var activeTodoCount = getActiveTodos().length;
        var completedTodos = todoCount - activeTodoCount;

        function itemView(index:Int, item:Todo) {
            return e('li', {"data-id":item.id, "class":if (item.completed) 'completed' else ''}, [
                e('div.view', [
                    e('input.toggle', {
                        type:"checkbox",
                        checked: item.completed,
                        onchange: onToggleChange
                    }),
                    e('label', {onDoubleClick: onLabelDoubleClick}, item.title),
                    e('button.destroy', {onclick: onDestroyClick})
                ]),
                e('input', {
                    'class': if (index == editingIndex) 'edit editing' else 'edit',
                    value: item.title,
                    onkeyup: onEditKeyUp,
                    onfocusout: onEditBlur
                })
            ]);
        }

        // var view =
        //     @section('#todoapp')
        //         @header('#header')
        //             @h1()
        //                 'todos'
        //             @input('#new-todo', placeholder="What needs to be done?", autofocus=true)
        //         @section('#main', class=if (todoCount == 0) "hidden" else "")
        //             @input('#toggle-all', type="checkbox")
        //             @label(for="toggle-all")
        //                 "Mark all as complete"
        //             @ul('#todo-list')
        //                 [for (item in todos) itemView(item)]
        //         @footer('#footer', class=if (todoCount == 0) "hidden" else "")
        //             @span('#todo-count')
        //                 @strong
        //                     activeTodoCount
        //                 if (activeTodoCount != 1) ' items left' else ' item left'
        //             @ul('#filters')
        //                 @li
        //                     @a(href="#/all", class=if (filter == 'all') "selected" else "")
        //                     "All"
        //                 @li
        //                     @a(href="#/active", class=if (filter == 'active') "selected" else "")
        //                     "Active"
        //                 @li
        //                     @a(href="#/completed", class=if (filter == 'completed') "selected" else "")
        //                     "Completed"
        //             @button('#clear-completed', class=if (completedTodos == 0) "hidden" else "")
        //                 'Clear completed (' + completedTodos + ')')
        //     @footer('#info')
        //         @p
        //             'Double-click to edit a todo'
        //         @p
        //             'Created by '
        //             @a(href="http://sindresorhus.com")
        //                 "Sindre Sorhus"
        //         @p
        //             'Ported to Starlight by '
        //             @a(href="http://github.com/explorigin")
        //                 "Timothy Farrell"

        return [
            e('section#todoapp', [
                e('header#header', [
                    e('h1', 'todos'),
                    e('input#new-todo', {
                        placeholder:"What needs to be done?",
                        autofocus:true,
                        onkeyup:onNewTodoKeyUp
                    })
                ]),
                e('section#main', {"class":if (todoCount == 0) "hidden" else ""}, [
                    e('input#toggle-all', {"type":"checkbox", onchange:onToggleAllChange}),
                    e('label', {"for":"toggle-all"}, "Mark all as complete"),
                    e('ul#todo-list', [for (i in 0...todos.length) itemView(i, todos[i])])
                ]),
                e('footer#footer', {"class":if (todoCount == 0) "hidden" else ""}, [
                    e('span#todo-count', [
                        e('strong', activeTodoCount),
                        if (activeTodoCount != 1) ' items left' else ' item left'
                    ]),
                    e('ul#filters', [
                        e('li', [
                            e('a', {href:"#/all", "class":if (filter == 'all') "selected" else ""}, "All")
                        ]),
                        e('li', [
                            e('a', {href:"#/active", "class":if (filter == 'active') "selected" else ""}, "Active")
                        ]),
                        e('li', [
                            e('a', {href:"#/completed", "class":if (filter == 'completed') "selected" else ""}, "Completed")
                        ])
                    ]),
                    e('button#clear-completed',
                      {
                        "class":if (completedTodos == 0) "hidden" else "",
                        onclick:onClearClick
                      },
                      'Clear completed (' + completedTodos + ')')
                ])
            ]),
            e('footer#info', [
                e('p', 'Double-click to edit a todo'),
                e('p', [
                    'Created by ',
                    e('a', {href:"http://sindresorhus.com"}, "Sindre Sorhus")
                ]),
                e('p', [
                    'Ported to Starlight by ',
                    e('a', {href:"http://github.com/explorigin"}, "Timothy Farrell")
                ])
            ])
        ];
    }

    static function main() {
        var app = new App();

        // Normally in Haxe, we interact with external Javascript libraries with an extern class.
        // However, small interactions can use the magic "untyped __js__()" function.
        untyped __js__("Router({'/:filter': function (filter) { app.filter = filter; app.render(); } }).init('/all')");
        untyped __js__("window.app = app");
    }
}
