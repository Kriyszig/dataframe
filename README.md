# Magpie - Mir Data Analysis and Processing Library

[![Build Status](https://travis-ci.org/Kriyszig/magpie.svg?branch=master)](https://travis-ci.org/Kriyszig/magpie)

DataFrame project for GSoC 2019.

The goal of the project is to deliver a DataFrame that behaves just like Pandas in Python.

## Usage

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

DataFrame!(int, 2, double, 1) df;
Index index;
index.setIndex([0,1,2,3,4,5], ["Row Index"], [0,1,2], ["Column Index"]);
df.setFrameIndex(index);
df.display();
/*
 *  Column Index  0  1  2
 *  Row Index
 *  0             0  0  nan
 *  1             0  0  nan
 *  2             0  0  nan
 *  3             0  0  nan
 *  4             0  0  nan
 *  5             0  0  nan
 */

df.assign!1(2, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
df.display();
/*
 *  Column Index  0  1  2
 *  Row Index
 *  0             0  0  1
 *  1             0  0  2
 *  2             0  0  3
 *  3             0  0  4
 *  4             0  0  5
 *  5             0  0  6
 */

df.assign!1(1, [1, 2, 3]);
df.display();
/*
 *  Column Index  0  1  2
 *  Row Index
 *  0             0  1  1
 *  1             0  2  2
 *  2             0  3  3
 *  3             0  0  4
 *  4             0  0  5
 *  5             0  0  6
 */

df.assign!0(0, 4, 5, 1.6);
df.display();
/*
 *  Column Index  0  1  2
 *  Row Index
 *  0             4  5  1.6
 *  1             0  2  2
 *  2             0  3  3
 *  3             0  0  4
 *  4             0  0  5
 *  5             0  0  6
 */

index.extend!0([6]);
df.setFrameIndex(index);
df.display();
/*
 *  Column Index  0  1  2
 *  Row Index
 *  0             4  5  1.6
 *  1             0  2  2
 *  2             0  3  3
 *  3             0  0  4
 *  4             0  0  5
 *  5             0  0  6
 *  6             0  0  nan
 */
```

## Different ways of creating a DataFrame

```d
import magpie.dataframe: DataFrame;

DataFrame!(int, 10) df;
DataFrame!(int, 10, double, 10) df;
DataFrame!(int[10], double[10]) df;
DataFrame!(int, 10, double[10]) df;

// DataFrame from Structure
struct S
{
    int[10] a;
    double[10] b;
}

import std.traits: Fields;
DataFrame!(Fields!S) df;

// In case all the fields are of primitive types, you can add
// true in the beginning to reduce compile time
DataFrame!(true, int, int, double, double) df;

struct RS
{
    int a;
    int b;
    double c;
    double d;
}

DataFrame!(Fields!(RS)) df;
```

## Structure

- The DataFrame structure is defined as:

```d
struct DataFrame(Fields)
{
    alias RowType = getArgsList!(Fields);
    alias FrameType = staticMap!(toArr, RowType);

    // Dimension of data
    size_t rows = 0;
    size_t cols = RowType.length;

    Index indx;
    FrameType data;
}
```
- Index is defined as folows:

```d
struct Index
{

    struct Indexing
    {
        string[] titles;
        string[][] index;
        int[][] codes;
    }

    /// To know if data is multi-indexed
    bool isMultiIndexed = false;

    /// Row and Column indexing
    Indexing[2] indexing;
}
```

## Features

* [Index](#Index)
* [Access](#Access)
* [Assignment](#Assignment)
* [Apply](#Apply)
* [Binary Operations](#BinaryOps)
* [Drop](#Drop)
* [Group By](#GroupBy)
* [I/O](#I/O)
* [Slice Integration](#Slice)
* [Aggregate](#Aggregate)
* [Filter](#Filter)

### Index

Index is a structure that stores the indexes as strings with a special space optimization for integer indexes.

```d
import magpie.index: Index;

// Declaration
Index indx;

// Setting Indexes
indx.setIndex([1, 2, 3, 4], ["Row Index"], [1, 2, 3], ["Column Index"]);
/*
 *  Provides the following basic skeleton for the DataFrame:
 *
 *  Column Index  1  2  3
 *  Row Index
 *  1
 *  2
 *  3
 *  4
 */
```

#### `setIndex(rowIndex, rowIndexTitles, columnIndex?, columnIndexTitles?)`

Setting indexes of an empty Index.

* rowIndex - Can be a single or two dimensional array of string or integers
* rowIndexTitles - Single Dimensional array of strings
* columnIndex[Optional] - Can be a single or two dimensional array of string or integers
* columnIndexTitles[Optional] - Single Dimensional array of strings

Usage:

```d
import magpie.index: Index;

Index inx;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["RL1", "RL2"],
             [["Hello", "Hi"], ["Hi", "Hello"]], ["CL1", "CL2"]);
/*
 *  The basic skeleton:
 *
 *         CL1    Hello  Hi
 *         CL2    Hi     Hello
 *  RL1    Rl2
 *  Hello  Hi
 *  Hi     Hello
 */
```

Note: In case the dimension of columnIndex don't match the dimension of DataFrame, the default indexing will be applied.

#### `constructFromPairs(rowIndex, rowIndexTitles, columnIndex?, columnIndexTitles?)`

Setting row indexes row wise and column indexes column wise

* rowIndex - Two dimensional array of string or integer
* rowIndexTitles - Single Dimensional array of strings
* columnIndex[Optional] - Two dimensional array of string or integers
* columnIndexTitles[Optional] - Single Dimensional array of strings

```d
import magpie.index: Index;

Index inx;
inx.constructFromPairs([["Hello", "Hi"], ["Hi", "Hello"], ["Hey", "Hey"]],
                        ["RL1", "RL2"],
                        [["Hello", "Hi"], ["Hi", "Hello"], ["Hey", "Hey"]],
                        ["CL1", "CL2"]);
/*
 *  The basic skeleton:
 *
 *         CL1    Hello  Hi     Hey
 *         CL2    Hi     Hello  Hey
 *  RL1    Rl2
 *  Hello  Hi
 *  Hi     Hello
 *  Hey    Hey
 */
```

#### `constructFromZip(axis, levels)(index, titles)`

Constructing Index from a Zip range

* axis - 0 to construct row index, 1 for constructing column index
* levels - depth of indexing
* index - Zip containing the indexes
* titles - Index titles [Mandatory for axis = 0]

```d
import magpie.index: Index;
import std.range: zip;

Index inx;
auto z = zip([1, 2, 3, 4], ["Hello", "Hi", "Hello", "Hi"]);
inx.constructFromZip!(0, 2)(z, ["Index1", "Index2"]);
/*
 *  The basic skeleton:
 *
 *  Index1  Index2
 *  1       Hello
 *  2       Hi
 *  3       Hello
 *  4       Hi
 */

auto zc = zip([1, 2, 3, 4], ["Hello", "Ho", "Hello", "Ho"]);
inx.constructFromZip!(1, 2)(zc);
/*
 *  The basic skeleton:
 *
                    1      2   3      4
 *                  Hello  Hi  Hello  Hi
 *  Index1  Index2
 *  1       Hello
 *  2       Hi
 *  3       Hello
 *  4       Hi
 */
```

#### `constructFromLevels(axis)(index, titles)`

Construct indexes based on unique levels

* axis - 0 to construct row index, 1 for constructing column index
* index - Two dimensional array of string containing unique level of indexes
* titles - Index titles [Mandatory for axis = 0]

```d
import magpie.index: Index;

Index inx;
inx.constructFromLevels!0([["Air", "Water"],
                           ["Transportation"],
                           ["Net Income", "Gross Income"]],
                          ["Index1", "Index2", "Index3"]);

/*
 *  The basic skeleton:
 *
 *  Index1  Index2          Index3
 *  Air     Transportation  Net Income
 *  Air     Transportation  Gross Income
 *  Water   Transportation  Net Income
 *  Water   Transportation  Gross Income
 */

inx.constructFromLevels!1([["Air", "Water"], ["Transportation", "What_to_put_here"], ["Net Income", "Gross Income"]]);

/*
 *  The basic skeleton:
 *                                        Air             Air             Air               Air               Water           Water           Water               Water
 *                                        Transportation  Transportation  What_to put_here  What_to_put_here  Transportation  Transportation  What_to put_here  What_to_put_here
 *  Index1  Index2          Index3        Net Income      Gross Income    Net Income        Gross Income      Net Income      Gross Income    Net Income        Gross Income
 *  Air     Transportation  Net Income
 *  Air     Transportation  Gross Income
 *  Water   Transportation  Net Income
 *  Water   Transportation  Gross Income
 */
```

#### Setting Index using Array like operation

```d
import magpie.index: Index;

Index inx;
inx[0] = ["Hello", "Hi"];
inx[1] = ["Hey"];
/*
 *  The basic skeleton:
 *         Hey
 *  Hello
 *  Hi
 */

inx[0] = [["Hello", "Hi"], ["Hey", "Hey"]];
/*
 *  The basic skeleton:
 *              Hey
 *  Hello  Hey
 *  Hi     Hey
 */
```

#### `extend(axis)(next)`

Extending indexing of a previously assigned Index.

* axis - set 0 to extend row index else set 1
* next - element to extend index (Needs to be a 1D array of string or integer)

Usage:

```d
import magpie.index: Index;

Index inx;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["RL1", "RL2"],
             [["Hello", "Hi"], ["Hi", "Hello"]], ["CL1", "CL2"]);
/*
 *  The basic skeleton:
 *
 *         CL1    Hello  Hi
 *         CL2    Hi     Hello
 *  RL1    Rl2
 *  Hello  Hi
 *  Hi     Hello
 */

inx.extend!0(["Hey", "Hey"]);
inx.extend!1(["Yo", "Yo"]);

/*
 *  The basic skeleton:
 *
 *         CL1    Hello  Hi     Yo
 *         CL2    Hi     Hello  Yo
 *  RL1    Rl2
 *  Hello  Hi
 *  Hi     Hello
 *  Hey    Hey
 */
```

#### `columnToIndex(position)() @property`

Convert a column to an indexing level

* position - integral position of column to convert to index

Usage:
```d
Index inx;
DataFrame!(double, 2) df;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["RL1", "RL2"],
            [["Hello", "Hi"], ["Hi", "Hello"]], ["CL1", "CL2"]);
