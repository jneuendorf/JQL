JQL =
    config:
        where:
            # this configures what happens if you specify a column constraint for a column that does not exist:
            # new JQL.Table({a: number, b: number}).where({c: 4})
            # possible values: ignore, error,
            invalidKeyBehavior: "ignore"
        async:
            delay: 20 # in ms
            recordsPerCall: 10000
        defaultTableName: "Table"
    # built-in SQL functions
    # they are called with a table as 'this' context
    sum: (col) ->
        f = (vals) ->
            res = 0
            res += val for val in vals
            return res
        f.column = col
        f.name = "sum"
        f.type = () ->
            return "number"
        return f
    first: (col) ->
        f = (vals) ->
            return vals[0]
        f.column = col
        f.name = "first"
        self = @
        f.type = () ->
            return self.schema.cols[self.schema.nameToIdx(col)].type
        return f
    last: (col) ->
        f = (vals) ->
            return vals[vals.length - 1]
        f.column = col
        f.name = "last"
        f.type = () ->
            return self.schema.cols[self.schema.nameToIdx(col)].type
        return f
    # TODO: avg, max, min, sum
    createAggregation: (func, onColumn, aggrName, aggrType) ->
        func.column = onColumn
        func.name = aggrName
        func.type = aggrType
        return func

getSelf = () ->
    return @

toArr = (args) ->
    return Array::slice.call args

# http://stackoverflow.com/questions/7837456/comparing-two-arrays-in-javascript
arrEquals = (arr1, arr2) ->
    if arr1.length isnt arr2.length
        return false

    for x, i in arr1
        y = arr2[i]
        if x instanceof Array and y instanceof Array
            if not arrEquals(x, y)
                return false
        else if x isnt y
            return false

    return true

arrUnique = (arr) ->
    res = []
    for elem in arr
        valid = true
        for done in res when arrEquals(done, elem)
            valid = false
            break

        if valid
            res.push elem
    return res

cloneObject = (obj) ->
    return JSON.parse JSON.stringify(obj)

padNum = (num, digits) ->
    if typeof num is "number"
        num = "#{num}"

    len = num.length
    if (idx = num.indexOf ".") >= 0
        len = idx

    if digits > len
        for i in [0...(digits - len)]
            num = "0#{num}"
    return num

# makeAsync = (func, args...) ->
#     #    i = 0
#     #    records = @table.records
#     #    deltaIdx = JQL.Schema.config.async.recordsPerCall
#     #    delay = JQL.Schema.config.async.delay
#     #    maxIdx = records.length
#     #
#     #    f = (index) ->
#     #        console.log "async adding. index = #{index}..."
#     #        max = index + deltaIdx
#     #        doCallback = false
#     #        if max > maxIdx
#     #            max = maxIdx
#     #            doCallback = true
#     #
#     #        for i in [index...max]
#     #            records[i].push initValue
#     #
#     #        if not doCallback
#     #            return window.setTimeout(
#     #                () ->
#     #                    return f(max)
#     #                delay
#     #            )
#     #        return callback?()
#     #
#     #    window.setTimeout(
#     #         () ->
#     #             return f(0)
#     #         0
#     #    )
#
#     func = () ->
#         for record in @table.records
#             record.push initValue
#
#     return f
