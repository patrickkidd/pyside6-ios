// Stub implementations for Harfbuzz graph symbols that are referenced
// from hb-subset.cc but never defined in Qt's bundled Harfbuzz build.
// Font subsetting is unused at runtime in an iOS app.

namespace graph {
struct graph_t {};
struct gsubgpos_graph_context_t {
    gsubgpos_graph_context_t(unsigned int, graph_t&);
    unsigned int create_node(unsigned int);
};
gsubgpos_graph_context_t::gsubgpos_graph_context_t(unsigned int, graph_t&) {}
unsigned int gsubgpos_graph_context_t::create_node(unsigned int) { return 0; }
}