df.setFrameIndex(inx);

df.assign!1(0, [1.0, 4.0]);
df.assign!1(1, [16.0, 256.0]);
df.display();
/*
 *        CL1    Hello  Hi
 *        CL2    Hi     Hello
 * RL1    RL2
 * Hello  Hi     1      16
 * Hi     Hello  4      256
 */

auto extended = df.columnToIndex!(0);
extended.display();
/*
 *               CL1  Hi
 *               CL2  Hello
 * RL1    RL2    Hi
 * Hello  Hi     1    16
 * Hi     Hello  4    256
 */
```
Note: The index from the bottom most level will be used as the new indexing level title.

### Access

In addition to array like access to elements, some of the other ways to access elements are:

#### `at!(row, column)`

Direct access to element using integral indexes

* row - Integral index of row
* column - Integral Index of column

Usage:

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

Index inx;
inx.setIndex([1, 2, 3],["rindex"]);

DataFrame!(int, 2) df;
df.setFrameIndex(inx);
df.at!(0,0);        // Will return 0
df[0, 0];           // Same as above, returns 0
df[["1"], ["0"]];   // Same as above - usig string indexes - returns 0
```
#### Getting row and column position from string indexes

#### `getRowPosition(indexes)`

Getting integer position of a row in DataFrame based on string index

