cite about-plugin
about-plugin 'alias "http" to SimpleHTTPServer'

# Start an HTTP server from a directory, optionally specifying the port
function server() {
    # Get port (if specified)
    local port="${1:-8000}"

    # Open in the browser
    open "http://localhost:${port}/"

    # Redefining the default content-type to text/plain instead of the default
    # application/octet-stream allows "unknown" files to be viewable in-browser
    # as text instead of being downloaded.
    #
    # Unfortunately, "python -m SimpleHTTPServer" doesn't allow you to redefine
    # the default content-type, but the SimpleHTTPServer module can be executed
    # manually with just a few lines of code.
    if [ $(uname) = "Linux" ]
    then
        #alias http='python2 -m SimpleHTTPServer'
        python2 -c $'import SimpleHTTPServer;\nSimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map[""] = "text/plain";\nSimpleHTTPServer.test();' "$port"
    else
        #alias http='python -m SimpleHTTPServer'
        python -c $'import SimpleHTTPServer;\nSimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map[""] = "text/plain";\nSimpleHTTPServer.test();' "$port"
    fi
}

function pyedit() {
    about 'opens python module in your EDITOR'
    param '1: python module to open'
    example '$ pyedit requests'
    group 'python'

    xpyc=`python -c "import sys; stdout = sys.stdout; sys.stdout = sys.stderr; import $1; stdout.write($1.__file__)"`

    if [ "$xpyc" == "" ]; then
        echo "Python module $1 not found"
        return -1

    elif [[ $xpyc == *__init__.py* ]]; then
        xpydir=`dirname $xpyc`;
        echo "$EDITOR $xpydir";
        $EDITOR "$xpydir";
    else
        echo "$EDITOR ${xpyc%.*}.py";
        $EDITOR "${xpyc%.*}.py";
    fi
}
