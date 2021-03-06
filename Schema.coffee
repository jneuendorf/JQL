class JQL.Schema

    # TODO:
    # NOTE: this method does NOT clone the table! It points to the same table as the given schema.
    # Therefore this method should not be used from the outside.
    # It should only be used by JQL.Table and only when a new JQL.Table instance is being returned (i.e. for SELECT)
    @fromSchema: (schema) ->
        result = new JQL.Schema(schema.table)

        result.names = schema.names.slice(0)
        # result.indices = schema.indices.slice(0)
        result.types = schema.types.slice(0)
        for col in schema.cols
            result.cols.push {
                name: col.name
                index: col.index
                type: col.type
            }

        return result

    constructor: (table, record, preTyped) ->
        @table = table
        @cols = []
        @names = []
        # @indices = []
        @types = []

        if record?
            i = 0
            for k, v of record
                if not preTyped
                    type = typeof v
                    if v? and type is "object"
                        type = v.constructor.name
                else
                    type = v

                @cols.push {
                    name: k
                    index: i
                    type: type
                    # options
                    notNull: false
                    autoIncrement: false
                    # prime: false
                    _maxVal: null
                }
                @names.push k
                # @indices.push i
                @types.push type
                i++

    # all columns that are not given will be reset!
    setNotNulls: (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        for col in @cols
            if col.name in cols
                col.notNull = true
            else if col.notNull
                col.notNull = false
        return @

    # this also resets all unlisted columns to autoIncrement = false
    setAutoIncrements: (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        for col in @cols
            if col.name in cols
                col.autoIncrement = true
                if @table?
                    max = null
                    for val in @table.col(col.name) when not max? or val > max
                        max = val
                    col._maxVal = max
            else if col.autoIncrement
                col.autoIncrement = false

        return @

    # setPrimaryKeys: (cols...) ->
    #     if cols[0] instanceof Array
    #         cols = cols[0]
    #
    #     for col in @cols
    #         if col.name in cols
    #             col.prime = true
    #         else if col.prime
    #             col.prime = false
    #     return @
    #
    # setPrimes: () ->
    #     return @setPrimaryKeys.apply(@, arguments)

    # resetOptions: () ->
    #     for col in @cols
    #         col.notNull = false
    #         col.autoIncrement = false
    #         col.prime = false
    #     return @

    # names, indices
    # should be called after modifying this.cols
    _updateData: () ->
        names = []
        # indices = []
        types = []
        for col, i in @cols
            names.push col.name
            # indices.push i
            types.push col.type
        @names = names
        # @indices = indices
        @types = types
        return @

    clone: () ->
        return JQL.Schema.fromSchema(@)

    # and: (schema) ->
    #     # kick out the columns that are not in 'schema'
    #     indicesToRemove = []
    #     for name, i in @names when schema.nameToIdx(name) < 0
    #         indicesToRemove.push i
    #
    #     @cols = (col for col, i in @cols when i not in indicesToRemove)
    #     @_updateData()
    #     return @
    #
    # or: (schema) ->

    concat: (schema) ->
        leftSchema = @clone()
        # update column names for this schema
        for col, i in leftSchema.cols when "." not in col.name
            if leftSchema.table.name isnt JQL.config.defaultTableName
                leftSchema.cols[i].name = "#{leftSchema.table.name}.#{col.name}"
            else
                leftSchema.cols[i].name = "#{leftSchema.table.name}Left.#{col.name}"

        # update column names for given schema
        rightSchema = schema.clone()
        for col, i in rightSchema.cols when "." not in col.name
            if @table.name isnt JQL.config.defaultTableName
                rightSchema.cols[i].name = "#{rightSchema.table.name}.#{col.name}"
            else
                rightSchema.cols[i].name = "#{rightSchema.table.name}Right.#{col.name}"

        leftSchema.cols = leftSchema.cols.concat rightSchema.cols
        leftSchema._updateData()
        return leftSchema

    join: () ->
        return @concat.apply(@, arguments)

    ###*
    * @method addColumn
    * @param column {Object}
    * An optional .initValue attribut can be passed along. This can either be a function(record, index), an array of initial values, or a single initial value (for all records).
    * @param async {Boolean}
    * Optional. Default is 'false'. If set to 'true' appending the initial value to the table records is done asynchronously. Recommended for very tables with many records.
    * @param callback {Function}
    * Optional. If passed and the 'async' parameter is 'true' the callback will be executed after all records have been changed.
    *###
    addColumn: (col, async=false, callback) ->
        colData =
            name:           col.name
            index:          @cols.length
            type:           col.type.toLowerCase()
            notNull:        col.notNull or false
            autoIncrement:  col.autoIncrement or false
            prime:          col.prime or col.primaryKey or false

        @cols.push colData
        @_updateData()

        # create set of initial values depending on given parameter
        initValue = col.initValue
        # function => create array
        if initValue instanceof Function
            if not async
                initValues = (initValue(record, i) for record, i in @table.records)
            else
                initValues = initValue
        # array => take it
        else if initValue instanceof Array
            initValues = initValue
        # single value => create array
        else
            if col.initValue is undefined
                initValue = null

            if initValue? and typeof initValue isnt colData.type
                console.warn "Initial value '#{initValue}' (#{typeof initValue}) does not match column type '#{colData.type}'! Falling back to 'null'."
                initValue = null

            initValues = (initValue for i in [0...@table.records.length])

        if not async
            for record, i in @table.records
                record.push(initValues[i] or null)
            return @

        # else: async
        i = 0
        records = @table.records
        deltaIdx = JQL.config.async.recordsPerCall
        delay = JQL.config.async.delay
        maxIdx = records.length

        f = (index) ->
            max = index + deltaIdx
            doCallback = false
            if max > maxIdx
                max = maxIdx
                doCallback = true

            for i in [index...max]
                records[i].push(initValues?(records[i], i) or initValues[i])

            if not doCallback
                return window.setTimeout(
                    () ->
                        return f(max)
                    delay
                )
            return callback?()

        window.setTimeout(
             () ->
                 return f(0)
             0
        )

        return @

    deleteColumn: (names...) ->
        indices = []
        for name in names
            indices.push @nameToIdx(name)
        @cols = (col for col, i in @cols when i not in indices)
        @_updateData()

        # TODO: delete columns from records

        return @

    deleteColumns: () ->
        return @deleteColumn.apply(@, arguments)

    renameColumn: (oldName, newName) ->
        @cols[@nameToIdx(oldName)].name = newName
        @_updateData()
        return @

    changeColumn: (name, type) ->
        @cols[@nameToIdx(name)].type = type
        @_updateData()
        return @

    renameColumn = (oldName, newName) ->
        @schema.renameColumn oldName, newName
        return @

    equals: (schema) ->
        if (l = @cols.length) is schema.cols.length
            # cache array references
            n1 = @names
            n2 = schema.names
            # i1 = @indices
            # i2 = schema.indices
            t1 = @types
            t2 = schema.types

            # for i in [0...l] when n1[i] isnt n2[i] or i1[i] isnt i2[i] or t1[i] isnt t2[i]
            for i in [0...l] when n1[i] isnt n2[i] or t1[i] isnt t2[i]
                return false
            return true
        return false

    at: (param) ->
        if typeof param is "string"
            idx = @nameToIdx param
        else
            idx = param
        return @cols[idx] or null

    nameToIdx: (name) ->
        return @names.indexOf name

    idxToName: (idx) ->
        return @names[idx]
