JQL =
    config:
        where:
            # this configures what happens if you specify a column constraint for a column that does not exist:
            # new JQL.Table({a: number, b: number}).where({c: 4})
            # possible values: ignore, error,
            invalidKeyBehavior: "ignore"

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

cloneObject = (obj) ->
    return JSON.parse JSON.stringify(obj)

# firstInObject = (obj) ->
#     key = Object.key obj
#     key = key[0]
#     return obj[key]
