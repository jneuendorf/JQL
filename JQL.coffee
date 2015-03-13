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

cloneObject = (obj) ->
    return JSON.parse JSON.stringify(obj)

# firstInObject = (obj) ->
#     key = Object.key obj
#     key = key[0]
#     return obj[key]

###
select (from), where
update, set
join
insert (into)
distinct
functions: avg, sum, count, max, min, first, last
###