* indexes - 1D array of string indexes of the row you desire

#### `getColumnPosition(indexes)`

Getting integer position of a column in DataFrame based on string index

* indexes - 1D array of string indexes of the column you desire

Usage:
```d
Index inx;
DataFrame!(int, 2) df;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["RL1", "RL2"],
            [["Hello", "Hi"], ["Hi", "Hello"]], ["CL1", "CL2"]);
df.setFrameIndex(inx);

df.getRowPosition(["Hello", "Hi"]); // 0
df.getColumnPosition(["Hi", "Hello"]); // 1
```

### Assignment

#### Direct Assignment

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

Index inx;
inx.setIndex([1, 2, 3],["rindex"]);

DataFrame!(int, 2, double) df;
df.setFrameIndex(inx);  // If column index isn't specified, default indexing takes over
df.display();
/*
 *  rindex  0  1  2
 *  1       0  0  nan
 *  2       0  0  nan
 *  3       0  0  nan
 */

df = [[1.0], [1.0, 2.0], [1.0, 2.0, 3.5]];
df.display();
/*
 *  rindex  0  1  2
 *  1       1  0  nan
 *  2       1  2  nan
 *  3       1  2  3.5
 */

// Assignment based on direct integer index
df[0, 0] = 42;
df.display();
/*
 *  rindex  0   1  2
 *  1       42  0  nan
 *  2       1   2  nan
 *  3       1   2  3.5
 */

