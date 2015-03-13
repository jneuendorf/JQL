
class JQL.Table

    @sqlToJsType =
        varchar:    "string"
        char:       "string"
        int:        "number"
        decimal:    "number"

    @new: (schema, records) ->
        return new JQL.Table(schema, records)
    # JSON format must be record based:
    # [
    #     {col1: 1, col2: 2},
    #     ...
    # ]
    @new.fromJSON   = (json, schema) ->
        # only schema given
        if arguments.length is 2
            schema = new JQL.Schema(json)
            records = []
        else
            if json instanceof Array
                if json.length > 0
                    schema = new JQL.Schema(json[0])
                else if schema not instanceof JQL.Schema
                    schema = new JQL.Schema(schema)

            records = []
            for record in json
                r = []
                for col in schema.cols
                    r.push record[col.name]
                records.push r

        table = new JQL.Table(schema, records)

        return table or null
    @new.fromRowJSON    = @new.fromJSON
    # JSON format must be column based:
    # [
    # {
    #     name: "col1"
    #     type: someCrazyType   <- optional
    #     vals: [
    #         val11,
    #         val12,
    #         ...
    #     ]
    # },
    # {
    #     name: "col2"
    #     vals: [
    #         val21,
    #         val22,
    #         ...
    #     ]
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

        return new JQL.Table(new JQL.Schema(pseudoRecord, true), records)
    # String. INSERT INTO statements
    @new.fromSQL = (sql) ->
        sql = sql.replace /\`/g, ""
        createTableRegex = /CREATE\s+TABLE\s+(\w+)\s*\(\s*(\w+)\s+(\w+)\s*(\(\s*(\w+)(\s*,\s*(\w+))*\s*\))?\s*((\w+)\s+)*(\w+)?(\s*,\s*(\w+)\s+(\w+)\s*(\(\s*(\w+)(\s*,\s*(\w+))*\s*\))?\s*((\w+)\s+)*(\w+)?)*\)/gi
        colDefRegex = /(\w+)\s+(\w+)\s*(\(\s*\w+(\s*,\s*\w+)*\s*\))?\s*((\w+)\s+)*(\w+)?/gi
        primareKeyRegex = /PRIMARY\s+KEY\s*\(\s*\w+(\s*,\s*\w+)*\s*\)/gi
        # TODO: double quotes not supported, insert into select not supported
        # TODO: this info should at least be in the documentation
        insertRegex = /INSERT INTO\s+(\w+)\s*(\(\w+(\s*,\s*\w+)*\)\s+)?(VALUES\s+\((\w+|\d+|'\w+')(\s*,\s*(\w+|\d+|'\w+'))*\)(\s*,\s*\((\w+|\d+|'\w+')(\s*,\s*(\w+|\d+|'\w+'))*\))*)/gi

        # CREATE TABLE table_name(
        #    column1 datatype,
        #    column2 datatype,
        #    column3 datatype,
        #    .....
        #    columnN datatype,
        #    PRIMARY KEY( one or more columns )
        # );
        # CREATE TABLE CUSTOMERS(
        #    ID   INT              NOT NULL,
        #    NAME VARCHAR (20)     NOT NULL,
        #    AGE  INT              NOT NULL,
        #    ADDRESS  CHAR (25) ,
        #    SALARY   DECIMAL (18, 2),
        #    PRIMARY KEY (ID)
        # );
        # CREATE TABLE `users` (
        #   `id` INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
        #   `username` VARCHAR(16) NOT NULL,
        #   `password` VARCHAR(16) NOT NULL,
        #   PRIMARY KEY (`id`)
        # );

        console.log "SQL...."

        if (matches = sql.match createTableRegex)?
            tables = {}

            # console.log matches

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


                schema = new JQL.Schema(pseudoRecord, true)

                if notNulls.length > 0
                    schema.setNotNulls notNulls
                if autoIncrements.length > 0
                    schema.setAutoIncrements autoIncrements
                if primaryKeys.length > 0
                    schema.setPrimaryKeys primaryKeys

                tables[name] = new JQL.Table(schema, [], name)


            if (matches = sql.match insertRegex)?

                for match in matches
                    info = insertRegex.exec match
                    insertRegex.lastIndex = 0

                    name = info[1]
                    values = info[4]
                    values = values
                        .slice values.indexOf("(")
                        .split /\s*\,(?![^\(]*\))\s*/g

                    console.log name
                    console.log values

                    # add values to existing table
                    if (table = tables[name])?
                        records = []
                        for value in values
                            value = value
                                .replace /\s+/g, ""
                                .slice(value.indexOf("(") + 1, value.indexOf(")"))
                                .split /\s*,\s*/g
                            records.push value
                        console.log ">", records
                        table.insert records
                    # new table => create and insert
                    else

                    # console.log info
                    # console.log name, values

            console.log tables

            return tables

        # else:
        console.warn "SQL statement somehow invalid (back ticks erased already):", sql
        return null



    constructor: (schema, records, name="Table") ->
        if schema instanceof JQL.Schema
            @schema = schema
            @records = records or []
            @name = name
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
            # 1 object for each column, each being a name-type pair
            else
                cols = toArr arguments
                for col in cols
                    for key, val of col when not pseudoRecord[key]?
                        pseudoRecord[key] = val

            @schema = new JQL.Schema(pseudoRecord, true)
            @records = []
            @name = "Table"

        # create props that are just for being close to SQL
        # i.e. this.update.set ...
        Object.defineProperties @, {
            update:
                get: getSelf
                set: getSelf
        }

    row: (n) ->
        return new JQL.Table(@schema, [@records[n]])

    col: (n) ->
        if typeof n is "string"
            n = @schema.nameToIdx n

        return (record[n] for record in @records)

    select: (cols...) ->
        # select all columns
        if not cols? or cols[0] is "*"
            return @

        # select not all columns => projection
        schema = @schema.clone()

        indicesToKeep = (schema.nameToIdx(col) for col in cols when col in schema.names)

        records = []
        for record in @records
            records.push(col for col, i in record when i in indicesToKeep)

        schema.cols = (col for col, i in schema.cols when col.index in indicesToKeep)
        schema._updateData()
        return new JQL.Table(schema, records)

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
                else if pool[key]? and not pool[key](val, record)
                    return false
            return true

        # records = (record for record in records when check(predicate, record))
        return new JQL.Table(
            @schema.clone()
            record for record in records when check(predicate, record)
        )

    and: () ->

    or: () ->

    join: () ->

    set: () ->

    groupBy: () ->

    orderBy: () ->

    insert: (records...) ->
        for record in records
            # TODO: check primary (if set)
            true
        return @

    delete: () ->

    each: (callback) ->
        for record, i in @records
            if callback(record, i) is false
                break
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
