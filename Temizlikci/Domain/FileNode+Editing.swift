import Foundation

extension FileNode {
    /// This directory without the descendant reached by following `path` (IDs from a child of this node
    /// down to the item), with every folder on the way re-totalled. `nil` if the path doesn't exist.
    nonisolated func removingDescendant(at path: ArraySlice<String>) -> FileNode? {
        guard kind == .directory, let first = path.first, let index = children.firstIndex(where: { $0.id == first }) else { return nil }
        var updated = children
        if path.count == 1 {
            updated.remove(at: index)
        } else {
            guard let child = children[index].removingDescendant(at: path.dropFirst()) else { return nil }
            updated[index] = child
        }
        return .directory(url: url, modificationDate: modificationDate, children: updated)
    }

    /// This directory with `node` added inside the folder reached by `path` (IDs from a child of this
    /// node down to the new parent; empty means directly here). `nil` if the path doesn't exist.
    nonisolated func insertingDescendant(_ node: FileNode, under path: ArraySlice<String>) -> FileNode? {
        guard kind == .directory else { return nil }
        guard let first = path.first else {
            return .directory(url: url, modificationDate: modificationDate, children: children + [node])
        }
        guard let index = children.firstIndex(where: { $0.id == first }),
              let child = children[index].insertingDescendant(node, under: path.dropFirst()) else { return nil }
        var updated = children
        updated[index] = child
        return .directory(url: url, modificationDate: modificationDate, children: updated)
    }

    /// Follows `ids` (starting with this node's own ID) and returns the nodes found, stopping at the first missing one.
    nonisolated func nodes(along ids: [String]) -> [FileNode] {
        guard ids.first == id else { return [] }
        var result = [self]
        for id in ids.dropFirst() {
            guard let next = result.last?.children.first(where: { $0.id == id }) else { break }
            result.append(next)
        }
        return result
    }
}
