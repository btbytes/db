module db.interfaces;

public import db.api;

import std.regex;

auto   regexDbParam = ctRegex!(`\$(\w+)`, "g");

interface DbDriverCreator {
  DbDriver  create();
  @property string   name()    const;
  @property string[] aliases() const;
}

interface DbDriver {
  @property string    name()   const;
  @property bool      isOpen() const;
  @property DbError   error()  const;
  @property void*     handle();
  @property DbResult  result();
//string    databaseName() const
  bool hasFeature(Database.Feature);

  bool transactionBegin();
  bool transactionCommit();
  bool transactionRollback();

  bool open(URI uri);
  void close();
//  DbResult createResult();
// QString   escapeIdentifier(const QString & identifier, IdentifierType type) const
// QString   formatValue(const QSqlField & field, bool trimStrings = false) const
// bool  isIdentifierEscaped(const QString & identifier, IdentifierType type) const

// QSqlIndex   primaryIndex(const QString & tableName) const
// QSqlRecord  record(const QString & tableName) const
// QString   sqlStatement(StatementType type, const QString & tableName, const QSqlRecord & rec, bool preparedStatement) const
// QString   stripDelimiters(const QString & identifier, IdentifierType type) const
// string[]   tables(QSql::TableType tableType);

// QStringList   subscribedToNotifications() const
// bool  subscribeToNotification(const QString & name)
// bool  unsubscribeFromNotification(const QString & name)
}

mixin template DbDriverMixin() {
  private {
    Version           _version;
    URI               _uri;
    DbDriverCreator   _creator;
    DbError           _error;
  }
  @property string name() const { return _creator.name;   }
  @property bool isOpen() const { return _handle != null; }
  @property DbError error()   const { return _error; }
   
  @property void*    handle() { return cast(void*)(handle); }
  @property DbResult result() { return _result; }
    
  bool transactionBegin()    { return !hasFeature(Database.Feature.Transactions) ? false : exec("BEGIN"); }
  bool transactionCommit()   { return !hasFeature(Database.Feature.Transactions) ? false : exec("COMMIT"); }
  bool transactionRollback() { return !hasFeature(Database.Feature.Transactions) ? false : exec("ROLLBACK"); }

  private void errorClear() {
    if (_error.type != DbError.Type.None) {
      _error = DbError(DbError.Type.None);
    }
  } 
}



interface DbResult {
  @property DbError  error()  const;
  @property ulong    length() const;
  @property ulong    rowsAffectedCount() const;
  @property ulong    fieldsCount() const;
  @property string[] fieldsNames();
  @property Variant  lastInsertId();
  @property Database.NumericPrecision numericPrecision() const;
  @property Database.NumericPrecision numericPrecision(Database.NumericPrecision p);

  bool prepare(string query);
  bool exec(Variant[string] params = (Variant[string]).init);
  void clear();

  bool seek(long index, bool relative = false);
  bool first();
  bool previous();
  bool next();
  bool last();
  bool nextSet(); 

  Variant opIndex(ulong index);
//QSqlResult(const QSqlDbDriver * db)
//const QSqlDbDriver *  DbDriver() const
//QString   executedQuery() const
//virtual bool  fetch(int index) = 0
//virtual bool  fetchFirst() = 0
//virtual bool  fetchLast() = 0
//virtual bool  fetchNext()
//virtual bool  fetchPrevious()
//bool  hasOutValues() const
//bool  isActive() const
//bool  isForwardOnly() const
//virtual bool  isNull(int index) = 0
//bool  isSelect() const
//bool  isValid() const
//QString   lastQuery() const
//virtual int   numRowsAffected() = 0
//virtual bool  prepare(const QString & query)
//virtual QSqlRecord  record() const
//virtual bool  reset(const QString & query) = 0
//void  resetBindCount()
//virtual bool  savePrepare(const QString & query)
//virtual void  setActive(bool active)
//virtual void  setAt(int index)
//virtual void  setForwardOnly(bool forward)
//virtual void  seterror(const QSqlError & error)
//virtual void  setSelect(bool select)
}



mixin template DbResultMixin() {
  private {
    bool                      _firstFetch;
    ulong                     _row;
    ulong                     _length;
    ulong                     _fieldsCount;
    ulong                     _affectedCount;
    DbError                   _error;
    string[]                  _fieldsNames = [];
    string[]                  _paramsTokens;
    string[]                  _paramsKeys;
    Database.NumericPrecision _precision;
  }
  @property DbError  error()             const { return _error; }
  @property ulong    length()            const { return _length; }
  @property ulong    rowsAffectedCount() const { return _affectedCount; }
  @property ulong    fieldsCount()       const { return _fieldsCount; }
  @property string[] fieldsNames() { return _fieldsNames; }
  @property Database.NumericPrecision numericPrecision() const {
    return _precision;
  }
  @property Database.NumericPrecision numericPrecision(Database.NumericPrecision p) {
    return _precision = p;
  }
  bool seek(long pos, bool relative = false) {
    if (_length == 0) {
      return false;
    }
    if (relative) {
      auto newPos = _row;
      if (_firstFetch) {
        newPos += pos;
      } else {
        _firstFetch = true;
      }
      if (newPos >= 0 && newPos < _length) {
        _row = newPos;
      } else {
        return false;
      }
    } else if (pos < 0) {
      return false;
    } else {
      _row = pos;
    }  
    return fetch();
  }
  bool first() {
    _row = 0;
    return seek(0); 
  }
  bool previous() {
    return seek(-1, true);
  }
  bool next() {
    return seek(+1, true);
  }
  bool last() {
    return seek(_length - 1);
  }
  
  bool nextSet(){
    return false;
  }
private:
  void cleanup() {
    _row      = 0;
    _length   = 0;
    _firstFetch   = false;
    _fieldsCount  = 0;
    _fieldsTypes.length  = 0;
    _paramsTokens.length = 0;
    _paramsKeys.length   = 0;  
    _fieldsNames.length  = 0;
  }
  void errorClear() {
    if (_error.type != DbError.Type.None) {
      _error = DbError(DbError.Type.None);
    }
  }
  void checkForError(string txt, bool ok, DbError.Type t = DbError.Type.Statement) {
    if (!ok) {
      errorTake(t, txt);
    }
  }
}