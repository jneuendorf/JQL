# TODO: inherit from interface
class OpChainer# extends BasicOps

    constructor: (table, inPlace=false) ->
        if not inPlace
            @_table = table.clone()
        else
            @_table = table
        @_chain = []

    _optimizeChain: () ->
        # projection (subset of columns)
        # selection (tuples satisfying condition)
        #  - commutative
        # join

        # EXAMPLES:
        # schema:   a, b, c, d
        #           select(a, c).where(c: 2).unique().where(d: 42).select(a, b).unique()
        #  =>       select(*).where(c: 2, d: 42).select(a, b).unique()
        # <=>       where(c: 2, d: 42).select(a, b).unique()

        # schema:   a, b, c, d, e
        #           select(a, d).where(c: 2).unique().where(d: 42).select(a, c).unique()
        #  =>       select(a, c, d).where(c: 2, d: 42).select(a, c).unique()

        # schema:   a, b, c, d, e
        #           select(a, d).select(d, e).where(c: 2)
        #  =>       where(c: 2).select(d)

        # RULES:
        # 1. joins cannot be moved in chain
        # 2. drop columns as early as possible (before where/groupby,orderby)
        # 3. combine select statements to their intersection
        # TODO: make where be able to take complex objects instead of multiple where calls.


        selectGroups = []
        chain = []

        columnsToKeep = []
        for data in @_chain
            [args, func] = data
            if func is "select"
                columnsToKeep = columnsToKeep.concat args

        columnsToDrop = (col for col in @_table.schema.names when col not in columnsToKeep)

        # try to select first but if cols are needed in where/groupby/orderby dont select first...only the ones possible

        return chain


    start: () ->
        for data in @_optimizeChain()
            data.func.apply(@_table, data.args)

        return @_table

    exec: @::start

    end: (exec=true) ->
        if exec is true
            return @start()
        return @

    done: @::end

    _addToChain = (args, func) ->
        @_chain.push [args, func]

    # part of JQL.TABLE's API

    apiMethods = [
        # JOIN
        "fullOuterJoin"
        "innerJoin"
        "join"
        "leftJoin"
        "rightJoin"

        "unique"
        "distinct"

        "groupBy"
        "orderBy"

        "select"
        "where"
    ]
    for methodName in apiMethods
        @::[methodName] = do (methodName) ->
            return () ->
                _addToChain.call @, toArr(arguments), methodName
                return @

    ##################################################################################################################
    # "OVERRIDING" some methods of JQL.Table

    # merges with uniqueness
    _merge: (table) ->
        if @schema.equals table.schema
            return new JQL.Table(
                @schema.clone()
                arrUnique(@records.concat table.records)
                @name
            )

        console.warn "JQL::merge: schema of given table does not match schema of this table! Returning this table."
        return @

    # JOIN
    _fullOuterJoin: (table, leftCol, rightCol) ->
        return @leftJoin(table, leftCol, rightCol).merge(@rightJoin(table, leftCol, rightCol))

    _innerJoin: (table, leftCol, rightCol) ->
        if not rightCol
            rightCol = leftCol

        records = []
        leftSchema = @schema
        rightSchema = table.schema
        for leftRecord in @records
            for rightRecord in table.records
                if leftRecord[leftSchema.nameToIdx(leftCol)] is rightRecord[rightSchema.nameToIdx(rightCol)]
                    records.push leftRecord.concat(rightRecord)

        @schema = leftSchema.concat rightSchema
        @records = records
        return @

    _join: (table, leftCol, rightCol, type="inner") ->
        if not type?
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

        if map[type]?
            return map[type].call(@, table, leftCol, rightCol)

        return @innerJoin(table, leftCol, rightCol)

    _leftJoin: (table, leftCol, rightCol) ->
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

        @schema = leftSchema.concat rightSchema
        @records = records
        return @


    _rightJoin: (table, leftCol, rightCol) ->
        if not rightCol
            rightCol = leftCol

        records = []
        leftSchema = @schema
        rightSchema = table.schema
        nullArray = (null for i in [0...rightSchema.cols.length])
        for rightRecord in table.records
            matchFound = false
            for leftRecord in @records
                if rightRecord[rightSchema.nameToIdx(rightCol)] is leftRecord[leftSchema.nameToIdx(leftCol)]
                    records.push leftRecord.concat(rightRecord)
                    matchFound = true

            if not matchFound
                records.push nullArray.concat(rightRecord)

        @schema = leftSchema.concat rightSchema
        @records = records
        return @

    #
    _unique: () ->
        @records = arrUnique @records
        return @

    _distinct: @::_unique

    _groupBy: (col, aggregation, alias) ->
        dict = {}

        # aggregation given
        if aggregation instanceof Function and typeof aggregation.column is "string"
            recordDict = {}
            schema = @schema.clone()

            for record in @records
                val = record[schema.nameToIdx(col)]
                if not dict[val]?
                    dict[val] = [record[schema.nameToIdx(aggregation.column)]]
                    # save copy of record so we don't modify the original data
                    recordDict[val] = record.slice(0)
                else
                    dict[val].push record[schema.nameToIdx(aggregation.column)]

            for groupByCol, aggrVals of dict
                dict[groupByCol] = aggregation.call(@, aggrVals)

            # add aggregation column to records
            for key, val of dict
                recordDict[key].push val

            schema.cols.push {
                name: aggregation.name or alias or "aggregation"
                type: aggregation.type()
                index: schema.cols.length
            }
            schema._updateData()

            return new JQL.Table(
                schema
                (record for key, record of recordDict)
            )

        # else: no aggregation => don't calculate anything, don't add extra column
        for record in @records
            val = record[@schema.nameToIdx(col)]
            if not dict[val]?
                dict[val] = record

        @records = (record for key, record of dict)
        return @

    _orderBy: (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        schema = @schema

        @records = @records.slice(0).sort (r1, r2) ->
            for col in cols
                idx = schema.nameToIdx col
                if r1[idx] < r2[idx]
                    return -1
                if r1[idx] > r2[idx]
                    return 1
            return 0

        return @

    # QUERY
    _select: (cols...) ->
        # select all columns
        if not cols? or cols[0] is "*"
            return @

        # select not all columns => projection
        schema = @schema

        records = []
        for record in @records
            records.push (record[schema.nameToIdx(col)] for col in cols)

        schema = new JQL.Schema()
        for col, i in cols
            # col contains alias
            if col.toLowerCase().indexOf " as "
                parts = col.split /\s+as\s+/i
                col = parts[0]
                alias = parts[1]

            c = @schema.cols[@schema.nameToIdx(col)]
            c.index = i

            if alias?
                c.name = alias
            schema.cols.push c

        schema._updateData()

        @schema = schema
        @records = records
        return @

    _where: (predicate) ->
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

        @records = (record for record in records when check(predicate, record))
        return @
