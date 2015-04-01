# {
#     "id": 692,
#     "date": "2012-04-01",
#     "value": 207935,
#     "created_at": "2013-06-06 15:24:47",
#     "updated_at": "2014-01-06 17:36:06",
#     "detail_html": null,
#     "detail_pic": null,
#     "kpi_report_id": 23,
#     "raw_row_number": null
# }
##################################################################################################################
##################################################################################################################
describe "miscellaneous", () ->

    start = Date.now()
    table = JQL.fromJSON bigJSON, "bigTable"
    loadingTime = Date.now() - start
    console.log "#{loadingTime} ms,", table
    schema = table.schema
    records = table.records

    it "loading big data", () ->
        expect loadingTime
            .toBeLessThan 500

    ##############################################################################################################
    it "arrEquals", () ->
        arr1 = [1, true, "asdf", [1,2,3], 4]
        arr2 = [1, true, "asdf", [1,2,3], 4]
        arr3 = [[1,2], [3,4]]

        expect arrEquals(arr1, arr2)
            .toBe true

        expect arrEquals(arr1, arr3)
            .toBe false

    ##############################################################################################################
    it "padNum", () ->
        expect padNum(3, 2)
            .toBe "03"

        expect padNum("03", 3)
            .toBe "003"

        expect padNum("33", 2)
            .toBe "33"

        expect padNum("33", 1)
            .toBe "33"

        expect padNum(333, 5)
            .toBe "00333"

        expect padNum(33.34, 5)
            .toBe "00033.34"

        expect padNum("33.34", 5)
            .toBe "00033.34"

        expect padNum(33.345, 2)
            .toBe "33.345"

        expect padNum(33.345, 1)
            .toBe "33.345"


##################################################################################################################
##################################################################################################################
describe "JQL.Schema", () ->

    table = JQL.fromJSON bigJSON, "bigTable"
    schema = table.schema
    records = table.records

    it "clone and equals", () ->
        expect schema.clone().equals(schema)
            .toBe true

    ##############################################################################################################
    it "addColumn and query new column", () ->
        oldNames = schema.names

        expect schema.addColumn({name: "testColumn", type: "number"}).names
            .toEqual oldNames.concat(["testColumn"])

        expect table.where(id: 692).select("testColumn").col("testColumn")
            .toEqual [null]

        schema.addColumn({name: "testColumn2", type: "number", initValue: 4})

        expect table.where(id: 692).select("testColumn2").col("testColumn2")
            .toEqual [4]

        schema.addColumn({name: "testColumn3", type: "number", initValue: "non-valid-value"})

        expect table.where(id: 692).select("testColumn3").col("testColumn3")
            .toEqual [null]

        # stuff finished => last records should now have a different length
        callback = () ->
            # NOTE: this try-catch is only because jasmine throws an error when expect is called anywhere but in the it() callback
            try
                expect records[records.length - 1].length
                    .toBe 13
            catch error
                console.warn error.message
            # console.log "async done....."
            return true

        schema.addColumn({name: "testColumn4", type: "number"}, true, callback)
        # console.log "async starting...."
        expect records[records.length - 1].length
            .toBe 12

    ##############################################################################################################
    it "deleteColumn", () ->
        names = (name for name in schema.names when name not in ["testColumn", "testColumn2"])

        expect schema.deleteColumns("testColumn", "testColumn2").names
            .toEqual names

        expect schema.at("testColumn")
            .toBe null

        expect table.records[0].length
            .toBe 12

        # expect table.where(id: 692).select("testColumn", "testColumn2").records
        #     .toEqual [[]]


