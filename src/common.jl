# Common facilities

typealias AttributeDict Dict{UTF8String, Any}

#################################################
#
#  vertex types
#
################################################

vertex_index(v::Integer) = v

immutable KeyVertex{K}
    index::Int
    key::K
end

KeyVertex{K}(idx::Int, key::K) = KeyVertex{K}(idx, key)
make_vertex{V<:KeyVertex}(g::AbstractGraph{V}, key) = V(num_vertices(g) + 1, key)
vertex_index(v::KeyVertex) = v.index

type ExVertex
    index::Int
    label::UTF8String
    attributes::AttributeDict
    
    ExVertex(i::Int, label::String) = new(i, label, AttributeDict())    
end

make_vertex(g::AbstractGraph{ExVertex}, label::String) = ExVertex(num_vertices(g) + 1, utf8(label))
vertex_index(v::ExVertex) = v.index
attributes(v::ExVertex, g::AbstractGraph) = v.attributes


#################################################
#
#  edge types
#
################################################

immutable Edge{V}
    index::Int
    source::V
    target::V
end
typealias IEdge Edge{Int}

Edge{V}(i::Int, s::V, t::V) = Edge{V}(i, s, t)
make_edge{V,E<:Edge}(g::AbstractGraph{V,E}, s::V, t::V) = Edge(num_edges(g) + 1, s, t)

revedge{V}(e::Edge{V}) = Edge(e.index, e.target, e.source)

edge_index(e::Edge) = e.index
source(e::Edge) = e.source
target(e::Edge) = e.target
source{V}(e::Edge{V}, g::AbstractGraph{V}) = e.source
target{V}(e::Edge{V}, g::AbstractGraph{V}) = e.target

type ExEdge{V}
    index::Int
    source::V
    target::V
    attributes::AttributeDict
end

ExEdge{V}(i::Int, s::V, t::V) = ExEdge{V}(i, s, t, AttributeDict())
ExEdge{V}(i::Int, s::V, t::V, attrs::AttributeDict) = ExEdge{V}(i, s, t, attrs)
make_edge{V}(g::AbstractGraph{V}, s::V, t::V) = ExEdge(num_edges(g) + 1, s, t)

revedge{V}(e::ExEdge{V}) = ExEdge{V}(e.index, e.target, e.source, e.attributes)

edge_index(e::ExEdge) = e.index
source(e::ExEdge) = e.source
target(e::ExEdge) = e.target
source{V}(e::ExEdge{V}, g::AbstractGraph{V}) = e.source
target{V}(e::ExEdge{V}, g::AbstractGraph{V}) = e.target
attributes(e::ExEdge, g::AbstractGraph) = e.attributes


#################################################
#
#  iteration
#
################################################

immutable VecProxy{A, I}
    vec::A
    len::Int
    inds::I
end

vec_proxy{A,I}(vec::A, inds::I) = VecProxy(vec, length(inds), inds)

length(proxy::VecProxy) = proxy.len
isempty(proxy::VecProxy) = isempty(proxy.inds)
getindex(proxy::VecProxy, i::Integer) = proxy.vec[proxy.inds[i]]

start(proxy::VecProxy) = 1
next(proxy::VecProxy, s::Int) = (proxy.vec[proxy.inds[s]], s+1)
done(proxy::VecProxy, s::Int) =  s > proxy.len

# out_neighbors proxy

immutable OutNeighborsProxy{EList}
    len::Int
    edges::EList
end

out_neighbors_proxy{EList}(edges::EList) = OutNeighborsProxy(length(edges), edges)

length(proxy::OutNeighborsProxy) = proxy.len
isempty(proxy::OutNeighborsProxy) = proxy.len == 0
getindex(proxy::OutNeighborsProxy, i::Integer) = target(proxy.edges[i])

start(proxy::OutNeighborsProxy) = 1
next(proxy::OutNeighborsProxy, s::Int) = (proxy[s], s+1)
done(proxy::OutNeighborsProxy, s::Int) =  s > proxy.len


#################################################
#
#  convenient functions
#
################################################

isnz(x::Bool) = x
isnz(x::Number) = x != zero(x)

multivecs{T}(::Type{T}, n::Int) = [T[] for _ =1:n]

function collect_edges{V,E}(graph::AbstractGraph{V,E})
            
    if implements_edge_list(graph)
        collect(edges(graph))                
            
    elseif implements_vertex_list(graph) && implements_incidence_list(graph)
        edges = Array(E, 0)    
        sizehint(edges, num_edges(graph))
    
        for v in vertices(graph)
            for e in out_edges(v, graph)
                push!(edges, e)
            end
        end    
        edges
    else
        throw(ArgumentError("graph must implement either edge_list or incidence_list."))
    end    
end


immutable WeightedEdge{E,W}
    edge::E
    weight::W
end

isless{E,W}(a::WeightedEdge{E,W}, b::WeightedEdge{E,W}) = a.weight < b.weight

function collect_weighted_edges{V,E,W}(graph::AbstractGraph{V,E}, weights::AbstractVector{W})
    
    @graph_requires graph edge_map
    
    wedges = Array(WeightedEdge{E,W}, 0)
    sizehint(wedges, num_edges(graph))
            
    if implements_edge_list(graph)
        for e in edges(graph)
            w = weights[edge_index(e, graph)]
            push!(wedges, WeightedEdge(e, w))
        end               
            
    elseif implements_vertex_list(graph) && implements_incidence_list(graph)    
        for v in vertices(graph)
            for e in out_edges(v, graph)
                w = weights[edge_index(e, graph)]
                push!(wedges, WeightedEdge(e, w))
            end
        end    
    else
        throw(ArgumentError("graph must implement either edge_list or incidence_list."))
    end  
    
    return wedges  
end

