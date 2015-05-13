package todomvc;

import starlight.view.View in SLView;
import starlight.router.HistoryManager;
import js.html.InputElement;
import js.html.DOMElement;

using starlight.core.StringTools;
using starlight.core.ArrayTools;

class View extends SLView {
    static inline var ENTER_KEY = 13;
    static inline var ESCAPE_KEY = 27;

    public var filter:String = 'all';
    var editingIndex:Int = -1;
    var todos:Array<Todo> = new Array<Todo>();
    var store:Store<Todo>;

    public function new(store:Store<Todo>) {
        super();

        this.store = store;
        todos = this.store.findAll();
    }

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

    function onNewTodoKeyUp(evt:js.html.KeyboardEvent) {
        var el:InputElement = cast evt.target;
        var val:String = el.value;

        if (evt.which != ENTER_KEY || val == "") {
            return;
        }

        var todo = new Todo(val);

        if(store.add(todo)) {
            todos.push(todo);
        }

        el.value = '';
        render();
    }

    function onToggleAllChange(evt:Dynamic) {
        var el:InputElement = cast evt.target;

        var isChecked = el.checked;

        store.overwrite(
            todos.map(function (todo:Todo):Todo {
                todo.completed = isChecked;
                return todo;
            })
        );

        render();
    }

    function onClearClick(evt:Dynamic) {
        if (store.overwrite(getActiveTodos())) {
            todos = store.findAll();
        }
        filter = 'all';
        render();
    }

    function onToggleChangeFactory(index:Int) {
        return function onToggleChange(evt:Dynamic) {
            var el:InputElement = cast evt.target;
            todos[index].completed = el.checked;
            store.update(todos[index]);
            render();
        }
    }

    function onLabelClickFactory(index:Int) {
        return function onLabelClick(evt:Dynamic) {
            editingIndex = index;
            render();
        }
    }

    function onEditKeyUp(evt:Dynamic) {
        if (evt.which == ENTER_KEY) {
            evt.target.blur();
        }

        if (evt.which == ESCAPE_KEY) {
            evt.target.dataset.abort = 'true';
            evt.target.blur();
        }
    }

    function onEditBlurFactory(index:Int) {
        return function onEditBlur(evt:Dynamic) {
            var el:InputElement = cast evt.target;
            var val = el.value.trim();

            editingIndex = -1;

            if (evt.target.dataset.abort == 'true') {
                evt.target.dataset.abort = 'false';
                el.value = todos[index].title;
                render();
                return;
            }

            if (val != '') {
                todos[index].title = val;
                store.update(todos[index]);
            } else {
                if (store.remove(todos[index].id)) {
                    todos.splice(index, 1);
                }
            }

            render();
        }
    }

    function onDestroyClickFactory(index:Int) {
        return function onDestroyClick(evt:Dynamic) {
            var el:js.html.DOMElement = cast evt.target;
            if (store.remove(todos[index].id)) {
                todos.splice(index, 1);
            }
            render();
        }
    }

    @:view
    inline function filterEntry(item) {
        return e('li', [
            e('a', {href:"#/" + item, "class":{selected: filter == item}}, item.toUpperCase())
        ]);
    }

    @:view
    override function view() {
        var currentTodos = getFilteredTodos();
        var todoCount = todos.length;
        var activeTodoCount = getActiveTodos().length;
        var completedTodos = todoCount - activeTodoCount;
        var filters = ['all', 'active', 'completed'];

        function itemView(item:Todo, ?index:Int) {
            return e('li', {
                    "data-id":item.id,
                    "class":{completed: item.completed, editing: index == editingIndex}
                }, [
                    e('div.view', [
                        e('input.toggle', {
                            type:"checkbox",
                            checked: item.completed,
                            onchange: onToggleChangeFactory(index)
                        }),
                        e('label', {onclick: onLabelClickFactory(index)}, item.title),
                        e('button.destroy', {onclick: onDestroyClickFactory(index)})
                    ]),
                    if (index == editingIndex)
                        e('input.edit', {
                            value: item.title,
                            onkeyup: onEditKeyUp,
                            onblur: onEditBlurFactory(index),
                            focus: true,
                            select: true
                        })
                    else
                        ''
                ]);
        }

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
                e('section#main', {"class":{hidden: todoCount == 0}}, [
                    e('input#toggle-all', {"type":"checkbox", onchange:onToggleAllChange}),
                    e('label', {"for":"toggle-all"}, "Mark all as complete"),
                    e('ul#todo-list', currentTodos.mapi(itemView))
                ]),
                e('footer#footer', {"class":if (todoCount == 0) "hidden" else ""}, [
                    e('span#todo-count', [
                        e('strong', activeTodoCount),
                        if (activeTodoCount != 1) ' items left' else ' item left'
                    ]),
                    e('ul#filters', filters.map(filterEntry)),
                    e('button#clear-completed',
                      {
                        "class":{hidden: completedTodos == 0},
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
}

class App {
    static function main() {
        var store = new Store<Todo>('todomvc');
        var view = new View(store);

        var manager = new HistoryManager(function (newHash, oldHash) {
            view.filter = newHash;
            view.render();
        });
        manager.init('/all');
    }
}
