using ZulipJuliaBloggers

include("configuration.jl")

try
    const db = getdb(JBDB)
    const zulip = ZulipClient(email = EMAIL, apikey = API_KEY, ep = ZULIP_EP)
    const posts = ZulipJuliaBloggers.getposts()

    for post in reverse(posts)
        process(post, db, zulip)
    end
catch err
    # This one is needed for telegram notification
    @error err
    # This one goes to logs
    rethrow()
end
