package todomvc;

import js.Browser;

import starlight.view.Renderer;
import starlight.view.Component;
import starlight.router.HistoryManager;

using Lambda;

class View extends Component {
    static inline var ENTER_KEY = 13;
    static inline var ESCAPE_KEY = 27;

    public var filter = 'all';
    var editingIndex = -1;
    var todos = new Array<Todo>();
    var store:Store<Todo>;
    var newTodoValue = "";
    var editTodoValue = "";
    var abortEdit = false;
    var editBlurMethod:Void->Void;

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
        if (evt.which != ENTER_KEY || newTodoValue == "") {
            return false;
        }

        var todo = new Todo(newTodoValue);

        if(store.add(todo)) {
            todos.push(todo);
        }

        newTodoValue = '';
        return true;
    }

    function onToggleAllChange(evt:Dynamic) {
        var isChecked = evt.target.checked;

        store.overwrite(
            todos.map(function (todo:Todo):Todo {
                todo.completed = isChecked;
                return todo;
            })
        );
    }

    function onClearClick() {
        if (store.overwrite(getActiveTodos())) {
            todos = store.findAll();
        }
        filter = 'all';
    }

    function onToggleChange(index:Int, evt:Dynamic) {
        todos[index].completed = evt.target.checked;
        store.update(todos[index]);
    }

    function onLabelClick(index:Int) {
        editingIndex = index;
        abortEdit = false;
        editTodoValue = todos[index].title;
        editBlurMethod = onEditBlur.bind(index);
    }

    function onEditKeyUp(evt:Dynamic) {
        if (evt.which != ENTER_KEY && evt.which != ESCAPE_KEY) {
            return false;
        }

        if (evt.which == ESCAPE_KEY) {
            abortEdit = true;
        }

        editBlurMethod();
        return true;
    }

    function onEditBlur(index:Int) {
        var val = (untyped editTodoValue).trim();  // Use ES5 String.trim

        editingIndex = -1;

        if (abortEdit) {
            abortEdit = false;
            trace('resetting todoValue');
            editTodoValue = todos[index].title;
        } else if (val != '') {
            todos[index].title = val;
            store.update(todos[index]);
        } else {
            if (store.remove(todos[index].id)) {
                todos.splice(index, 1);
            }
        }
    }

    function onDestroyClick(index:Int) {
        if (store.remove(todos[index].id)) {
            todos.splice(index, 1);
        }
    }

    @:prerender
    override function template() {
        var currentTodos = getFilteredTodos();
        var todoCount = todos.length;
        var activeTodoCount = getActiveTodos().length;
        var completedTodos = todoCount - activeTodoCount;
        var filters = [
            {name:'all', label:'All'},
            {name:'active', label:'Active'},
            {name:'completed', label:'Completed'}
        ];

        function filterEntry(item) {
            return e('li', [
                e('a', {href:"#/" + item.name, "class":{selected: filter == item.name}}, item.label)
            ]);
        }

        function itemView(index:Int, item:Todo) {
            return e('li', {
                    "data-id":item.id,
                    "class":{completed: item.completed, editing: index == editingIndex}
                }, [
                    e('div.view', [
                        e('input.toggle', {
                            type:"checkbox",
                            checked: item.completed,
                            onchange: onToggleChange.bind(index)
                        }),
                        e('label', {onclick: onLabelClick.bind(index)}, item.title),
                        e('button.destroy', {onclick: onDestroyClick.bind(index)})
                    ]),
                    if (index == editingIndex)
                        e('input.edit', {
                            value: editTodoValue,
                            onkeyup: onEditKeyUp,
                            onchange:setValue(editTodoValue),
                            onblur: editBlurMethod,
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
                        onkeyup:onNewTodoKeyUp,
                        onchange:setValue(newTodoValue),
                        value:newTodoValue
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

        var r = new Renderer([{
            component: view,
            root: Browser.document.body
        }]);
        r.start();

        var manager = new HistoryManager(function (newHash, oldHash) {
            view.filter = newHash;
            view.checkState();
        });
        manager.init('/all');
    }
}