// Assignment based on string index
df[["2"], ["1"]] = 17;
df.display();
/*
 *  rindex  0   1   2
 *  1       42  0   nan
 *  2       1   17  nan
 *  3       1   2   3.5
 */
```
Note: Direct assignment works with only 2D array. Each element will be implicitly casted to the data type of the given column.

#### `assign(axis)(index, data)`

Assign data completely or partially to a row or a column.

* axis - set 0 to assign to a row else set 1 to assign to a particular column
* index - Integer or string index of the location to assign
* data - Data to set at the particular row / column

Usage:

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

Index inx;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"],
             [["Hello", "Hi"], ["Hi", "Hello"]]);

DataFrame!(double, int) df;
df.setFrameIndex(inx);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     nan    0
 *  Hi     Hello  nan    0
 */

df.RowType ele;
ele[0] = 1.77;
ele[1] = 4;

// Using RowType alias
df.assign!0(["Hi", "Hello"], ele);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     nan    0
 *  Hi     Hello  1.77   4
 */

// Without RowType
df.assign!0(["Hi", "Hello"], 1.688, 6);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     nan    0
 *  Hi     Hello  1.688  6
 */

// Assigning usig direct index
df.assign!0(1, 1.588, 6);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     nan    0
 *  Hi     Hello  1.588  6
 */

// Assigning column
df.assign!1(["Hello", "Hi"], [1.2, 3.6]);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     1.2    0
 *  Hi     Hello  3.6    6
 */

// Assigning columns using direct index
df.assign!1(0, [1.26, 4.6]);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     1.26   0
 *  Hi     Hello  4.6    6
 */

// Partial Assignment - rows
df.assign!0(1, 3.588);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     1.26   0
 *  Hi     Hello  3.588  6
 */

// Partial Assignment - columns
df.assign!1(0, [2.26]);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     2.26   0
 *  Hi     Hello  4.6    6
 */
```
### Apply

#### `apply(Fn, axis)(index)`

Applies a function to all the elements of row/column
* Axis - 0 for row, 1 for column
* Fn - Function to apply
* index - single dimensional array of integer index or two dimensional array of string index.

Usage:

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

Index inx;
DataFrame!(double, 2) df;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["RL1", "RL2"],
            [["Hello", "Hi"], ["Hi", "Hello"]], ["CL1", "CL2"]);
df.setFrameIndex(inx);

df.assign!1(0, [1.0, 4.0]);
df.assign!1(1, [16.0, 256.0]);
df.display();
/*
 *        CL1    Hello  Hi
 *        CL2    Hi     Hello
 * RL1    RL2
 * Hello  Hi     1      16
 * Hi     Hello  4      256
 */

import std.math: sqrt;
df.apply!(sqrt, 1)([1]);
df.display();
/*
 *        CL1    Hello  Hi
 *        CL2    Hi     Hello
 * RL1    RL2
 * Hello  Hi     1      4
 * Hi     Hello  4      16
 */

df.apply!(sqrt, 0)([1]);
df.display();
/*
 *        CL1    Hello  Hi
 *        CL2    Hi     Hello
 * RL1    RL2
 * Hello  Hi     1      4
 * Hi     Hello  2      4
 */
```


### BinaryOps

DataFrame supports row and column binary operations. Supported operations:
* Assignment (Assigning values of one row/column to another)
* Addition
* Subtraction
* Multiplication
* Division

#### Usage

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

DataFrame!(int, 3) df;
Index inx;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"]);
df.setFrameIndex(inx);
df.display();
/*
 *  Index  Index  0  1  2
 *  Hello  Hi     0  0  0
 *  Hi     Hello  0  0  0
 */

df.assign!1(0, [1, 4]);
df.assign!1(1, [1, 6]);
df.assign!1(2, [1, 8]);
df.display();
/*
 *  Index  Index  0  1  2
 *  Hello  Hi     1  1  1
 *  Hi     Hello  4  6  8
 */

df[["0"]] = df[["1"]] + df[["2"]];
df.display();
/*
 *  Index  Index  0   1  2
 *  Hello  Hi     2   1  1
 *  Hi     Hello  14  6  8
 */

df[["Hello", "Hi"], 0] = df[["Hi", "Hello"], 0];
df.display();
/*
 *  Index  Index  0   1  2
 *  Hello  Hi     14  6  8
 *  Hi     Hello  14  6  8
 */
```
Note:
* For now, binary operations only work with string based indexes.
* The first argument is always an array of string [even if level of indexing is 1]
* Don't specify axis for column binary operation. Using column binary operations as `df[["0"], 1]` will not work.
* When assigning a column containing floating point number to integral one, there won't be any implicit conversion made. Please use `convertTo` function of `Axis` to convert result to the desired type before assignment.

