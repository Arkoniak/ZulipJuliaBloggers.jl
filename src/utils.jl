# DB related

getdb(dbname) = SQLite.DB(dbname)

struct Post
    title::String
    link::String
    creator::String
    pubdate::DateTime
    body::String
    guid::String
end
function Post(item)
    d = Dict(name(c) => content(c) for c in child_nodes(item) if name(c) in ["title", "link", "creator", "pubDate", "encoded", "guid"])
    title = get(d, "title", "No title")
    link = get(d, "link", "https://www.juliabloggers.com")
    creator = get(d, "creator", "No author")
    pubdate = get(d, "pubDate", "")
    pubdate = isempty(pubdate) ? DateTime(0) : DateTime(pubdate[1:25], dateformat"eee, dd uuu yyyy HH:MM:SS")
    body = get(d, "encoded", "")

    # This one is tricky. It should be unique, but there is no way to guarantee it.
    # Will cross that bridge when get to it.
    guid = get(d, "guid", link)

    return Post(title, link, creator, pubdate, body, guid)
end

function getposts()
    xroot = @_ HTTP.get("https://www.juliabloggers.com/feed/";
                        require_ssl_verification = false) |>
            String(__.body) |> parse_string |> root

    channel = [c for c in child_nodes(xroot) if is_elementnode(c)][1];
    items = [c for c in child_nodes(channel) if is_elementnode(c) && name(c) == "item"];
    posts = Post.(items)
    
    return posts
end

function html2md(x::HTMLText, io, list)
    print(io, x.text)

    return io
end

function html2md(x, io = IOBuffer(), list = "", max_size = 3000)
    ptr = io.ptr
    if tag(x) == :pre
        # It should be large code block
        print(io, "```\n", nodeText(x), "\n```\n")
    elseif tag(x) == :code
        # This is inline code
        print(io, "`", nodeText(x), "`")
    elseif tag(x) == :a
        # Link
        print(io, "[", nodeText(x), "](", x.attributes["href"], ")")
    elseif tag(x) == :p
        # Paragraph
        for child in x.children
            io = html2md(child, io, list)
            if io.ptr > max_size
                break
            else
                ptr = io.ptr
            end
        end
        io.ptr = ptr
        print(io, "\n\n")
    elseif tag(x) == :ul
        for child in x.children
            io = html2md(child, io, "ul")
            if io.ptr > max_size
                break
            else
                ptr = io.ptr
            end
        end
        io.ptr = ptr
        print(io, "\n\n")
    elseif tag(x) == :li
        # In the future, here should be if/else for different kinds of list (numbered, unnumbered, nested)
        print(io, "+ ")
        for child in x.children
            io = html2md(child, io, "")
            if io.ptr > max_size
                break
            else
                ptr = io.ptr
            end
        end
        io.ptr = ptr
        print(io, "\n\n")
    elseif tag(x) == :blockquote
        # Quote
        print(io, "```quote\n")
        # Bad thing is we are losing all formatting, but let's hope that it is not going to be an issue in most cases
        print(io, nodeText(x))
        print(io, "\n```\n")
    elseif tag(x) == :strong
        print(io, "**")
        for child in x.children
            io = html2md(child, io, "")
            if io.ptr > max_size
                break
            else
                ptr = io.ptr
            end
        end
        io.ptr = ptr
        print(io, "**")
    elseif tag(x) in [:h1, :h2, :h3, :h4, :h5, :h6]
        print(io, "\n\n**", uppercase(nodeText(x)), "**\n\n")
    elseif tag(x) == :body
        for child in x.children
            io = html2md(child, io, list)
            if io.ptr > max_size
                break
            else
                ptr = io.ptr
            end
        end
        io.ptr = ptr
    else
        for child in x.children
            io = html2md(child, io, list)
            if io.ptr > max_size
                break
            else
                ptr = io.ptr
            end
        end
        io.ptr = ptr
    end

    io.ptr = io.ptr > max_size ? ptr : io.ptr
    return io
end

function blogpost(x)
    io = IOBuffer()
    print(io, "[", x.title ,"](", x.link ,")\n")
    pubdate = Dates.format(x.pubdate, "eee, dd uuu yyyy HH:MM:SS")
    print(io, "Published on $pubdate\n\n")

    body = @_ x.body |> parsehtml |> __.root |> matchFirst(sel"body", __)
    iobody = html2md(body)
    ptr = iobody.ptr
    iscomplete = ptr == iobody.size + 1
    msg = take!(iobody)[1:(ptr - 1)] |> String

    print(io, msg)

    if !iscomplete
        print(io, "... [")
        print(io, "[", "Continue >>>" ,"](", x.link, ")")
        print(io, "]")
    end

    msg = take!(io) |> String

    return (topic = x.title, msg = msg)
end

function process(x::Post, db, zulip; to = "blogs", type = "stream")
    st, msg_id, title = status(db, x)
    st == "known" && return
    topic, msg = blogpost(x)
    if st == "new"
        res = sendMessage(zulip; to = to, type = type, topic = topic, content = msg)
        if get(res, :result, "fail") == "success"
            add!(db, x, res)
        else
            @error "Get bad response from zulip server: $res"
        end
    else # st == "update"
        res = updateMessage(zulip, msg_id; to = to, type = type, content = msg, topic = title)
        if get(res, :result, "fail") == "success"
            update!(db, posts[1])
        else
            @error "Get bad response from zulip server: $res"
        end
    end
end
