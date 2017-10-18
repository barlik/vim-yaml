" Make sure Python is ready
if !has("python3")
    echo "vim has to be compiled with +python to run this"
    finish
endif

python3 << endpython
from yaml import events, nodes, compose

def search(filename, x, y):
    f = open(filename, 'r')
    parsed = compose(f)

    return _search(parsed, x, y)

def _search(obj: nodes.Node, x, y, path=None):
    if path is None:
        path = ''

    if not obj:
        return None

    if isinstance(obj, nodes.ScalarNode):
        # print("SCALAR: %s (%s)" % (obj.value, path))
        s = obj.start_mark
        e = obj.end_mark
        if s.line <= x-1 <= e.line and s.column <= y-1 <= e.column:
            # FOUND
            return path

    elif isinstance(obj, nodes.SequenceNode):
        ret = _search(obj.value, x, y, path)
        if ret:
            return ret

    elif isinstance(obj, list):
        # print("LIST %s" % str(len(obj)))
        for i, o in enumerate(obj):
            ret = _search(o, x, y, path + "[%d]" % (i))
            if ret:
                return ret

    elif isinstance(obj, tuple):
        # key
        node, mapping = obj

        s = node.start_mark
        e = node.end_mark
        if s.line <= x-1 <= e.line and s.column <= y-1 <= e.column:
            # FOUND
            return path + str(node.value)

        ret = _search(mapping, x, y, path + str(node.value))
        if ret:
            return ret

    elif isinstance(obj, nodes.MappingNode):
        # print("MAP")
        for o in obj.value:
            ret = _search(o, x, y, path + ".")
            if ret:
                return ret
    else:
        print(type(obj))
        # import ipdb; ipdb.set_trace()

def current_word():
    return vim.eval("expand('<cWORD>')")

def current_file():
    return vim.eval("expand('%:p')")

def pos():
    return int(vim.eval("line('.')")), int(vim.eval("col('.')"))

def return_path():
    x, y = pos()
    ret = search(current_file(), x, y)
    if ret:
        # vim.command("let s:out='%s'" % ret)
        vim.command("let @*='%s'" % ret)
        print(ret)

endpython

nnoremap <silent> <Leader>K :python3 return_path()<CR>