### Drop

#### `drop(axis, positions)() @property`

`drop` can drop a row/column from the DataFrame

* axis - 0 to drop a row, 1 to drop a column
* positions - integer array of positions to drop

Usage:
```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

Index inx;
DataFrame!(double, 2) df;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["RL1", "RL2"],
            [["Hello", "Hi"], ["Hi", "Hello"]], ["CL1", "CL2"]);
df.setFrameIndex(inx);

df.assign!1(0, [1.0, 4.0]);
df.assign!1(1, [16.0, 256.0]);
df.display();
/*
 *        CL1    Hello  Hi
 *        CL2    Hi     Hello
 * RL1    RL2
 * Hello  Hi     1      16
 * Hi     Hello  4      256
 */

auto drow = df.drop!(0, [1]);
drow.display();
/*
 *        CL1  Hello  Hi
 *        CL2  Hi     Hello
 * RL1    RL2
 * Hello  Hi   1      16
 */

auto dcol = df.drop!(1, [1]);
dcol.display();
/*
 *        CL1    Hello
 *        CL2    Hi
 * RL1    RL2
 * Hello  Hi     1
 * Hi     Hello  4
 */
```

### GroupBy

`DataFrame.groupBy(dataLevels)(indexLevels)`

Group DataFrame based on arbitrary number of columns. This includes grouping based on row indexes and data columns.

* dataLevels - Integral indexes of data columns to be considered for grouping
* indexLevels - Integral indexes of row indexing level to consider for grouping

Returns: A `Group` object

#### Usage
```d
DataFrame!(int, 5) df;
Index inx;
inx.setIndex([["Hello", "Hi", "Hey"], ["Hi", "Hello", "Hey"], ["Hey", "Hello", "Hi"]], ["1", "2", "3"]);
df.setFrameIndex(inx);
df.assign!1(2, [1,2,3]);

auto gp = df.groupBy!([2])([0, 1]);
gp.display();
/*
 * Group: ["Hello", "Hi", "1"]
 * Group Dimension: [ 1 X 4 ]
 * 3    0  1  3  4
 * Hey  0  0  0  0
 * 
 * Group: ["Hi", "Hello", "2"]
 * Group Dimension: [ 1 X 4 ]
 * 3      0  1  3  4
 * Hello  0  0  0  0
 * 
 * Group: ["Hey", "Hey", "3"]
 * Group Dimension: [ 1 X 4 ]
 * 3   0  1  3  4
 * Hi  0  0  0  0
 */
```

#### Operations on `Group`

`display`

* Displays the contents of group on the terminal
* Usage: `Group.display()`

`getGroups`

* Returns a `string[][]` containing all the groups

Usage: 
```d
DataFrame!(double) df;
Index inx;
inx.constructFromLevels!(0)([["Falcon", "Parrot"], ["Captive", "Wild"]], ["Animal", "Type"]);
inx.constructFromLevels!(1)([["Max-Speed"]]);
df.setFrameIndex(inx);
df.assign!1(0, [380.0, 370.0, 24.0, 26.0]);

auto grp = df.groupBy([0]);
assert(grp.getGroups == [["Falcon"], ["Parrot"]]);
```

`combine`

Combines one or more group into a `DataFrame`

`auto combine(groupIndex)`

* groupIndex - Array of Integral or string index of groups

