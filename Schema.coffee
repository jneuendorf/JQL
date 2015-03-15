class JQL.Schema

    @typeToVal:
        number: 0
        string: ""
        boolean: false
        object: {}

    @fromSchema: (schema) ->
        result = new JQL.Schema()

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

    constructor: (record, preTyped) ->
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
                    prime: false
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

    setAutoIncrements: (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        for col in @cols
            if col.name in cols
                col.autoIncrement = true
            else if col.autoIncrement
                col.autoIncrement = false
        return @

    setPrimaryKeys: (cols...) ->
        if cols[0] instanceof Array
            cols = cols[0]

        for col in @cols
            if col.name in cols
                col.prime = true
            else if col.prime
                col.prime = false
        return @

    setPrimes: () ->
        return @setPrimaryKeys.apply(@, arguments)

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

    and: (schema) ->
        result = @clone()

        # kick out the columns that are not in 'schema'
        indicesToRemove = []
        for name, i in @names when schema.nameToIdx(name) < 0
            indicesToRemove.push i

        @cols = (col for col, i in @cols when i not in indicesToRemove)
        @_updateData()

        return result

    or: (schema) ->

    addColumn: (col) ->
        colData =
            name:           col.name
            index:          @cols.length
            type:           col.type
            notNull:        col.notNull or false
            autoIncrement:  col.autoIncrement or false
            prime:          col.prime or col.primaryKey or false

        @cols.push colData
        return @

    deleteColumn: (name) ->
        idx = @nameToIdx name
        @cols = (col for col, i in @cols when i isnt idx)
        @_updateData()
        return @

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

    colNamed: (name) ->
        for col in @cols when col.name is name
            return col
        return null

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

    nameToIdx: (name) ->
        return @names.indexOf name

    idxToName: (idx) ->
        return @names[idx]
