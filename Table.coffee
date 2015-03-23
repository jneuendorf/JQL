###
update, set
insert (into)
distinct
functions: avg, sum, count, max, min, first, last
###
class JQL.Table

    @sqlToJsType =
        varchar:    "string"
        char:       "string"
        int:        "number"
        decimal:    "number"
        date:       "date"

    @typeConversion =
        strToNum: (str) ->
            return parseFloat(str)
        numToStr: (num) ->
            return "#{num}"
        numToDat: (num) ->
            return new Date(num)
        datToNum: (date) ->
            return date.getTime()
        strToDat: (str) ->
            str = str.split /\D/g
            data = []
            for d, i in str
                d = parseInt(d, 10)
                if i is 1
                    d--
                data.push d

            # NOTE: the date constructor creates invalid dates when undefined is passed as argument
            # TODO: is there no better way?
            lookupTable = [
                null
                (args) ->
                    return new Date(args[0])
                (args) ->
                    return new Date(args[0], args[1])
                (args) ->
                    return new Date(args[0], args[1], args[2])
                (args) ->
                    return new Date(args[0], args[1], args[2], args[3])
                (args) ->
                    return new Date(args[0], args[1], args[2], args[3], args[4])
                (args) ->
                    return new Date(args[0], args[1], args[2], args[3], args[4], args[5])
            ]
            return lookupTable[data.length](data)
        datToStr: (date) ->
            return "#{date.getFullYear()}-#{padNum(date.getMonth() + 1, 2)}-#{padNum(date.getDate(), 2)} #{padNum(date.getHours(), 2)}:#{padNum(date.getMinutes(), 2)}:#{padNum(date.getSeconds(), 2)}"


    @new: (schema, records) ->
        return new JQL.Table(schema, records)

    # JSON format must be record based:
    # [
    #     {col1: 1, col2: 2},
    #     ...
    # ]
    @new.fromJSON = (json, name) ->
        if json not instanceof Array
            return null

        schema = new JQL.Schema(null, json[0])

        records = []
        for record in json
            r = []
            for col in schema.cols
                r.push record[col.name]
            records.push r

        table = new JQL.Table(schema, records, name, null)
        schema.table = table

        return table
    @new.fromRowJSON    = @new.fromJSON

    # JSON format must be column based:
    # [
    # {
    #     name: "col1",
    #     type: someCrazyType,   <- optional
    #     vals: [ val11, val12, ... ]
    # },
    # {
    #     name: "col2",
    #     vals: [val21, val22, ... ]
    # },
    # ...
    # ]
    @new.fromColJSON = (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        # schema
        pseudoRecord = {}
        maxColLength = 0
        for col in cols
            pseudoRecord[col.name] = col.type or typeof col.vals[0]
            if col.vals.length > maxColLength
                maxColLength = col.vals.length

        # records
        records = []
        for i in [0...maxColLength]
            records.push(col.vals[i] or null for col in cols)

        return new JQL.Table(new JQL.Schema(@, pseudoRecord, true), records)
    # String. INSERT INTO statements
    @new.fromSQL = (sql) ->
        sql = sql.replace /\`/g, ""
        createTableRegex = /CREATE\s+TABLE\s+(\w+)\s*\(\s*(\w+)\s+(\w+)\s*(\(\s*(\w+)(\s*,\s*(\w+))*\s*\))?\s*((\w+)\s+)*(\w+)?(\s*,\s*(\w+)\s+(\w+)\s*(\(\s*(\w+)(\s*,\s*(\w+))*\s*\))?\s*((\w+)\s+)*(\w+)?)*\)/gi
        colDefRegex = /(\w+)\s+(\w+)\s*(\(\s*\w+(\s*,\s*\w+)*\s*\))?\s*((\w+)\s+)*(\w+)?/gi
        primareKeyRegex = /PRIMARY\s+KEY\s*\(\s*\w+(\s*,\s*\w+)*\s*\)/gi
        # TODO: double quotes not supported, insert into select not supported
        # TODO: this info should at least be in the documentation
        insertRegex = /INSERT INTO\s+(\w+)\s*(\(\w+(\s*,\s*\w+)*\)\s+)?(VALUES\s+\((\w+|\d+|'\w+')(\s*,\s*(\w+|\d+|'\w+'))*\)(\s*,\s*\((\w+|\d+|'\w+')(\s*,\s*(\w+|\d+|'\w+'))*\))*)/gi

        if (matches = sql.match createTableRegex)?
            tables = {}

            for match in matches
                info = createTableRegex.exec match
                # this is needed for repeatedly using the regex without acting like the global modifier is on
                # that means each regex.exec will start at index 0 for each match
                createTableRegex.lastIndex = 0

                name = info[1]

                # go through lines to extract data
                tableData = match
                    .slice(match.indexOf("(") + 1, -1)
                    .trim()
                    .replace /\n/g, ""
                    .replace /\s+/g, " "
                    # .split /\s*,\s*/g
                    .split /\s*\,(?![^\(]*\))\s*/g

                pseudoRecord = {}
                notNulls = []
                autoIncrements = []
                primaryKeys = []

                for colDef in tableData
                    if not colDef.match primareKeyRegex
                        colDef = colDef
                            .replace /\(\s*\w+(\s*,\s*\w+)*\s*\)/g, ""
                            .replace /NOT\s+NULL/gi, "notnull"
                            .replace /AUTO_INCREMENT/gi, "autoincrement"
                            .replace /UNSIGNED/gi, ""
                            .split /\s+/g
                        colName = colDef[0]
                        type = JQL.Table.sqlToJsType[colDef[1].toLowerCase()]
                        options = colDef.slice(2)

                        pseudoRecord[colName] = type

                        if "notnull" in options
                            notNulls.push colName

                        if "autoincrement" in options
                            autoIncrements.push colName

                        # console.log "column...", colName, type, options
                    else
                        colDef = colDef
                            .replace /PRIMARY\s+KEY\s*\((.*)\)/gi, "$1"
                            .split /\s*,\s*/g
                        for col in colDef
                            primaryKeys.push col.trim()
                        # console.log "prime...", colDef


                schema = new JQL.Schema(@, pseudoRecord, true)

                if notNulls.length > 0
                    schema.setNotNulls notNulls
                if autoIncrements.length > 0
                    schema.setAutoIncrements autoIncrements
                # if primaryKeys.length > 0
                #     schema.setPrimaryKeys primaryKeys

                tables[name] = new JQL.Table(schema, [], name)

            # INSERT INTO statements
            if (matches = sql.match insertRegex)?

                for match in matches
                    info = insertRegex.exec match
                    insertRegex.lastIndex = 0

                    name = info[1]
                    values = info[4]
                    values = values
                        .slice values.indexOf("(")
                        .split /\s*\,(?![^\(]*\))\s*/g

                    # add values to existing table
                    if (table = tables[name])?
                        records = []
                        for value, i in values
                            value = value
                                .replace /\s+/g, ""
                                .slice(value.indexOf("(") + 1, value.indexOf(")"))
                                .split /\s*,\s*/g
                            records.push value
                        table.insert records
                    # new table => create and insert
                    else
                        console.warn "Table '#{name}' does not exist! Create (first) with CREATE TABLE!"

            console.log tables
            return tables
        # else:
        console.warn "SQL statement somehow invalid (back ticks erased already):", sql
        return null

    @new.fromTable = (table) ->
        return new JQL.Table(
            table.schema.clone()
            record.slice(0) for record in table.records
        )

    constructor: (schema, records, name="Table", partOf=null) ->
        if schema instanceof JQL.Schema
            @schema = schema
            schema.table = @
            @records = records or []
            @name = name
            @partOf = partOf
        else
            pseudoRecord = {}

            # array of name-type pairs
            if schema instanceof Array
                for col, i in schema by 2
                    type = schema[i + 1]
                    pseudoRecord[col] = type
            # object of name-type pairs
            else if arguments.length is 1
                pseudoRecord = schema
            else
                console.warn "Invalid arguments passed:", arguments
                # 1 object for each column, each being a name-type pair
                # cols = toArr arguments
                # for col in cols
                #     for key, val of col when not pseudoRecord[key]?
                #         pseudoRecord[key] = val

            @schema = new JQL.Schema(@, pseudoRecord, true)
            @records = []
            @name = "Table"
            @partOf = null

        @history = []

        # create props that are just for being close to SQL
        # i.e. this.update.set ...
        Object.defineProperties @, {
            update:
                get: getSelf
                set: getSelf
        }

    clone: () ->
        return JQL.Table.new.fromTable(@)

    row: (n) ->
        return new JQL.Table(@schema, [@records[n]], @name, @)

    first: () ->
        return @row(0)

    firstRaw: () ->
        return @records[0]

    last: () ->
        return @row(@records.length - 1)

    lastRaw: () ->
        return @record[@records.length - 1]

    col: (n) ->
        if typeof n is "string"
            n = @schema.nameToIdx n

        return (record[n] for record in @records)

    # TODO: enable labeling (col AS name)
    # TODO: enable table referencing (SELECT table1.id, table2.id)
    #       => make "Table.column" equal to "column" and make operations (like join) automatically prepend their table name
    select: (cols...) ->
        # select all columns
        if not cols? or cols[0] is "*"
            return @clone()

        # select not all columns => projection
        schema = @schema.clone()

        indicesToKeep = (schema.nameToIdx(col) for col in cols when col in schema.names)

        records = []
        for record in @records
            records.push(col for col, i in record when i in indicesToKeep)

        schema.cols = (col for col, i in schema.cols when col.index in indicesToKeep)
        schema._updateData()
        return new JQL.Table(schema, records, "#{@name}.select", @)

    project: () ->
        return @select.apply(@, arguments)

    where: (predicate) ->
        if predicate instanceof Function
            return record for record in @records when predicate(record)

        schema = @schema
        records = @records
        map = schema.nameToIdx.bind(schema)

        pool =
            isnt: (predicate, record) ->
                for key, val of predicate
                    if record[map(key)] is val
                        return false
                return true
            is: (predicate, record) ->
                for key, val of predicate
                    if record[map(key)] isnt val
                        return false
                return true
            lt: (predicate, record) ->
                for key, val of predicate
                    if record[map(key)] >= val
                        return false
                return true
            gt: (predicate, record) ->
                for key, val of predicate
                    if record[map(key)] <= val
                        return false
                return true
            lte: (predicate, record) ->
                for key, val of predicate
                    if record[map(key)] > val
                        return false
                return true
            gte: (predicate, record) ->
                for key, val of predicate
                    if record[map(key)] < val
                        return false
                return true

        self = @

        check = (predicate, record) ->
            for key, val of predicate
                # form: col: val => implicit is()
                if key in schema.names
                    if record[map(key)] isnt val
                        return false
                # form lt:
                #       col: val
                # invalid col names are ignored here
                # TODO: use setting to decide what to do with inexistent keys
                else if pool[key]? and not pool[key](val, record)
                    return false
            return true

        # records = (record for record in records when check(predicate, record))
        return new JQL.Table(
            @schema.clone()
            record for record in records when check(predicate, record)
            @name
            @
        )

    alter: () ->

    # form: {name:, type:, notNull:, autoIncrement:, prime/primaryKey:, initVal: }
    @::alter.addColumn = (col) ->
        if col.notNull is true and not col.initVal
            console.warn "Can't add NOT NULL column if no initial value is given!"
            return @

        @schema.addColumn col

        for record in @records
            record.push(col.initVal or null)

        return @

    @::alter.deleteColumn = (colName) ->
        idx = @schema.nameToIdx colName
        @schema.deleteColumn colName

        for record, i in @records
            @records[i] = (col for col, j in record when j isnt idx)

        return @

    @::alter.dropColumn = () ->
        return @alter.deleteColumn.apply(@, arguments)

    @::alter.changeColumn = (name, type) ->
        @schema.changeColumn name, type
        return @

    @::alter.changeColumnType = () ->
        return @alter.changeColumn.apply(@, arguments)

    @::alter.renameColumn = (oldName, newName) ->
        @schema.renameColumn oldName, newName
        return @

    @::alter.changeColumnName = () ->
        return @alter.renameColumn.apply(@, arguments)

    # make all altering methods directly accessible from JQL.Table object
    for name, method of @::alter
        @::[name] = method

    rename: (name) ->
        @name = "#{name}"
        return @

    and: (table) ->
        # TODO: this operation is not commutative.
        # if 'this' contains 2 identical rows R and 'table' also has that row the result depends on the order:
        # this.and(table) != table.and(this)
        #    both rows R   -    1 row R
        # TODO: maybe assume uniqueness right away?!?

        return new JQL.Table(
            @schema.clone()
            record for record in @records when record in table.records
        )

    or: (table) ->
        return new JQL.Table(
            @schema.clone()
            @records.concat table.records
        )

    innerJoin: (table, leftCol, rightCol) ->
        if not rightCol
            rightCol = leftCol

        records = []
        leftSchema = @schema
        rightSchema = table.schema
        for leftRecord in @records
            for rightRecord in table.records
                if leftRecord[leftSchema.nameToIdx(leftCol)] is rightRecord[rightSchema.nameToIdx(rightCol)]
                    records.push leftRecord.concat(rightRecord)

        return new JQL.Table(leftSchema.concat(rightSchema), records)

    outerJoin: (table, leftCol, rightCol) ->

    leftJoin: (table, leftCol, rightCol) ->
        if not rightCol
            rightCol = leftCol

        records = []
        leftSchema = @schema
        rightSchema = table.schema
        nullArray = (null for i in [0...rightSchema.cols.length])
        for leftRecord in @records
            matchFound = false
            for rightRecord in table.records
                if leftRecord[leftSchema.nameToIdx(leftCol)] is rightRecord[rightSchema.nameToIdx(rightCol)]
                    records.push leftRecord.concat(rightRecord)
                    matchFound = true

            if not matchFound
                records.push leftRecord.concat(nullArray)

        return new JQL.Table(leftSchema.concat(rightSchema), records)

    rightJoin: (table, leftCol, rightCol) ->
        return table.leftJoin(@, rightCol, leftCol)

    fullOuterJoin: (table, leftCol, rightCol) ->

    join: (table, leftCol, rightCol, type="inner") ->
        if arguments.length is 3
            return @innerJoin(table, leftCol, rightCol)

        type = ("#{type}").toLowerCase()
        map =
            fullOuter:  @fullOuterJoin
            inner:      @innerJoin
            left:       @leftJoin
            leftOuter:  @leftJoin
            outer:      @outerJoin
            right:      @rightJoin
            rightOuter: @rightJoin

        return @[map[type]]?(table, leftCol, rightCol) or @innerJoin(table, leftCol, rightCol)

    equals: (table) ->
        if @schema.equals table.schema
            if @records.length isnt table.record.length
                return false

            doneIndices = []
            for record, i in table.records
                for rRecord, j in @records when j not in doneIndices and arrEquals(record, rRecord)
                    doneIndices.push j

            return doneIndices.length is @records.length
        return false


    set: () ->

    unique: () ->
        records = []
        for record in @records
            for r in records when not arrEquals(record, r)
                records.push record
        return new JQL.Table(@schema.clone(), records)

    distinct: () ->
        return @unique.applu(@, arguments)

    groupBy: (aggregation) ->

    # in place
    orderBy: (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        schema = @schema

        @records.sort (r1, r2) ->
            for col in cols
                idx = schema.nameToIdx col
                if r1[idx] < r2[idx]
                    return -1
                if r1[idx] > r2[idx]
                    return 1
            return 0

        return @

    insert: (records...) ->
        if records[0] instanceof Array
            records = records[0]

        for record in records
            types = @schema.types
            if record instanceof Array
                for col, i in record when typeof col isnt types[i]
                    type = types[i]
                    funcName = "#{(typeof col).slice(0,3)}To#{type[0].toUpperCase()}#{type.slice(1, 3)}"
                    record[i] = JQL.Table.typeConversion[funcName](col)
                    console.warn "JQL.Table::insert: type of '#{col}' (#{typeof col}, #{i + 1}th column) does not match '#{type}'. Converting to '#{record[i]}' (type: '#{type}')."

                @records.push record
            else
                r = []
                for name in @schema.names
                    r.push record[name]
                @records.push r
        return @

    delete: (param) ->
        # child (= subset) table given
        if param instanceof JQL.Table
            child = param
            incidesToRemove = []
            for childRecord in param.records
                for record, i in @records when arrEquals(childRecord, record)
                    incidesToRemove.push i
                    break
            @records = (record for record, i in @records when i not in incidesToRemove)
        # where predicate given
        else if param?
            @delete @where(param.where or predicate)
        # nothing given => assume 'this' is a child (= subset) of some table
        else
            @partOf?.delete @
        return @

    @::["delete"].where = () ->
        return @delete.apply(@, arguments)

    each: (callback) ->
        for record, i in @records
            break if callback(record, i) is false
        return @

    # more detailed than 'each'. cb params: record as object, index
    each2: (callback) ->
        for record, i in @records
            r = {}
            for col, j in @schema.names
                r[col] = record[j]

            break if callback(r, i) is false
        return @

    each3: (callback) ->
        for record, i in @records
            r = []
            for col, j in @schema.cols
                r[j] = record[col.index]

            # add current iteration index to the front of arguments
            r.unshift i

            break if callback.apply(r, r) is false
        return @

    # revert table to json format (inverse of fromJSON)
    toJSON: () ->
        res = []
        map = @schema.idxToName.bind(@schema)
        for record in @records
            obj = {}
            for col, i in @schema.cols
                obj[map(i)] = record[i]
            res.push obj
        return res

    # create (dependent on parent table(s)) (select) sql query
    toSelectSQL: () ->

    # create independent (create + insert) sql statement
    toSQL: () ->