```d
DataFrame!(double) df;
Index inx;
inx.constructFromLevels!(0)([["Falcon", "Parrot"], ["Captive", "Wild"]], ["Animal", "Type"]);
inx.constructFromLevels!(1)([["Max-Speed"]]);
df.setFrameIndex(inx);
df.assign!1(0, [380.0, 370.0, 24.0, 26.0]);
/*
 * Animal  Type     Max-Speed
 * Falcon  Captive  380      
 * Falcon  Wild     370      
 * Parrot  Captive  24       
 * Parrot  Wild     26       
 * 
 * Dataframe Dimension: [ 5 X 3 ]
 * Data Dimension: [ 4 X 1 ]
 */

auto grp = df.groupBy([0]);
grp.display();
/*
 * Group: ["Falcon"]
 * Group Dimension: [ 2 X 1 ]
 * Type     Max-Speed
 * Captive  380      
 * Wild     370      
 * 
 * Group: ["Parrot"]
 * Group Dimension: [ 2 X 1 ]
 * Type     Max-Speed
 * Captive  24       
 * Wild     26
 */

grp.combine([0, 1]).display();
/*
 * GroupL1  Type     Max-Speed
 * Falcon   Captive  380      
 * Falcon   Wild     370      
 * Parrot   Captive  24       
 * Parrot   Wild     26       
 * 
 * Dataframe Dimension: [ 5 X 3 ]
 * Data Dimension: [ 4 X 1 ]
 */
```

#### Binary Operations on Group

Binary Operations on `Group` are carried out in the same was as that of a `DataFrame`. An `Axis` structure is used to obtain the values.
#### Usage

```d
DataFrame!(int, 5) df;
Index inx;
inx.setIndex([["Hello", "Hi", "Hey"], ["Hi", "Hello", "Hey"], ["Hey", "Hello", "Hi"]], ["1", "2", "3"]);
df.setFrameIndex(inx);
df.assign!1(2, [1,2,3]);
df.assign!1(4, [1,2,3]);

auto gp = df.groupBy!([2])(df, [0, 1]);
gp.display();
/*
 * Group: ["Hello", "Hi", "1"]
 * Group Dimension: [ 1 X 4 ]
 * 3    0  1  3  4
 * Hey  0  0  0  1
 * 
 * Group: ["Hi", "Hello", "2"]
 * Group Dimension: [ 1 X 4 ]
 * 3      0  1  3  4
 * Hello  0  0  0  2
 * 
 * Group: ["Hey", "Hey", "3"]
 * Group Dimension: [ 1 X 4 ]
 * 3   0  1  3  4
 * Hi  0  0  0  3
 */

gp[["Hello", "Hi", "1"], ["3"]] = gp[["Hello", "Hi", "1"], ["4"]];
gp[["Hello", "Hi", "1"], ["3"]] = gp[["Hello", "Hi", "1"], ["0"]] + gp[["Hello", "Hi", "1"], ["3"]] + gp[["Hello", "Hi", "1"], ["4"]];

gp.display();
/*
 * Group: ["Hello", "Hi", "1"]
 * Group Dimension: [ 1 X 4 ]
 * 3    0  1  3  4
 * Hey  0  0  2  1
 * 
 * Group: ["Hi", "Hello", "2"]
 * Group Dimension: [ 1 X 4 ]
 * 3      0  1  3  4
 * Hello  0  0  0  2
 * 
 * Group: ["Hey", "Hey", "3"]
 * Group Dimension: [ 1 X 4 ]
 * 3   0  1  3  4
 * Hi  0  0  0  3
 */
```

### I/O

#### `display(getStr = false, maxSize = 0)`

Displays the content of the dataframe on the terminal.

