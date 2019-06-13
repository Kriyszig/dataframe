module magpie.index;

/++
Structure for DataFrame Indexing
+/
struct Index
{
private:
    struct Indexing
    {
        string[] titles;
        string[][] index;
        int[][] codes;
    }

public:
    /// To know if data is multi-indexed
    bool isMultiIndexed = false;

    /// Row and Column indexing
    Indexing[2] indexing;

    /// Referring Index.indexing[0] as Index.row
    ref row()
    {
        return indexing[0];
    }

    /// Referring Index.indexing[1] as Index.column
    ref column()
    {
        return indexing[1];
    }

    /++
    void optimize()
    Description: Optimizes a DataFrame - If row.index can be expressed as integer, converts string row.index to int and stores in the codes
    +/
    void optimize()
    {
        foreach(k; 0 .. 2)
        {
            foreach(i; 0 .. indexing[k].index.length)
            {
                import std.conv: to, ConvException;
                if(indexing[k].index[i].length > 0)
                {
                    try
                    {
                        import std.array: appender;
                        auto inx = appender!(string[]);
                        foreach(j; 0 .. indexing[k].codes[i].length)
                            inx.put(indexing[k].index[i][indexing[k].codes[i][j]]);
                        int[] codes = to!(int[])(inx.data);
                        indexing[k].codes[i] = codes;
                        indexing[k].index[i] = [];
                    }
                    catch(ConvException e)
                    {
                        import magpie.helper: sortIndex;
                        sortIndex(indexing[k].index[i], indexing[k].codes[i]);
                    }
                }
            }
        }
    }

    /++
    void setIndex(Args...)(Args args)
    Description: Method for etting row.index
    @params: rowindex - Can be a 1D or 2D array of int or string
    @params: rowindexTitles - 1D array of string
    @params?: columnindex - Can be a 1D or 2D array of int or string
    @params?: columnIndexTitles - 1D array of string
    +/
    void setIndex(Args...)(Args args)
        if(Args.length > 1 && Args.length < 5)
    {
        this = Index();

        static foreach(j; 0 .. 2)
        {
            static if(Args.length > 2 * j)
            {
                static if(is(Args[j * 2] == string[]))
                {
                    indexing[j].index = [args[j * 2]];
                    indexing[j].codes = [[]];
                    foreach(i; 0 .. args[j * 2].length)
                        indexing[j].codes[0] ~= cast(int)i;
                }
                else static if(is(Args[j * 2] == int[]))
                {
                    indexing[j].codes = [args[j * 2]];
                    indexing[j].index = [[]];
                }
                else static if(is(Args[j* 2] == string[][]))
                {
                    assert(args[j * 2].length > 0, "Can't construct index from empty array");
                    assert(args[j * 2][0].length > 0, "Inner dimension cannot be 0");
                    foreach(i; 0 .. args[j * 2].length)
                        assert(args[j * 2][i].length == args[j * 2][0].length && args[j * 2][0].length > 0, "Inner dimension of indexes are unequal");
                    
                    foreach(i; 0 .. args[j * 2].length)
                    {
                        indexing[j].index ~= [[]];
                        indexing[j].codes ~= [[]];
                        foreach(k; 0 .. args[j * 2][i].length)
                        {
                            import std.algorithm: countUntil;
                            int pos = cast(int)countUntil(indexing[j].index[i], args[j * 2][i][k]);
                            if(pos > -1)
                            {
                                indexing[j].codes[i] ~= pos;
                            }
                            else
                            {
                                indexing[j].index[i] ~= args[j * 2][i][k];
                                indexing[j].codes[i] ~= cast(int)indexing[j].index[i].length - 1;
                            }
                        }
                    }
                }
                else static if(is(Args[j * 2] == int[][]))
                {
                    assert(args[j * 2].length > 0, "Can't construct index from empty array");
                    size_t len = args[j * 2][0].length;
                    assert(len > 0, "Inner dimension cannot be 0");
                    foreach(i; 0 .. args[j * 2].length)
                        assert(args[j * 2][i].length == len, "Inner dimension of index not equal");
                    indexing[j].codes = args[j * 2];
                    foreach(i; 0 .. args[j * 2].length)
                        indexing[j].index ~= [[]];
                }
            }

            static if(Args.length > j * 2 + 1)
                indexing[j].titles = args[j*2 + 1];
        }
        

        optimize();
    }

    /++
    void extend(int axis, T)(T next)
    Description:Extends row.index
    @params: axis - 0 for rows, 1 for column.index
    @params: next - The element to extend element
    +/
    void extend(int axis, T)(T next)
    {
        static if(is(T == int[]))
        {
            
            assert(next.length == indexing[axis].codes.length, "Index depth mismatch");
            foreach(i; 0 .. indexing[axis].codes.length)
            {
                if(indexing[axis].index[i].length == 0)
                    indexing[axis].codes[i] ~= next[i];
                else
                {
                    import std.conv: to, ConvException;
                    import std.algorithm: countUntil;
                    string ele = to!string(next[i]);
                    int pos = cast(int)countUntil(indexing[axis].index[i], ele);

                    if(pos > -1)
                    {
                        indexing[axis].codes[i] ~= pos;
                    }
                    else
                    {
                        indexing[axis].index[i] ~= ele;
                        indexing[axis].codes[i] ~= cast(int)indexing[axis].index[i].length - 1;
                    }
                }
            }
        }
        else static if(is(T == string[]))
        {
            assert(next.length == indexing[axis].codes.length, "Index depth mismatch");
            foreach(i; 0 .. indexing[axis].codes.length)
            {
                if(indexing[axis].index[i].length > 0)
                {
                    import std.algorithm: countUntil;
                    int pos = cast(int)countUntil(indexing[axis].index[i], next[i]);

                    if(pos > -1)
                    {
                        indexing[axis].codes[i] ~= pos;
                    }
                    else
                    {
                        indexing[axis].index[i] ~= next[i];
                        indexing[axis].codes[i] ~= cast(int)indexing[axis].index[i].length - 1;
                    }
                }
                else
                {
                    import std.conv: to, ConvException;
                    try
                    {
                        int ele = to!int(next[i]);
                        indexing[axis].codes[i] ~= ele;
                    }
                    catch(ConvException e)
                    {
                        indexing[axis].index[i] = to!(string[])(indexing[axis].codes[i]);
                        indexing[axis].index[i] ~= next[i];
                        indexing[axis].codes[i] = [];
                        foreach(j; 0 .. indexing[axis].index[i].length)
                            indexing[axis].codes[i] ~= cast(int)j;
                    }
                }
            }
            
        }
        else
        {
            foreach(i; 0 .. next.length)
                extend!axis(next[i]);
        }
        optimize();
    }
}

