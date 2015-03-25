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
            try
                expect records[records.length - 1].length
                    .toBe 13
            catch error
                console.warn error.message
            console.log "async done....."
            return true

        schema.addColumn({name: "testColumn4", type: "number"}, true, callback)
        console.log "async starting...."
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

    ##############################################################################################################
    it "where", () ->
        expect table.where(lt: id: 400).records.length
            .toBe 25

        expect table.where(gt: id: 694).records.length
            .toBe 1

        expect table.where(date: "2012-03-01").records.length
            .toBe 21

        expect table.where(detail_html: null, detail_pic: null).records.length
            .toBe 304

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

    ##############################################################################################################
    it "and", () ->
        expect table.where(id: 375).and(table.where(id: 376)).records.length
            .toBe 0

        expect table.where(id: 375).and(table.where(date: "2012-01-01")).records
            .toEqual [[375, "2012-01-01", 95800, "2013-06-06 15:24:35", "2014-01-06 17:36:02", null, null, 1, null]]

    ##############################################################################################################
    it "or", () ->
        expect table.where(id: 375).or(table.where(id: 376)).records
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

        expect joined.records
            .toEqual [
                [10, "asdf", 10, "10"]
                [10, "asdf", 10, "50"]
                [20, "bsdf", 20, "40"]
                [20, "csdf", 20, "40"]
            ]

    ##############################################################################################################
    it "leftJoin", () ->

    ##############################################################################################################
    it "rightJoin", () ->

    ##############################################################################################################
    it "groupBy", () ->

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
        table.each (record, idx) ->
            ids.push record[0]

        # just checking if they were iterated in the correct order
        expect ids
            .toEqual (rec.id for rec in bigJSON)

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
