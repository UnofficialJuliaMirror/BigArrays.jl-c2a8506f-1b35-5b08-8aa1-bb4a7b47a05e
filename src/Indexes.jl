module Indexes
using ..BigArrays

export colon2unit_range, chunkid2global_range, index2chunkid, index2unit_range
export global_range2buffer_range, global_range2chunk_range
export cartesian_range2unit_range, unit_range2string, cartesian_range2string 

# make Array accept cartetian range as index
function cartesian_range2unit_range(r::CartesianRange{CartesianIndex{N}}) where N
    map((x,y)->x:y, r.start.I, r.stop.I)
end

"""
    global_range2buffer_range(globalRange::CartesianRange, bufferGlobalRange::CartesianRange)

Transform a global range to a range inside buffer.
"""
function global_range2buffer_range(globalRange::CartesianRange{CartesianIndex{N}},
                                 bufferGlobalRange::CartesianRange{CartesianIndex{N}}) where N
    start = globalRange.start - bufferGlobalRange.start + 1
    stop  = globalRange.stop  - bufferGlobalRange.start + 1
    return CartesianRange( start, stop )
end

"""
    global_range2chunk_range(globalRange::CartesianRange, bufferGlobalRange::CartesianRange)

Transform a global range to a range inside chunk.
"""
function global_range2chunk_range(globalRange::CartesianRange{CartesianIndex{N}},
                                 chunkSize::NTuple{N};
                                 offset::CartesianIndex{N} = CartesianIndex{N}()-1) where N
    chunkID = index2chunkid(globalRange.start, chunkSize; offset=offset)
    start = index2cartesian_index( map((s,i,sz,o)->s-(i-1)*sz-o, globalRange.start.I,
                                                            chunkID, chunkSize, offset.I))
    stop  = index2cartesian_index( map((s,i,sz,o)->s-(i-1)*sz-o, globalRange.stop.I,
                                                            chunkID, chunkSize, offset.I))
    return CartesianRange(start, stop)
end

function index2chunkid(idx::CartesianIndex{N}, chunkSize::NTuple{N};
                       offset::CartesianIndex{N} = CartesianIndex{N}()-1) where N
    # the offset is actually start of the real data, it could be not aligned to 0 
    ( map((x,y,o)->fld(x-1-o, y)+1, idx.I, chunkSize, offset.I) ... )
end

function chunkid2global_range(chunkID::NTuple{N}, chunkSize::NTuple{N};
                              offset::CartesianIndex{N} = CartesianIndex{N}()-1) where N
    start = index2cartesian_index( map((x,y)->(x-1)*y+1, chunkID, chunkSize) )
    stop  = index2cartesian_index( map((x,y)->x*y,       chunkID, chunkSize) )
    return CartesianRange(start+offset, stop+offset)
end

"""
replace Colon of indexes by UnitRange
"""
function colon2unit_range(buf::AbstractArray, indexes::Tuple)
    colon2unit_range(size(buf), indexes)
end

function colon2unit_range(sz::NTuple{N}, indexes::Tuple) where N
    map((x,y)-> x==Colon() ? UnitRange(1:y) : x, indexes, sz)
end

function index2cartesian_index( idx::Union{Tuple, Vector} )
    CartesianIndex((idx...))
end

# function Base.string{N}(r::CartesianRange{CartesianIndex{N}})
#     ret = ""
#     for d in 1:N
#         s = r.start.I[d]
#         e = r.stop.I[d]
#         ret *= "$s:$e_"
#     end
#     return ret[1:end-1]
# end

function unit_range2string(idxes::Vector)
    ret = ""
    for idx in idxes
        ret *= "$(start(idx)-1)-$(idx[end])_"
    end 
    return ret[1:end-1]
end

function cartesian_range2string(r::CartesianRange{CartesianIndex{N}}) where N
    ret = ""
    for i in 1:3
        ret *= "$(r.start[i]-1)-$(r.stop[i])_"
    end
    return ret[1:end-1]
end

"""
transform string to UnitRange
the format of string should look like this:
2968-3480_1776-2288_16912-17424
-1024--896_-1024--896_1428-1429
"""
function string2unit_range( str::AbstractString )
    groups = match(r"(-?\d+)-(-?\d+)_(-?\d+)-(-?\d+)_(-?\d+)-(-?\d+)(?:\.gz)?$", str)
    idxes = map(parse, groups.captures)
    [idxes[1]+1:idxes[2], idxes[3]+1:idxes[4], idxes[5]+1:idxes[6]]
end 

"""
    adjust bounding box range when fitting in new subarray
"""
function union(globalRange::CartesianRange, idxes::CartesianRange)
    start = map(min, globalRange.start.I, idxes.start.I)
    stop  = map(max, globalRange.stop.I,  idxes.stop.I)
    return CartesianRange(start, stop)
end
function union!(r1::CartesianRange, r2::CartesianRange)
    r1 = union(r1, r2)
end


"""
    transform x1:x2_y1:y2_z1:z2 style string to CartesianRange
"""
function string2cartesian_range( s::String )
    secs = split(s, "_")
    starts = map( x->parse(split(x,"-")[1])+1, secs )
    stops  = map( x->parse(split(x,"-")[2]), secs )
    CartesianRange( CartesianIndex(starts...), CartesianIndex( stops... ) )
end

function index2unit_range(x::UnitRange)
    x
end 
function index2unit_range(x::Int)
    x:x
end

end # end of module
