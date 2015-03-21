window.test = () ->
    @json = [
        {
            id: 0
            a: 10
            b: "20"
            c: true
        }
        {
            id: 1
            a: -1
            b: "jim"
            c: false
        }
    ]
    @json2 = [
        {
            x: 1
            y: 34
        }
        {
            x: 0
            y: 10
        }
    ]
    @colJson = [
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
                "val21"
                "val22"
            ]
        }
    ]

    start = Date.now()
    # @bigJqlPart = bigJql.where({
    #     lt:
    #         id: 400
    # }).or(bigJql.where({
    #     gt:
    #         id: 2400
    # }))
    console.log @bigJqlPart = bigJql.where({
        lt:
            id: 400
    }).and(bigJql.where({
        lt:
            id: 380
    })).select("id", "date")
    end = Date.now()
    console.log "query time = #{end-start} ms"
    return


    @jql = jql = JQL.fromJSON @json
    @jql2 = jql2 = JQL.fromJSON @json2
    @colJql = colJql = JQL.new.fromColJSON @colJson
    # jql.name = "A"
    # jql2.name = "B"
    console.log jql

    # console.log jql.where {
    #     id: 1
    # }
    #
    # console.log jql.where {
    #     lt:
    #         a: 13
    #         b: "a"
    # }
    #
    # console.log jql.where {
    #     a: 10
    #     c: true
    # }

    # console.log jql.row(1).toJSON()
    #
    # console.log jql.col "b"

    console.log jql.select("id", "b").where(a: 10)
    console.log jql.where(a: 10).select("id", "b")


    t1 = new JQL.Table(["id", "number", "text", "string", "img", "string"])
    t2 = new JQL.Table(
        {id: "number"}
        {text: "string"}
        {img: "string"}
    )
    t3 = new JQL.Table(
        id: "number"
        text: "string"
        img: "string"
    )

    # console.log t1.schema.equals(t2.schema) and t2.schema.equals(t3.schema)

    @sqlJql = JQL.new.fromSQL """CREATE TABLE users (
        id INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
        username VARCHAR(16) NOT NULL,
        password DECIMAL (18, 2) NOT NULL,
        PRIMARY KEY ( id,b)
    );
    INSERT INTO users VALUES (1,2,3), (4,5,6);"""

    console.log jql.join(jql2, "a", "y")

    return "done"

# test.call(window)


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
start = Date.now()
table = JQL.fromJSON bigJSON, "bigTable"
loadingTime = Date.now() - start
schema = table.schema
records = table.records

describe "miscellaneous", () ->

    it "loading big data", () ->
        expect loadingTime
            .toBeLessThan 500

    it "arrEquals", () ->
        arr1 = [1, true, "asdf", [1,2,3], 4]
        arr2 = [1, true, "asdf", [1,2,3], 4]
        arr3 = [[1,2], [3,4]]

        expect arrEquals(arr1, arr2)
            .toBe true

        expect arrEquals(arr1, arr3)
            .toBe false


describe "JQL.Schema", () ->

    it "clone and equals", () ->
        expect schema.clone().equals(schema)
            .toBe true

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
            console.log "async done!"
            expect records[records.length - 1].length
                .toBe 13
            return true

        schema.addColumn({name: "testColumn4", type: "number"}, true, callback)
        expect records[records.length - 1].length
            .toBe 12
        console.log "after expect"


    it "deleteColumn", () ->
        names = (name for name in schema.names when name not in ["testColumn", "testColumn2"])

        expect schema.deleteColumns("testColumn", "testColumn2").names
            .toEqual names

        expect schema.at("testColumn")
            .toBe null


        console.log table.where(id: 692).select("testColumn", "testColumn2")

        expect table.where(id: 692).select("testColumn", "testColumn2").records
            .toEqual [[]]

    # it "", () ->
    #
    # it "", () ->
    #
    # it "", () ->
    #
    # it "", () ->


describe "JQL.Table", () ->

    it "constructor", () ->
        expect schema
            .toBe table.schema

        expect table
            .toBe schema.table

        expect table.name
            .toBe "bigTable"

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



    it "where", () ->
        expect table.where(lt: id: 400).records.length
            .toBe 25
