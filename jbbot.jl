using ZulipJuliaBloggers

include("configuration.jl")

try
    db = getdb(JBDB)
    zulip = ZulipClient(email = EMAIL, apikey = API_KEY, ep = ZULIP_EP)
    posts = ZulipJuliaBloggers.getposts()

    newposts = 0
    updated = 0

    for post in reverse(posts)
        st = process(post, db, zulip; max_size = MAX_SIZE)
        newposts += st == "new"
        updated += st == "update"
    end

    @info "Processed $(length(posts)) posts"
    @info "New: $newposts"
    @info "Updated: $updated"
catch err
    # This one is needed for telegram notification
    @error "$MSG_PREFIX" err
    # This one goes to logs
    rethrow()
end
