using ZulipJuliaBloggers

include("configuration.jl")

db = getdb(JBDB)
create_tables(db)
