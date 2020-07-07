currentts() = Dates.format(Dates.now(), "yyyy-mm-ddTHH:MM:SS")
md5hash(text) = bytes2hex(md5(text))

function create_tables(db)
    create_posts = """
    CREATE TABLE IF NOT EXISTS posts
    (
        zuid INTEGER,
        title TEXT,
        id TEXT PRIMARY KEY,
        creator TEXT,
        link TEXT,
        pubdate TEXT,
        body TEXT,
        created TEXT,
        updated TEXT
    ) WITHOUT ROWID
    """
    DBInterface.execute(db, create_posts)
    SQLite.createindex!(db, "posts", "id_index", "id"; unique=true, ifnotexists=true)
end

function issame(x::Post, row)
    return md5hash(x.body) == row.body
end

function status(db, x::Post)
    query = """
    SELECT zuid, title, body
    FROM posts
    WHERE id = ?
    """

    stmt = SQLite.Stmt(db, query)
    res = DBInterface.execute(stmt, (x.guid, ))
    status = "new"
    title = x.title
    msg_id = 0
    for row in res
        msg_id = row.zuid
        title = row.title
        status = issame(x, row) ? "known" : "update"
    end
    
    return (status = status, msg_id = msg_id, title = title)
end

function add!(db, x::Post, response)
    query = """
    INSERT INTO posts(id, zuid, title, link, creator, pubdate, body, created, updated) VALUES  (?, ?, ?, ?, ?, ?, ?, ?, ?) 
    """

    stmt = SQLite.Stmt(db, query)
    ts = currentts()
    DBInterface.execute(stmt, (x.guid, response.id, x.title, x.link, x.creator, Dates.format(x.pubdate, "yyyy-mm-dd HH:MM:SS"), md5hash(x.body), ts, ts))
end

function update!(db, x::Post)
    query = """
    UPDATE posts
    SET link = ?2,
        creator = ?3,
        pubdate = ?4,
        body = ?5,
        updated = ?6
    WHERE
        id = ?1
    """

    stmt = SQLite.Stmt(db, query)
    ts = currentts()
    DBInterface.execute(stmt, (x.guid, x.link, x.creator, Dates.format(x.pubdate, "yyyy-mm-dd HH:MM:SS"), md5hash(x.body), ts))
end

function invalidate_post(db, x::Post)
    query = """
    UPDATE posts
    SET body = ""
    WHERE id = ?
    """

    stmt = SQLite.Stmt(db, query)
    DBInterface.execute(stmt, (x.guid, ))
end
