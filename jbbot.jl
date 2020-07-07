using ZulipJuliaBloggers

include("configuration.jl")

try
    const db = getdb(JBDB)
    const zulip = ZulipClient(email = EMAIL, apikey = API_KEY, ep = ZULIP_EP)
    const posts = ZulipJuliaBloggers.getposts()

    newposts = 0
    updated = 0

    for post in reverse(posts)
        st = process(post, db, zulip)
        newposts += st == "new"
        updated += st == "update"
    end

    @info "Processed $(length(posts)) posts"
    @info "New: $newposts"
    @info "Updated: $updated"
catch err
    # This one is needed for telegram notification
    @error err
    # This one goes to logs
    rethrow()
end