// Optmization test
unittest
{
    Index inx;
    inx.row.index = [["B", "A"], ["1", "2"]];
    inx.row.codes = [[0, 1], [0, 1]];
    inx.column.index = [["B", "A"], ["1", "2"]];
    inx.column.codes = [[0, 1], [0, 1]];

    inx.optimize();

    assert(inx.row.index == [["A", "B"], []]);
    assert(inx.row.codes == [[1, 0], [1, 2]]);
    assert(inx.column.index == [["A", "B"], []]);
    assert(inx.column.codes == [[1, 0], [1, 2]]);
}

// Setting integer row index
unittest
{
    Index inx;
    inx.setIndex([1,2,3,4,5,6], ["Index"]);
    assert(inx.row.index == [[]]);
    assert(inx.row.titles == ["Index"]);
    assert(inx.row.codes == [[1,2,3,4,5,6]]);
}

// Setting string row index
unittest
{
    Index inx;
    inx.setIndex(["Hello", "Hi"], ["Index"]);
    assert(inx.row.index == [["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index"]);
    assert(inx.row.codes == [[0, 1]]);
}

// Setting 2D integer index for rows
unittest
{
    Index inx;
    inx.setIndex([[1,2], [3,4]], ["Index", "Index"]);
    assert(inx.row.index == [[], []]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[1,2], [3,4]]);
}

// Setting 2D string index for rows
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[0,1], [1,0]]);
}

// Setting integer column row.index
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"], [1,2,3,4,5]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[0,1], [1,0]]);
    assert(inx.column.index == [[]]);
    assert(inx.column.codes == [[1,2,3,4,5]]);
    assert(inx.column.titles == []);
}

// Setting string column index
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"], ["Hello", "Hi"]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[0,1], [1,0]]);
    assert(inx.column.index == [["Hello", "Hi"]]);
    assert(inx.column.codes == [[0, 1]]);
    assert(inx.column.titles == []);
}

// Setting 2D string index for column.index
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"], [["Hello", "Hi"], ["Hi", "Hello"]]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[0,1], [1,0]]);
    assert(inx.column.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.column.codes == [[0,1], [1,0]]);
    assert(inx.column.titles == []);
}

// Setting 2D integer index for column.index
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"],[[1,2], [3,4]]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[0,1], [1,0]]);
    assert(inx.column.index == [[], []]);
    assert(inx.column.codes == [[1,2], [3,4]]);
}

// Setting column titles
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"],
        [["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.titles == ["Index", "Index"]);
    assert(inx.row.codes == [[0,1], [1,0]]);
    assert(inx.column.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.column.codes == [[0,1], [1,0]]);
    assert(inx.column.titles == ["Index", "Index"]);
}

// Extending row.index 
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"],
        [["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"]);
    inx.extend!0(["Hello", "Hi"]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.codes == [[0,1,0], [1,0,1]]);
    inx.extend!1(["Hello", "Hi"]);
    assert(inx.column.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.column.codes == [[0,1,0], [1,0,1]]);
}

// Extending row.index that require int to be converted to string
unittest
{
    Index inx;
    inx.setIndex([1,2,3], ["Index"], [1,2,3]);
    assert(inx.row.codes == [[1,2,3]]);
    assert(inx.row.index == [[]]);
    assert(inx.column.codes == [[1,2,3]]);
    assert(inx.column.index == [[]]);

    // Appending string to integer row.index
    inx.extend!0(["Hello"]);
    assert(inx.row.index == [["1","2","3","Hello"]]);
    assert(inx.row.codes == [[0,1,2,3]]);

    // Appending integer to integer row.index
    inx.extend!1([4]);
    assert(inx.column.index == [[]]);
    assert(inx.column.codes == [[1,2,3,4]]);

    // Appending string to integer row.index
    inx.extend!1(["Hello"]);
    assert(inx.column.index == [["1","2","3","4","Hello"]]);
    assert(inx.column.codes == [[0,1,2,3,4]]);

    // Checking if optimize() is working
    inx.extend!1(["Arrow"]);
    assert(inx.column.index == [["1","2","3","4","Arrow","Hello"]]);
    assert(inx.column.codes == [[0,1,2,3,5,4]]);
}

// Extending row.index with 2D array
unittest
{
    Index inx;
    inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"],
        [["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"]);
    inx.extend!0([["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.row.codes == [[0,1,0,0], [1,0,1,1]]);
    inx.extend!1([["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.column.index == [["Hello", "Hi"], ["Hello", "Hi"]]);
    assert(inx.column.codes == [[0,1,0,0], [1,0,1,1]]);
}
