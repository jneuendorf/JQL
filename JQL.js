// Generated by CoffeeScript 1.8.0
(function() {
  var JQL, arrEquals, cloneObject, getSelf, toArr,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  JQL = {
    config: {
      where: {
        invalidKeyBehavior: "ignore"
      }
    }
  };

  getSelf = function() {
    return this;
  };

  toArr = function(args) {
    return Array.prototype.slice.call(args);
  };

  arrEquals = function(arr1, arr2) {
    var i, x, y, _i, _len;
    if (arr1.length !== arr2.length) {
      return false;
    }
    for (i = _i = 0, _len = arr1.length; _i < _len; i = ++_i) {
      x = arr1[i];
      y = arr2[i];
      if (x instanceof Array && y instanceof Array) {
        if (!arrEquals(x, y)) {
          return false;
        }
      } else if (x !== y) {
        return false;
      }
    }
    return true;
  };

  cloneObject = function(obj) {
    return JSON.parse(JSON.stringify(obj));
  };

  JQL.Schema = (function() {
    var renameColumn;

    Schema.typeToVal = {
      number: 0,
      string: "",
      boolean: false,
      object: {}
    };

    Schema.fromSchema = function(schema) {
      var col, result, _i, _len, _ref;
      result = new JQL.Schema();
      result.names = schema.names.slice(0);
      result.types = schema.types.slice(0);
      _ref = schema.cols;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        col = _ref[_i];
        result.cols.push({
          name: col.name,
          index: col.index,
          type: col.type
        });
      }
      return result;
    };

    function Schema(record, preTyped) {
      var i, k, type, v;
      this.cols = [];
      this.names = [];
      this.types = [];
      if (record != null) {
        i = 0;
        for (k in record) {
          v = record[k];
          if (!preTyped) {
            type = typeof v;
            if ((v != null) && type === "object") {
              type = v.constructor.name;
            }
          } else {
            type = v;
          }
          this.cols.push({
            name: k,
            index: i,
            type: type,
            notNull: false,
            autoIncrement: false,
            prime: false
          });
          this.names.push(k);
          this.types.push(type);
          i++;
        }
      }
    }

    Schema.prototype.setNotNulls = function() {
      var col, cols, _i, _len, _ref, _ref1;
      cols = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (cols[0] instanceof Array) {
        cols = cols[0];
      }
      _ref = this.cols;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        col = _ref[_i];
        if (_ref1 = col.name, __indexOf.call(cols, _ref1) >= 0) {
          col.notNull = true;
        } else if (col.notNull) {
          col.notNull = false;
        }
      }
      return this;
    };

    Schema.prototype.setAutoIncrements = function() {
      var col, cols, _i, _len, _ref, _ref1;
      cols = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (cols[0] instanceof Array) {
        cols = cols[0];
      }
      _ref = this.cols;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        col = _ref[_i];
        if (_ref1 = col.name, __indexOf.call(cols, _ref1) >= 0) {
          col.autoIncrement = true;
        } else if (col.autoIncrement) {
          col.autoIncrement = false;
        }
      }
      return this;
    };

    Schema.prototype.setPrimaryKeys = function() {
      var col, cols, _i, _len, _ref, _ref1;
      cols = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (cols[0] instanceof Array) {
        cols = cols[0];
      }
      _ref = this.cols;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        col = _ref[_i];
        if (_ref1 = col.name, __indexOf.call(cols, _ref1) >= 0) {
          col.prime = true;
        } else if (col.prime) {
          col.prime = false;
        }
      }
      return this;
    };

    Schema.prototype.setPrimes = function() {
      return this.setPrimaryKeys.apply(this, arguments);
    };

    Schema.prototype._updateData = function() {
      var col, i, names, types, _i, _len, _ref;
      names = [];
      types = [];
      _ref = this.cols;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        col = _ref[i];
        names.push(col.name);
        types.push(col.type);
      }
      this.names = names;
      this.types = types;
      return this;
    };

    Schema.prototype.clone = function() {
      return JQL.Schema.fromSchema(this);
    };

    Schema.prototype.and = function(schema) {
      var col, i, indicesToRemove, name, result, _i, _len, _ref;
      result = this.clone();
      indicesToRemove = [];
      _ref = this.names;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        name = _ref[i];
        if (schema.nameToIdx(name) < 0) {
          indicesToRemove.push(i);
        }
      }
      this.cols = (function() {
        var _j, _len1, _ref1, _results;
        _ref1 = this.cols;
        _results = [];
        for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
          col = _ref1[i];
          if (__indexOf.call(indicesToRemove, i) < 0) {
            _results.push(col);
          }
        }
        return _results;
      }).call(this);
      this._updateData();
      return result;
    };

    Schema.prototype.or = function(schema) {};

    Schema.prototype.addColumn = function(col) {
      var colData;
      colData = {
        name: col.name,
        index: this.cols.length,
        type: col.type,
        notNull: col.notNull || false,
        autoIncrement: col.autoIncrement || false,
        prime: col.prime || col.primaryKey || false
      };
      this.cols.push(colData);
      return this;
    };

    Schema.prototype.deleteColumn = function(name) {
      var col, i, idx;
      idx = this.nameToIdx(name);
      this.cols = (function() {
        var _i, _len, _ref, _results;
        _ref = this.cols;
        _results = [];
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          col = _ref[i];
          if (i !== idx) {
            _results.push(col);
          }
        }
        return _results;
      }).call(this);
      this._updateData();
      return this;
    };

    Schema.prototype.renameColumn = function(oldName, newName) {
      this.cols[this.nameToIdx(oldName)].name = newName;
      this._updateData();
      return this;
    };

    Schema.prototype.changeColumn = function(name, type) {
      this.cols[this.nameToIdx(name)].type = type;
      this._updateData();
      return this;
    };

    renameColumn = function(oldName, newName) {
      this.schema.renameColumn(oldName, newName);
      return this;
    };

    Schema.prototype.colNamed = function(name) {
      var col, _i, _len, _ref;
      _ref = this.cols;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        col = _ref[_i];
        if (col.name === name) {
          return col;
        }
      }
      return null;
    };

    Schema.prototype.equals = function(schema) {
      var i, l, n1, n2, t1, t2, _i;
      if ((l = this.cols.length) === schema.cols.length) {
        n1 = this.names;
        n2 = schema.names;
        t1 = this.types;
        t2 = schema.types;
        for (i = _i = 0; 0 <= l ? _i < l : _i > l; i = 0 <= l ? ++_i : --_i) {
          if (n1[i] !== n2[i] || t1[i] !== t2[i]) {
            return false;
          }
        }
        return true;
      }
      return false;
    };

    Schema.prototype.nameToIdx = function(name) {
      return this.names.indexOf(name);
    };

    Schema.prototype.idxToName = function(idx) {
      return this.names[idx];
    };

    return Schema;

  })();


  /*
  select (from), where
  update, set
  join
  insert (into)
  distinct
  functions: avg, sum, count, max, min, first, last
   */

  JQL.Table = (function() {
    Table.sqlToJsType = {
      varchar: "string",
      char: "string",
      int: "number",
      decimal: "number"
    };

    Table["new"] = function(schema, records) {
      return new JQL.Table(schema, records);
    };

    Table["new"].fromJSON = function(json, schema) {
      var col, r, record, records, table, _i, _j, _len, _len1, _ref;
      if (arguments.length === 2) {
        schema = new JQL.Schema(json);
        records = [];
      } else {
        if (json instanceof Array) {
          if (json.length > 0) {
            schema = new JQL.Schema(json[0]);
          } else if (!(schema instanceof JQL.Schema)) {
            schema = new JQL.Schema(schema);
          }
        }
        records = [];
        for (_i = 0, _len = json.length; _i < _len; _i++) {
          record = json[_i];
          r = [];
          _ref = schema.cols;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            col = _ref[_j];
            r.push(record[col.name]);
          }
          records.push(r);
        }
      }
      table = new JQL.Table(schema, records);
      return table || null;
    };

    Table["new"].fromRowJSON = Table["new"].fromJSON;

    Table["new"].fromColJSON = function() {
      var col, cols, i, maxColLength, pseudoRecord, records, _i, _j, _len;
      cols = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (cols[0] instanceof Array) {
        cols = cols[0];
      }
      pseudoRecord = {};
      maxColLength = 0;
      for (_i = 0, _len = cols.length; _i < _len; _i++) {
        col = cols[_i];
        pseudoRecord[col.name] = col.type || typeof col.vals[0];
        if (col.vals.length > maxColLength) {
          maxColLength = col.vals.length;
        }
      }
      records = [];
      for (i = _j = 0; 0 <= maxColLength ? _j < maxColLength : _j > maxColLength; i = 0 <= maxColLength ? ++_j : --_j) {
        records.push((function() {
          var _k, _len1, _results;
          _results = [];
          for (_k = 0, _len1 = cols.length; _k < _len1; _k++) {
            col = cols[_k];
            _results.push(col.vals[i] || null);
          }
          return _results;
        })());
      }
      return new JQL.Table(new JQL.Schema(pseudoRecord, true), records);
    };

    Table["new"].fromSQL = function(sql) {
      var autoIncrements, col, colDef, colDefRegex, colName, createTableRegex, info, insertRegex, match, matches, name, notNulls, options, primareKeyRegex, primaryKeys, pseudoRecord, records, schema, table, tableData, tables, type, value, values, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m;
      sql = sql.replace(/\`/g, "");
      createTableRegex = /CREATE\s+TABLE\s+(\w+)\s*\(\s*(\w+)\s+(\w+)\s*(\(\s*(\w+)(\s*,\s*(\w+))*\s*\))?\s*((\w+)\s+)*(\w+)?(\s*,\s*(\w+)\s+(\w+)\s*(\(\s*(\w+)(\s*,\s*(\w+))*\s*\))?\s*((\w+)\s+)*(\w+)?)*\)/gi;
      colDefRegex = /(\w+)\s+(\w+)\s*(\(\s*\w+(\s*,\s*\w+)*\s*\))?\s*((\w+)\s+)*(\w+)?/gi;
      primareKeyRegex = /PRIMARY\s+KEY\s*\(\s*\w+(\s*,\s*\w+)*\s*\)/gi;
      insertRegex = /INSERT INTO\s+(\w+)\s*(\(\w+(\s*,\s*\w+)*\)\s+)?(VALUES\s+\((\w+|\d+|'\w+')(\s*,\s*(\w+|\d+|'\w+'))*\)(\s*,\s*\((\w+|\d+|'\w+')(\s*,\s*(\w+|\d+|'\w+'))*\))*)/gi;
      if ((matches = sql.match(createTableRegex)) != null) {
        tables = {};
        for (_i = 0, _len = matches.length; _i < _len; _i++) {
          match = matches[_i];
          info = createTableRegex.exec(match);
          createTableRegex.lastIndex = 0;
          name = info[1];
          tableData = match.slice(match.indexOf("(") + 1, -1).trim().replace(/\n/g, "").replace(/\s+/g, " ").split(/\s*\,(?![^\(]*\))\s*/g);
          pseudoRecord = {};
          notNulls = [];
          autoIncrements = [];
          primaryKeys = [];
          for (_j = 0, _len1 = tableData.length; _j < _len1; _j++) {
            colDef = tableData[_j];
            if (!colDef.match(primareKeyRegex)) {
              colDef = colDef.replace(/\(\s*\w+(\s*,\s*\w+)*\s*\)/g, "").replace(/NOT\s+NULL/gi, "notnull").replace(/AUTO_INCREMENT/gi, "autoincrement").replace(/UNSIGNED/gi, "").split(/\s+/g);
              colName = colDef[0];
              type = JQL.Table.sqlToJsType[colDef[1].toLowerCase()];
              options = colDef.slice(2);
              pseudoRecord[colName] = type;
              if (__indexOf.call(options, "notnull") >= 0) {
                notNulls.push(colName);
              }
              if (__indexOf.call(options, "autoincrement") >= 0) {
                autoIncrements.push(colName);
              }
            } else {
              colDef = colDef.replace(/PRIMARY\s+KEY\s*\((.*)\)/gi, "$1").split(/\s*,\s*/g);
              for (_k = 0, _len2 = colDef.length; _k < _len2; _k++) {
                col = colDef[_k];
                primaryKeys.push(col.trim());
              }
            }
          }
          schema = new JQL.Schema(pseudoRecord, true);
          if (notNulls.length > 0) {
            schema.setNotNulls(notNulls);
          }
          if (autoIncrements.length > 0) {
            schema.setAutoIncrements(autoIncrements);
          }
          if (primaryKeys.length > 0) {
            schema.setPrimaryKeys(primaryKeys);
          }
          tables[name] = new JQL.Table(schema, [], name);
        }
        if ((matches = sql.match(insertRegex)) != null) {
          for (_l = 0, _len3 = matches.length; _l < _len3; _l++) {
            match = matches[_l];
            info = insertRegex.exec(match);
            insertRegex.lastIndex = 0;
            name = info[1];
            values = info[4];
            values = values.slice(values.indexOf("(")).split(/\s*\,(?![^\(]*\))\s*/g);
            if ((table = tables[name]) != null) {
              records = [];
              for (_m = 0, _len4 = values.length; _m < _len4; _m++) {
                value = values[_m];
                value = value.replace(/\s+/g, "").slice(value.indexOf("(") + 1, value.indexOf(")")).split(/\s*,\s*/g);
                records.push(value);
              }
              table.insert(records);
            } else {
              console.warn("Table '" + name + "' does not exist! Create (first) with CREATE TABLE!");
            }
          }
        }
        console.log(tables);
        return tables;
      }
      console.warn("SQL statement somehow invalid (back ticks erased already):", sql);
      return null;
    };

    Table["new"].fromTable = function(table) {
      var record;
      return new JQL.Table(table.schema.clone(), (function() {
        var _i, _len, _ref, _results;
        _ref = table.records;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          record = _ref[_i];
          _results.push(record.slice(0));
        }
        return _results;
      })());
    };

    function Table(schema, records, name, partOf) {
      var col, cols, i, key, pseudoRecord, type, val, _i, _j, _len, _len1;
      if (name == null) {
        name = "Table";
      }
      if (partOf == null) {
        partOf = null;
      }
      if (schema instanceof JQL.Schema) {
        this.schema = schema;
        this.records = records || [];
        this.name = name;
        this.partOf = partOf;
      } else {
        pseudoRecord = {};
        if (schema instanceof Array) {
          for (i = _i = 0, _len = schema.length; _i < _len; i = _i += 2) {
            col = schema[i];
            type = schema[i + 1];
            pseudoRecord[col] = type;
          }
        } else if (arguments.length === 1) {
          pseudoRecord = schema;
        } else {
          cols = toArr(arguments);
          for (_j = 0, _len1 = cols.length; _j < _len1; _j++) {
            col = cols[_j];
            for (key in col) {
              val = col[key];
              if (pseudoRecord[key] == null) {
                pseudoRecord[key] = val;
              }
            }
          }
        }
        this.schema = new JQL.Schema(pseudoRecord, true);
        this.records = [];
        this.name = "Table";
        this.partOf = null;
      }
      Object.defineProperties(this, {
        update: {
          get: getSelf,
          set: getSelf
        }
      });
    }

    Table.prototype.clone = function() {
      return JQL.Table["new"].fromTable(this);
    };

    Table.prototype.row = function(n) {
      return new JQL.Table(this.schema, [this.records[n]], this.name, this);
    };

    Table.prototype.col = function(n) {
      var record;
      if (typeof n === "string") {
        n = this.schema.nameToIdx(n);
      }
      return (function() {
        var _i, _len, _ref, _results;
        _ref = this.records;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          record = _ref[_i];
          _results.push(record[n]);
        }
        return _results;
      }).call(this);
    };

    Table.prototype.select = function() {
      var col, cols, i, indicesToKeep, record, records, schema, _i, _len, _ref;
      cols = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if ((cols == null) || cols[0] === "*") {
        return this;
      }
      schema = this.schema.clone();
      indicesToKeep = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = cols.length; _i < _len; _i++) {
          col = cols[_i];
          if (__indexOf.call(schema.names, col) >= 0) {
            _results.push(schema.nameToIdx(col));
          }
        }
        return _results;
      })();
      records = [];
      _ref = this.records;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        records.push((function() {
          var _j, _len1, _results;
          _results = [];
          for (i = _j = 0, _len1 = record.length; _j < _len1; i = ++_j) {
            col = record[i];
            if (__indexOf.call(indicesToKeep, i) >= 0) {
              _results.push(col);
            }
          }
          return _results;
        })());
      }
      schema.cols = (function() {
        var _j, _len1, _ref1, _ref2, _results;
        _ref1 = schema.cols;
        _results = [];
        for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
          col = _ref1[i];
          if (_ref2 = col.index, __indexOf.call(indicesToKeep, _ref2) >= 0) {
            _results.push(col);
          }
        }
        return _results;
      })();
      schema._updateData();
      return new JQL.Table(schema, records, this.name, this);
    };

    Table.prototype.project = function() {
      return this.select.apply(this, arguments);
    };

    Table.prototype.where = function(predicate) {
      var check, map, pool, record, records, schema, self, _i, _len, _ref;
      if (predicate instanceof Function) {
        _ref = this.records;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          record = _ref[_i];
          if (predicate(record)) {
            return record;
          }
        }
      }
      schema = this.schema;
      records = this.records;
      map = schema.nameToIdx.bind(schema);
      pool = {
        isnt: function(predicate, record) {
          var key, val;
          for (key in predicate) {
            val = predicate[key];
            if (record[map(key)] === val) {
              return false;
            }
          }
          return true;
        },
        is: function(predicate, record) {
          var key, val;
          for (key in predicate) {
            val = predicate[key];
            if (record[map(key)] !== val) {
              return false;
            }
          }
          return true;
        },
        lt: function(predicate, record) {
          var key, val;
          for (key in predicate) {
            val = predicate[key];
            if (record[map(key)] >= val) {
              return false;
            }
          }
          return true;
        },
        gt: function(predicate, record) {
          var key, val;
          for (key in predicate) {
            val = predicate[key];
            if (record[map(key)] <= val) {
              return false;
            }
          }
          return true;
        },
        lte: function(predicate, record) {
          var key, val;
          for (key in predicate) {
            val = predicate[key];
            if (record[map(key)] > val) {
              return false;
            }
          }
          return true;
        },
        gte: function(predicate, record) {
          var key, val;
          for (key in predicate) {
            val = predicate[key];
            if (record[map(key)] < val) {
              return false;
            }
          }
          return true;
        }
      };
      self = this;
      check = function(predicate, record) {
        var key, val;
        for (key in predicate) {
          val = predicate[key];
          if (__indexOf.call(schema.names, key) >= 0) {
            if (record[map(key)] !== val) {
              return false;
            }
          } else if ((pool[key] != null) && !pool[key](val, record)) {
            return false;
          }
        }
        return true;
      };
      return new JQL.Table(this.schema.clone(), (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = records.length; _j < _len1; _j++) {
          record = records[_j];
          if (check(predicate, record)) {
            _results.push(record);
          }
        }
        return _results;
      })(), this.name, this);
    };

    Table.prototype.alter = function() {};

    Table.prototype.alter.addColumn = function(col) {
      var record, _i, _len, _ref;
      if (col.notNull === true && !col.initVal) {
        console.warn("Can't add NOT NULL column if no initial value is given!");
        return this;
      }
      this.schema.addColumn(col);
      _ref = this.records;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        record.push(col.initVal || null);
      }
      return this;
    };

    Table.prototype.alter.deleteColumn = function(colName) {
      var col, i, idx, j, record, _i, _len, _ref;
      this.schema.deleteColumn(colName);
      idx = this.schema.nameToIdx(colName);
      _ref = this.records;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        record = _ref[i];
        this.records[i] = (function() {
          var _j, _len1, _results;
          _results = [];
          for (j = _j = 0, _len1 = record.length; _j < _len1; j = ++_j) {
            col = record[j];
            if (j !== idx) {
              _results.push(col);
            }
          }
          return _results;
        })();
      }
      return this;
    };

    Table.prototype.alter.dropColumn = function() {
      return this.alter.deleteColumn.apply(this, arguments);
    };

    Table.prototype.alter.changeColumn = function(name, type) {
      this.schema.changeColumn(name, type);
      return this;
    };

    Table.prototype.alter.changeColumnType = function() {
      return this.alter.changeColumn.apply(this, arguments);
    };

    Table.prototype.alter.renameColumn = function(oldName, newName) {
      this.schema.renameColumn(oldName, newName);
      return this;
    };

    Table.prototype.alter.changeColumnName = function() {
      return this.alter.renameColumn.apply(this, arguments);
    };

    Table.prototype.rename = function(name) {
      this.name = "" + name;
      return this;
    };

    Table.prototype.and = function(table) {
      var record;
      return new JQL.Table(this.schema.clone(), (function() {
        var _i, _len, _ref, _results;
        _ref = this.records;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          record = _ref[_i];
          if (__indexOf.call(table.records, record) >= 0) {
            _results.push(record);
          }
        }
        return _results;
      }).call(this));
    };

    Table.prototype.or = function(table) {
      return new JQL.Table(this.schema.clone(), this.records.concat(table.records));
    };

    Table.prototype.join = function(table, col) {};

    Table.prototype.set = function() {};

    Table.prototype.unique = function() {};

    Table.prototype.distinct = function() {
      return this.unique.applu(this, arguments);
    };

    Table.prototype.groupBy = function(aggregation) {};

    Table.prototype.orderBy = function() {
      var cols, schema;
      cols = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (cols[0] instanceof Array) {
        cols = cols[0];
      }
      schema = this.schema;
      this.records.sort(function(r1, r2) {
        var col, idx, _i, _len;
        for (_i = 0, _len = cols.length; _i < _len; _i++) {
          col = cols[_i];
          idx = schema.nameToIdx(col);
          if (r1[idx] < r2[idx]) {
            return -1;
          }
          if (r1[idx] > r2[idx]) {
            return 1;
          }
        }
        return 0;
      });
      return this;
    };

    Table.prototype.insert = function() {
      var name, r, record, records, _i, _j, _len, _len1, _ref;
      records = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (records[0] instanceof Array) {
        records = records[0];
      }
      for (_i = 0, _len = records.length; _i < _len; _i++) {
        record = records[_i];
        if (record instanceof Array) {
          this.records.push(record);
        } else {
          r = [];
          _ref = this.schema.names;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            name = _ref[_j];
            r.push(record[name]);
          }
          this.records.push(r);
        }
      }
      return this;
    };

    Table.prototype["delete"] = function(param) {
      var child, childRecord, i, incidesToRemove, record, _i, _j, _len, _len1, _ref, _ref1, _ref2;
      if (param instanceof JQT.Table) {
        child = param;
        incidesToRemove = [];
        _ref = param.records;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          childRecord = _ref[_i];
          _ref1 = this.records;
          for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
            record = _ref1[i];
            if (!(arrEquals(childRecord, record))) {
              continue;
            }
            incidesToRemove.push(i);
            break;
          }
        }
        this.records = (function() {
          var _k, _len2, _ref2, _results;
          _ref2 = this.records;
          _results = [];
          for (i = _k = 0, _len2 = _ref2.length; _k < _len2; i = ++_k) {
            record = _ref2[i];
            if (__indexOf.call(incidesToRemove, i) < 0) {
              _results.push(record);
            }
          }
          return _results;
        }).call(this);
      } else if (param != null) {
        this["delete"](this.where(param.where || predicate));
      } else {
        if ((_ref2 = this.partOf) != null) {
          _ref2["delete"](this);
        }
      }
      return this;
    };

    Table.prototype["delete"].where = function() {
      return this["delete"].apply(this, arguments);
    };

    Table.prototype.each = function(callback) {
      var i, record, _i, _len, _ref;
      _ref = this.records;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        record = _ref[i];
        if (callback(record, i) === false) {
          break;
        }
      }
      return this;
    };

    Table.prototype.toJSON = function() {
      var col, i, map, obj, record, res, _i, _j, _len, _len1, _ref, _ref1;
      res = [];
      map = this.schema.idxToName.bind(this.schema);
      _ref = this.records;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        obj = {};
        _ref1 = this.schema.cols;
        for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
          col = _ref1[i];
          obj[map(i)] = record[i];
        }
        res.push(obj);
      }
      return res;
    };

    return Table;

  })();

  JQL["new"] = JQL.Table["new"];

  JQL.fromJSON = JQL["new"].fromJSON;

  window.test = function() {
    var arr1, arr2, arr3, colJql, jql, t1, t2, t3;
    this.json = [
      {
        id: 0,
        a: 10,
        b: "20",
        c: true
      }, {
        id: 1,
        a: -1,
        b: "jim",
        c: false
      }
    ];
    this.colJson = [
      {
        name: "col1",
        type: "testType",
        vals: ["val11", "val12"]
      }, {
        name: "col2",
        vals: ["val21", "val22"]
      }
    ];
    arr1 = [1, true, "asdf", [1, 2, 3], 4];
    arr2 = [1, true, "asdf", [1, 2, 3], 4];
    arr3 = [[1, 2], [3, 4]];
    console.log("comparing arrays:");
    console.log(arrEquals(arr1, arr2));
    console.log(arrEquals(arr1, arr3));
    this.jql = jql = JQL.fromJSON(this.json);
    this.colJql = colJql = JQL["new"].fromColJSON(this.colJson);
    console.log(jql);
    console.log(jql.select("id", "b").where({
      a: 10
    }));
    console.log(jql.where({
      a: 10
    }).select("id", "b"));
    t1 = new JQL.Table(["id", "number", "text", "string", "img", "string"]);
    t2 = new JQL.Table({
      id: "number"
    }, {
      text: "string"
    }, {
      img: "string"
    });
    t3 = new JQL.Table({
      id: "number",
      text: "string",
      img: "string"
    });
    this.sqlJql = JQL["new"].fromSQL("CREATE TABLE users (\n    id INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,\n    username VARCHAR(16) NOT NULL,\n    password DECIMAL (18, 2) NOT NULL,\n    PRIMARY KEY ( id,b)\n);\nINSERT INTO users VALUES (1,2,3), (4,5,6);");
    return "done";
  };

  test.call(window);

}).call(this);
