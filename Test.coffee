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

    @jql = jql = JQL.fromJSON @json
    @colJql = colJql = JQL.new.fromColJSON @colJson
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

    # console.log colJql

    @sqlJql = JQL.new.fromSQL """CREATE TABLE users (
        id INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
        username VARCHAR(16) NOT NULL,
        password DECIMAL (18, 2) NOT NULL,
        PRIMARY KEY ( id,b)
    );
    INSERT INTO users VALUES (1,2,3), (4,5,6);"""

    return "done"

test.call(window)