##################################################################################################################
##################################################################################################################
describe "JQL.Table", () ->

    table = JQL.fromJSON bigJSON, "bigTable"
    schema = table.schema
    records = table.records

    it "fromJSON", () ->
        expect schema
            .toBe table.schema

        expect table
            .toBe schema.table

        expect table.name
            .toBe "bigTable"

    ##############################################################################################################
    it "fromColJSON", () ->
        colJson = [
            {
                name: "col1"
                type: "testType"
                vals: [
                    "val11"
                    "val12"
                ]
            }
            {
                name: "col2"
                vals: [
                    1
                    2
                ]
            }
        ]
        table2 = JQL.fromColJSON colJson

        expect table2.schema.names
            .toEqual ["col1", "col2"]

        expect table2.schema.types
            .toEqual ["testType", "number"]

        expect table2.records[0]
            .toEqual ["val11", 1]

    ##############################################################################################################
    it "fromSQL", () ->
        table2 = JQL.new.fromSQL """CREATE TABLE users (
            id INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
            username VARCHAR(16) NOT NULL,
            password DECIMAL (18, 2) NOT NULL,
            PRIMARY KEY ( id,b)
        );
        INSERT INTO users VALUES (1,2,3), (4,5,6);"""

        expect Object.keys(table2)
            .toEqual ["users"]

        table2 = table2.users

        expect table2.name
            .toBe "users"

        expect table2.schema.names
            .toEqual ["id", "username", "password"]

        expect table2.records
            .toEqual [
                [1,"2",3]
                [4,"5",6]
            ]

    ##############################################################################################################
    it "fromTable/clone", () ->
        clone = table.clone()

        expect clone.records.length
            .toBe table.records.length

        expect clone.schema.names
            .toEqual table.schema.names

    ##############################################################################################################
    it "constructor", () ->
        t1 = new JQL.Table(["id", "number", "text", "string", "img", "string"])
        t2 = new JQL.Table(
            id: "number"
            text: "string"
            img: "string"
        )

        expect t1.schema.cols
            .toEqual t2.schema.cols

    ##############################################################################################################
    it "type conversion", () ->
        funcSet = JQL.Table.typeConversion
        expect funcSet.datToStr(new Date("2015-02-02"))
            .toBe "2015-02-02 01:00:00"

        expect funcSet.strToDat("2015-02-02").getTime()
            .toBe (new Date(2015, 1, 2)).getTime()

        expect funcSet.strToNum(funcSet.numToStr(123.456))
            .toBe 123.456

        expect funcSet.datToNum(funcSet.numToDat(1427040298501))
            .toBe 1427040298501

    ##############################################################################################################
    it "row", () ->
        expect table.row(0).records[0]
            .toEqual [
                375
                "2012-01-01"
                95800
                "2013-06-06 15:24:35"
                "2014-01-06 17:36:02"
                null
                null
                1
                null
            ]

    ##############################################################################################################
    it "col", () ->
        expect table.col "id"
            .toEqual (rec.id for rec in bigJSON)

    ##############################################################################################################
    it "firstRaw", () ->
        expect table.firstRaw()
            .toEqual [
                375
                "2012-01-01"
                95800
                "2013-06-06 15:24:35"
                "2014-01-06 17:36:02"
                null
                null
                1
                null
            ]

    ##############################################################################################################
    it "toJSON", () ->
        expect table.row(0).toJSON()
            .toEqual [{
                "id": 375
                "date": "2012-01-01"
                "value": 95800
                "created_at": "2013-06-06 15:24:35"
                "updated_at": "2014-01-06 17:36:02"
                "detail_html": null
                "detail_pic": null
                "kpi_report_id": 1
                "raw_row_number": null
            }]

        expect table.toJSON()
            .toEqual bigJSON

    ##############################################################################################################
    it "where", () ->
        expect table.where(lt: id: 400).records.length
            .toBe 25

        expect table.where(gt: id: 1316).records.length
            .toBe 1

        expect table.where(date: "2012-03-01").records.length
            .toBe 62

        expect table.where(detail_html: null, detail_pic: null).records.length
            .toBe 919


        expect table.where(or: {id: [400..402], lt: {kpi_report_id: 2}}).records.length
            .toBe 3 + 15

    ##############################################################################################################
    it "select/project", () ->
        selection = table.select("id", "value")

        expect selection.records[0].length
            .toBe 2

        expect selection.schema.names
            .toEqual ["id", "value"]

        selection = table.where(id: 375).select("id", "value")

        expect selection.records.length
            .toBe 1

        expect selection.records[0]
            .toEqual [375, 95800]

        expect selection.at(0, "id")
            .toEqual 375

        expect selection.at("id")
            .toEqual 375

        expect selection.at(0, "value")
            .toEqual 95800

        expect selection.at("value")
            .toEqual 95800

        selection = table.where(id: 375).select("value", "id")

        expect selection.records[0]
            .toEqual [95800, 375]

        expect selection.at(0, "id")
            .toEqual 375

        expect selection.at("id")
            .toEqual 375

        expect selection.at(0, "value")
            .toEqual 95800

        expect selection.at("value")
            .toEqual 95800

        expect selection.schema.names
            .toEqual ["value", "id"]

        selection = table.select("id AS num", "value as someLabel")

        expect selection.schema.names
            .toEqual ["num", "someLabel"]

    ##############################################################################################################
    it "and", () ->
        expect table.where(id: 375).and(id: 376).records.length
            .toBe 0

        expect table.where(id: 375).and(date: "2012-01-01").records
            .toEqual [[375, "2012-01-01", 95800, "2013-06-06 15:24:35", "2014-01-06 17:36:02", null, null, 1, null]]

        expect table.where(id: 375).and().where(date: "2012-01-01").records
            .toEqual [[375, "2012-01-01", 95800, "2013-06-06 15:24:35", "2014-01-06 17:36:02", null, null, 1, null]]

    ##############################################################################################################
    it "or", () ->
        expect table.where(id: 375).or(id: 376).records
            .toEqual [
                [375, "2012-01-01", 95800, "2013-06-06 15:24:35", "2014-01-06 17:36:02", null, null, 1, null]
                [376, "2012-02-01", 90568, "2013-06-06 15:24:35", "2014-01-06 17:36:02", null, null, 1, null]
            ]

    ##############################################################################################################
    it "unique/distinct", () ->
        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
            }
            {
                a: 10
                b: 20
            }
            {
                a: 20
                b: 10
            }
        ]

        expect tempTable.select("a").unique().records
            .toEqual [[10], [20]]

        expect tempTable.unique().records
            .toEqual [[10, 10], [10, 20], [20, 10]]

    ##############################################################################################################
    it "insert", () ->
        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
            }
        ]

        expect tempTable.insert([0, 0], [0, 1]).records
            .toEqual [[10, 10], [0, 0], [0, 1]]

        expect tempTable.insert([[1, 0], [1, 1]]).records
            .toEqual [[10, 10], [0, 0], [0, 1], [1, 0], [1, 1]]

        expect tempTable.insert({a: 2, b: 0}, {a: 2, b: 1}).records
            .toEqual [[10, 10], [0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]]

        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
            }
        ]
        tempTable.schema
            .setAutoIncrements("a")
            .setNotNulls("b")

        # expect tempTable.schema.cols[0]._maxVal
        #     .toBe 10

        expect tempTable.insert({b: 2}).records
            .toEqual [
                [10, 10]
                [11, 2]
            ]

        expect tempTable.insert({b: 3}).records
            .toEqual [
                [10, 10]
                [11, 2]
                [12, 3]
            ]

        try
            expect tempTable.insert({a: 2})
        catch err
            expect err.message
                .toBe "Values of col 'b' must not be null!"

        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
            }
        ]
        tempTable.schema
            .setAutoIncrements("a")
            .setNotNulls("b")

        expect tempTable.insert(a: 42, b: 1337).insert(b: -1).records
            .toEqual [
                [10, 10]
                [42, 1337]
                [43, -1]
            ]


    ##############################################################################################################
    it "join/innerJoin", () ->
        leftTable = JQL.fromJSON [
            {
                lId: 10
                b: "asdf"
            }
            {
                lId: 20
                b: "bsdf"
            }
            {
                lId: 20
                b: "csdf"
            }
        ]

        rightTable = JQL.fromJSON [
            {
                rId: 10
                c: "10"
            }
            {
                rId: 20
                c: "40"
            }
            {
                rId: 10
                c: "50"
            }
        ]

        joined = leftTable.join(rightTable, "lId", "rId")

        expect joined.schema.names
            .toEqual ["TableLeft.lId", "TableLeft.b", "TableRight.rId", "TableRight.c"]

        expect joined.records
            .toEqual [
                [10, "asdf", 10, "10"]
                [10, "asdf", 10, "50"]
                [20, "bsdf", 20, "40"]
                [20, "csdf", 20, "40"]
            ]

        leftTable.name = "A"
        rightTable.name = "B"
        joined = leftTable.join(rightTable, "lId", "rId")

        expect joined.schema.names
            .toEqual ["A.lId", "A.b", "B.rId", "B.c"]

    ##############################################################################################################
    it "leftJoin", () ->
        leftTable = JQL.fromJSON [
            {
                lId: 10
                b: "asdf"
            }
            {
                lId: 20
                b: "bsdf"
            }
            {
                lId: 30
                b: "csdf"
            }
        ]

        rightTable = JQL.fromJSON [
            {
                rId: 10
                c: "10"
            }
            {
                rId: 20
                c: "40"
            }
            {
                rId: 10
                c: "50"
            }
        ]

        joined = leftTable.leftJoin(rightTable, "lId", "rId")

        expect joined.schema.names
            .toEqual ["TableLeft.lId", "TableLeft.b", "TableRight.rId", "TableRight.c"]

        expect joined.records
            .toEqual [
                [10, "asdf", 10, "10"]
                [10, "asdf", 10, "50"]
                [20, "bsdf", 20, "40"]
                [30, "csdf", null, null]
            ]

    ##############################################################################################################
    it "rightJoin", () ->
        leftTable = JQL.fromJSON [
            {
                lId: 10
                b: "asdf"
            }
            {
                lId: 20
                b: "bsdf"
            }
            {
                lId: 10
                b: "csdf"
            }
        ]

        rightTable = JQL.fromJSON [
            {
                rId: 10
                c: "10"
            }
            {
                rId: 20
                c: "40"
            }
            {
                rId: 30
                c: "50"
            }
        ]

        joined = leftTable.rightJoin(rightTable, "lId", "rId")

        expect joined.schema.names
            .toEqual ["TableLeft.lId", "TableLeft.b", "TableRight.rId", "TableRight.c"]

        expect joined.records
            .toEqual [
                [10, "asdf", 10, "10"]
                [10, "csdf", 10, "10"]
                [20, "bsdf", 20, "40"]
                [null, null, 30, "50"]
            ]

    ##############################################################################################################
    it "fullOuterJoin", () ->
        leftTable = JQL.fromJSON [
            {
                lId: 10
                b: "asdf"
            }
            {
                lId: 20
                b: "bsdf"
            }
            {
                lId: 40
                b: "csdf"
            }
        ]

        rightTable = JQL.fromJSON [
            {
                rId: 10
                c: "10"
            }
            {
                rId: 20
                c: "40"
            }
            {
                rId: 30
                c: "50"
            }
        ]

        joined = leftTable.fullOuterJoin(rightTable, "lId", "rId")

        expect joined.schema.names
            .toEqual ["TableLeft.lId", "TableLeft.b", "TableRight.rId", "TableRight.c"]

        expect joined.records
            .toEqual [
                [10, "asdf", 10, "10"]
                [20, "bsdf", 20, "40"]
                [40, "csdf", null, null]
                [null, null, 30, "50"]
            ]

    ##############################################################################################################
    it "groupBy", () ->
        expect table.groupBy("kpi_report_id", JQL.sum("id")).where(kpi_report_id: 1).firstRaw()
            .toEqual [375, "2012-01-01", 95800, "2013-06-06 15:24:35", "2014-01-06 17:36:02", null, null, 1, null, 5730]

    ##############################################################################################################
    it "orderBy", () ->
        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
                c: 10
            }
            {
                a: 20
                b: 20
                c: 40
            }
            {
                a: 20
                b: 10
                c: 50
            }
        ]

        expect tempTable.orderBy("a", "b", "c").records
            .toEqual [[10, 10, 10], [20, 10, 50], [20, 20, 40]]

    ##############################################################################################################
    it "each", () ->
        ids = []
        indices = []
        table.each (record, idx) ->
            ids.push record[0]
            indices.push idx

        # just checking if they were iterated in the correct order
        expect ids
            .toEqual (rec.id for rec in bigJSON)

        expect indices
            .toEqual [0...bigJSON.length]

    ##############################################################################################################
    it "equals", () ->
        expect table.equals(JQL.fromJSON bigJSON)
            .toBe true

    ##############################################################################################################
    it "count", () ->
        expect table.count("*")
            .toBe bigJSON.length

        expect table.count()
            .toBe table.count("*")

        expect table.count("raw_row_number")
            .toBe 1

        expect table.count("id")
            .toBe bigJSON.length

    ##############################################################################################################
    it "delete", () ->
        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
                c: 10
            }
            {
                a: 20
                b: 20
                c: 40
            }
            {
                a: 20
                b: 10
                c: 50
            }
        ]

        expect tempTable.where(a: 20).delete().records
            .toEqual [
                [10, 10, 10]
            ]

        tempTable = JQL.fromJSON [
            {
                a: 10
                b: 10
                c: 10
            }
            {
                a: 20
                b: 20
                c: 40
            }
            {
                a: 20
                b: 10
                c: 50
            }
        ]

        expect tempTable.delete(b: 10).records
            .toEqual [
                [20, 20, 40]
            ]

##################################################################################################################
##################################################################################################################
describe "OpChainer", () ->

    table = JQL.fromJSON bigJSON, "bigTable"
    opChainer = new OpChainer(table)

    it "", () ->
        console.log opChainer