* getStr - If set to true, will return the evaluated display string instead of the terminal output
* maxSize - Override terminal size [Dynamically detecting terminal size isn't implemented yet]

Usage:

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

Index inx;
inx.setIndex([["Hello", "Hi"], ["Hi", "Hello"]], ["Index", "Index"],
             [["Hello", "Hi"], ["Hi", "Hello"]]);

DataFrame!(double, int) df;
df.setFrameIndex(inx);
df.display();
/*
 *                Hello  Hi
 *  Index  Index  Hi     Hello
 *  Hello  Hi     nan    0
 *  Hi     Hello  nan    0
 */

 string display_string = df.display(true);  // If set to false, will return an empty string
 string if_terminal_width_150 = df.display(true, 150);  // Assumes terminal can accommodate 150 characters
```


#### `to_csv(string path, bool writeIndex = true, bool writeColumn = true, char sep = ",")`

Writes the DataFrame to CSV format.

* writeIndex - If set true writes row indexes to the file.
* writeColumn - If set rue writes column indexes to the file
* sep - Is the data separator

Usage:

```d
df.to_csv("./test.csv");
```

#### `from_csv(string path, int indexDepth = 1, int columnDepth = 1,int[] columns = [], char sep = ',')`
<b>Will be eventually replaced with fastCSV</b>

Parsing of CSV file into a DataFrame

* indexDepth - How many columns from left do row index span
* columnDepth - How many rows from top column index span
* columns - indexes of columns to selectively parse
* sep - Data Separator

Usage:

```d
import magpie.dataframe: DataFrame;

DataFrame!(double, int, 2, double) df;
df.from_csv("any.csv", 1, 1);
/* This assumes any.csv has 1 column dedicated to row indexes
 * and 1 row dedicated to column indexes
 */
```

#### `fastCSV(string path, size_t indexDepth, size_t columnDepth, char sep = ',')` (Alpha)

Faster parser for CSV files

* indexDepth - How many columns from left do row index span
* columnDepth - How many rows from top column index span
* columns - indexes of columns to selectively parse
* sep - Data Separator

Usage:
```d
import magpie.dataframe: DataFrame;

DataFrame!(double, int, 2, double) df;
df.fastCSV("any.csv", 1, 1);
/* This assumes any.csv has 1 column dedicated to row indexes
 * and 1 row dedicated to column indexes
 */
```
<b>Note:</b> This redesign is still in an alpha stage. It doesn't support CSV with titles for column indexing levels. That said it is light years ahead of `from_csv`.

You can see the benchmarks [here](https://github.com/Kriyszig/fastCSV). Adding a large CSV file to this repository wasn't practical. Hence, fastCSV tests on large CSV file were ported out of this repository.

### Slice

This section deals with integration and interoperation of Mir's Slice and Magpie's DataFrame and Group

* DataFrame.asSlice
* Group.asSlice

In DataFrame:

#### `asSlice(Type, SliceKind)() @property`
Retrieval of the entire DataFrame. If `Type` is Algebraic, then all the numeric data is copied over to the Slice else returns a Slice of string.

### `asSlice(SliceKind, Type = string, axis = 0)`
Get a row/column of DataFrame as Slice of `Type`.

#### Usage:
```d
// Using Slice to copy value from one DataFrame to another
import magpie.dataframe: DataFrame;
import magpie.index: Index;

DataFrame!(int, 5) df;
Index inx;
inx.setIndex([["Hello", "Hi", "Hey"], ["Hi", "Hello", "Hey"], ["Hey", "Hello", "Hi"]], ["1", "2", "3"]);
df.setFrameIndex(inx);
df.assign!1(2, [1,2,3]);
df.assign!1(4, [1,2,3]);

auto dfslice = df.asSlice!(int, Contiguous);

DataFrame!(int, 5) df2;
df2.setFrameIndex(inx);

df2 = dfslice;
df2.display();
```
```d
/// Index operation on Slice
import magpie.dataframe: DataFrame;
import magpie.index: Index;

DataFrame!(int, 3, double, 2) df;
Index inx;
inx.setIndex([["Hello", "Hi", "Hey"], ["Hi", "Hello", "Hey"], ["Hey", "Hello", "Hi"]], ["1", "2", "3"]);
df.setFrameIndex(inx);
df.assign!1(2, [1,2,3]);
df.assign!1(4, [1.0, 2.0, 3.0]);

df[["1"]] = df.asSlice!(Universal, int, 1)(["4"]);
df.display();
/*
 * 1      2      3      0  1  2  3    4
 * Hello  Hi     Hey    0  1  1  nan  1
 * Hi     Hello  Hello  0  2  2  nan  2
 * Hey    Hey    Hi     0  3  3  nan  3
 * 
 * Dataframe Dimension: [ 4 X 8 ]
 * Data Dimension: [ 3 X 5 ]
 */

df[["Hello", "Hi", "Hey"], 0] = df.asSlice!(Universal)(["Hi", "Hello", "Hello"]);
df.display();
/*
 * 1      2      3      0  1  2  3    4
 * Hello  Hi     Hey    0  2  2  nan  2
 * Hi     Hello  Hello  0  2  2  nan  2
 * Hey    Hey    Hi     0  3  3  nan  3
 * 
 * Dataframe Dimension: [ 4 X 8 ]
 * Data Dimension: [ 3 X 5 ]
 */
```

In Group:

#### `asSlice(Type, SliceKind)() @property`
Get the entire Group as slice for copying. If `Type` is Algebraic, then all the numeric data is copied over to the Slice else returns a Slice of string.

#### `asSlice(Type, SliceKind)(groupTitle)`
Get a single group as Slice. If `Type` is Algebraic, then all the numeric data is copied over to the Slice else returns a Slice of string.

#### `asSlice(SliceKind kind, Type = string, int axis = 0, U)(groupTitle,index)`
Retrieve a single row or column of a particular group as Slice of type `Type`

```d
// Assign a group to another using Slice
import magpie.dataframe: DataFrame;
import magpie.index: Index;

DataFrame!(int, 5) df;
Index inx;
inx.setIndex([["Hello", "Hi", "Hey"], ["Hi", "Hello", "Hey"], ["Hey", "Hello", "Hi"]], ["1", "2", "3"]);
df.setFrameIndex(inx);
df.assign!1(2, [1,2,3]);
df.assign!1(4, [1,2,3]);

auto gp = df.groupBy!([2])([0, 1]);

gp[["Hello", "Hi", "1"]] = gp.asSlice!(int, Universal)(["Hi", "Hello", "2"]);
gp.display();
/*
 * Group: ["Hello", "Hi", "1"]
 * Group Dimension: [ 1 X 4 ]
 * 3    0  1  3  4
 * Hey  0  0  0  2
 * 
 * Group: ["Hi", "Hello", "2"]
 * Group Dimension: [ 1 X 4 ]
 * 3      0  1  3  4
 * Hello  0  0  0  2
 * 
 * Group: ["Hey", "Hey", "3"]
 * Group Dimension: [ 1 X 4 ]
 * 3   0  1  3  4
 * Hi  0  0  0  3
 */
```

### Aggregate

Aggregate allows user to perform mathematical operation on row or columns of the DataFrame or a Group.

#### Usage
```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;
import std.algorithm: max, min;

DataFrame!(int, 3, double, 2) df;
Index inx;
inx[0] = ["Row1", "Row2"];
inx[1] = ["Col1", "Col2", "Col3", "Col4", "Col5"];

df.setFrameIndex(inx);
df = [[1, 2, 3, 4, 5], [0, 1, 2, 3, 4]];
df.display();
/*
 *        Col1  Col2  Col3  Col4  Col5
 *  Row1  1     2     3     4     5
 *  Row2  1     2     3     4     5
 */

df.aggregate!(1, max).display();
/*
 *  Operation  Col1  Col2  Col3  Col4  Col5
 *  max        1     2     3     4     5
 */

df.aggregate!(1, max, min).display();
/*
 *  Operation       Col1  Col2  Col3  Col4  Col5
 *  max             1     2     3     4     15
 *  min             0     1     2     3     4  
 */

aggregate!(0, max).display();
/*
 *        max
 *  Row1  5
 *  Row2  4
 */

aggregate!(0, max, min).display();
/*
 *        max  min
 *  Row1  5    1
 *  Row2  4    0
 */
```

### Filter

Filter operation allows you to drop specific rows of DataFrame based on the result of specific alias being passed.

`df.filter!(alias Func)`
* `Func` - alias based on which the row of DataFrame will be dropped

#### Usage

```d
import magpie.dataframe: DataFrame;
import magpie.index: Index;

DataFrame!(float, float) df;
Index inx;
inx[0] = ["Firm1", "Firm2", "Firm3", "Firm4", "Firm5"];
inx[1] = ["Assets", "Valuation"];
df.setFrameIndex(inx);

static bool filterFunc(T)(T ele)
{
    return (ele[0] > ele[1]);
}

df = [[1.2, 2.3], [0.8, 1.2], [4.2, 1.2], [7.2, 9.4], [1.1, 0.5]];

// Find undervalued function
df.filter!(filterFunc).display();
       Assets  Valuation
Firm3  4.2     1.2      
Firm5  1.1     0.5      
```


##### Dataset Sources

* [Dataset1 - UCI Statlog (Heart) Data Set](http://archive.ics.uci.edu/ml/datasets/statlog+(heart))
* [Dataset2 - U.S. Education Datasets: Unification Project](https://www.kaggle.com/noriuk/us-education-datasets-unification-project)