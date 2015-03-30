class BasicOps

    # JOIN
    fullOuterJoin: (table, leftCol, rightCol) ->
        return @leftJoin(table, leftCol, rightCol).merge(@rightJoin(table, leftCol, rightCol))

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

        @schema = leftSchema.concat rightSchema
        @records = records
        return @

    join: (table, leftCol, rightCol, type="inner") ->
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

        @schema = leftSchema.concat rightSchema
        @records = records
        return @


    rightJoin: (table, leftCol, rightCol) ->
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
    unique: () ->
    distinct: () ->

    groupBy: () ->
    orderBy: () ->


    # QUERY
    select: () ->

    where: () ->
