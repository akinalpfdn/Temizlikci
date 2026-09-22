import Accessibility
import SwiftUI

/// The sunburst chart for the current folder. Click selects, double-click (or Return) opens a folder,
/// clicking the center (or Escape) goes up; arrow keys move between siblings and rings.
struct SunburstView: View {
    let model: LocationScanModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.self) private var environment

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Canvas { context, _ in draw(in: context, side: side) }
                    .id(model.currentFolder?.id)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.94).combined(with: .opacity))
                SunburstCenter(model: model, holeDiameter: side * SunburstLayout.holeFraction * 2)
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .onContinuousHover { phase in updateHover(phase, side: side) }
            .gesture(taps(side: side))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: model.currentFolder?.id)
        .focusable()
        .onKeyPress(.leftArrow) { model.selectSibling(offset: -1); return .handled }
        .onKeyPress(.rightArrow) { model.selectSibling(offset: 1); return .handled }
        .onKeyPress(.upArrow) { model.selectParentRing(); return .handled }
        .onKeyPress(.downArrow) { model.selectChildRing(); return .handled }
        .onKeyPress(.return) { model.openSelection(); return .handled }
        .onKeyPress(.escape) { model.goUp(); return .handled }
        .onKeyPress(.space) { model.quickLook(); return .handled }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(L10n.Chart.accessibilityLabel(model.currentFolder.map(model.title(for:)) ?? "")))
        .accessibilityChartDescriptor(chartDescriptor)
        .accessibilityChildren { accessibleSegments }
        .onChange(of: model.currentFolder?.id) {
            guard let folder = model.currentFolder, model.hasResult else { return }
            AccessibilityNotification.Announcement(String(localized: L10n.Chart.opened(model.title(for: folder)))).post()
        }
    }

    // MARK: Interaction

    private func updateHover(_ phase: HoverPhase, side: CGFloat) {
        let hovered: String? = switch phase {
        case .active(let point): SunburstLayout.segment(at: point, side: side, in: model.segments)?.id
        case .ended: nil
        }
        if hovered != model.hoveredID { model.hoveredID = hovered }
    }

    private func taps(side: CGFloat) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                guard let id = SunburstLayout.segment(at: value.location, side: side, in: model.segments)?.nodeID,
                      let node = model.node(withID: id) else { return }
                model.open(node)
            }
            .exclusively(before: SpatialTapGesture().onEnded { value in
                if SunburstLayout.isInHole(value.location, side: side) {
                    model.goUp()
                } else {
                    model.selectNode(withID: SunburstLayout.segment(at: value.location, side: side, in: model.segments)?.nodeID)
                }
            })
    }

    // MARK: Drawing

    private func draw(in context: GraphicsContext, side: CGFloat) {
        let radius = side / 2
        let center = CGPoint(x: radius, y: radius)
        let hovered = model.hoveredID.flatMap { id in model.segments.first { $0.id == id } }

        for segment in model.segments {
            let bounds = SunburstLayout.ringBounds(depth: segment.depth)
            let path = Self.annularSector(center: center, inner: bounds.inner * radius, outer: bounds.outer * radius,
                                          start: segment.startAngle, end: segment.endAngle)
            var layer = context
            if let hovered, !Self.isWithin(segment, hovered) { layer.opacity = 0.42 }
            fill(model.displayFill(for: segment), path: path, in: layer)
            if segment.fill != .pending {
                layer.stroke(path, with: .color(ChartPalette.surface), lineWidth: ChartPalette.segmentGap)
            }
            if let selectedID = model.selection?.id, segment.nodeID == selectedID {
                layer.stroke(path, with: .color(.primary), lineWidth: ChartPalette.segmentGap)
            }
        }
        drawLabels(in: context, center: center, radius: radius)
    }

    private func fill(_ fill: SegmentFill, path: Path, in context: GraphicsContext) {
        if let color = ChartPalette.color(for: fill, colorScheme: colorScheme) {
            context.fill(path, with: .color(color))
            return
        }
        switch fill {
        case .unattributedHatch: hatch(path, rising: true, in: context)
        case .inaccessibleHatch: hatch(path, rising: false, in: context)
        case .pending:
            context.stroke(path, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        case .slot, .neutral, .safety, .dimmed:
            break
        }
    }

    private func hatch(_ path: Path, rising: Bool, in context: GraphicsContext) {
        var clipped = context
        clipped.clip(to: path)
        clipped.fill(path, with: .color(ChartPalette.dimmed))
        let rect = path.boundingRect
        var lines = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            if rising {
                lines.move(to: CGPoint(x: x, y: rect.maxY))
                lines.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            } else {
                lines.move(to: CGPoint(x: x, y: rect.minY))
                lines.addLine(to: CGPoint(x: x + rect.height, y: rect.maxY))
            }
            x += ChartPalette.hatchSpacing
        }
        clipped.stroke(lines, with: .color(ChartPalette.hatch), lineWidth: 2)
    }

    private func drawLabels(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let bounds = SunburstLayout.ringBounds(depth: 1)
        let labelRadius = (bounds.inner + bounds.outer) / 2 * radius
        for segment in model.segments where segment.depth == 1 && segment.sweep >= ChartMetrics.labelMinimumSweep && !segment.isMerged {
            let angle = segment.midAngle - .pi / 2
            let point = CGPoint(x: center.x + labelRadius * cos(angle), y: center.y + labelRadius * sin(angle))
            let ink = labelInk(on: model.displayFill(for: segment))
            let ringThickness = (bounds.outer - bounds.inner) * radius
            let maxWidth = min(labelRadius * segment.sweep * 0.8, ringThickness * 1.9)
            let name = fittedLabel(model.title(for: segment), maxWidth: maxWidth, ink: ink, in: context)
            let size = context.resolve(Text(Formatting.bytes(segment.allocatedSize)).font(Typography.chartCaption).foregroundStyle(ink))
            guard let name, size.measure(in: CGSize(width: CGFloat.infinity, height: .infinity)).width <= maxWidth else { continue }
            context.draw(name, at: CGPoint(x: point.x, y: point.y - 7), anchor: .center)
            context.draw(size, at: CGPoint(x: point.x, y: point.y + 7), anchor: .center)
        }
    }

    /// The segment name, shortened with an ellipsis to fit `maxWidth`, or `nil` if even one character won't fit.
    private func fittedLabel(_ title: String, maxWidth: CGFloat, ink: Color, in context: GraphicsContext) -> GraphicsContext.ResolvedText? {
        var candidate = title
        while !candidate.isEmpty {
            let text = candidate == title ? candidate : candidate + "…"
            let resolved = context.resolve(Text(text).font(Typography.chartCaption.weight(.semibold)).foregroundStyle(ink))
            if resolved.measure(in: CGSize(width: CGFloat.infinity, height: .infinity)).width <= maxWidth { return resolved }
            candidate.removeLast()
        }
        return nil
    }

    private func labelInk(on fill: SegmentFill) -> Color {
        guard let color = ChartPalette.color(for: fill, colorScheme: colorScheme) else { return .primary }
        let resolved = color.resolve(in: environment)
        let luminance = 0.2126 * resolved.linearRed + 0.7152 * resolved.linearGreen + 0.0722 * resolved.linearBlue
        return luminance > 0.18 ? ChartPalette.labelOnLight : ChartPalette.labelOnDark
    }

    /// True when `segment` is the hovered segment or lies inside it on an outer ring.
    private static func isWithin(_ segment: SunburstSegment, _ hovered: SunburstSegment) -> Bool {
        if segment.id == hovered.id { return true }
        let tolerance = 1e-9
        return segment.depth > hovered.depth
            && segment.startAngle >= hovered.startAngle - tolerance
            && segment.endAngle <= hovered.endAngle + tolerance
    }

    /// A ring slice. Angles are radians clockwise from 12 o'clock; SwiftUI measures from 3 o'clock.
    static func annularSector(center: CGPoint, inner: CGFloat, outer: CGFloat, start: Double, end: Double) -> Path {
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: .radians(start - .pi / 2), endAngle: .radians(end - .pi / 2), clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: .radians(end - .pi / 2), endAngle: .radians(start - .pi / 2), clockwise: true)
        path.closeSubpath()
        return path
    }

    // MARK: Accessibility

    private var accessibleSegments: some View {
        ForEach(model.segments) { segment in
            let share = model.currentFolder.flatMap { folder in
                folder.allocatedSize > 0 ? Double(segment.allocatedSize) / Double(folder.allocatedSize) : nil
            }
            Color.clear
                .accessibilityElement()
                .accessibilityLabel(Text(model.title(for: segment)))
                .accessibilityValue(Text([Formatting.bytes(segment.allocatedSize), share.map(Formatting.percent)].compactMap { $0 }.joined(separator: ", ")))
                .accessibilityAddTraits(segment.nodeID != nil && segment.nodeID == model.selection?.id ? [.isButton, .isSelected] : .isButton)
                .accessibilityAction { model.selectNode(withID: segment.nodeID) }
                .accessibilityAction(named: Text(L10n.Chart.open)) {
                    if let id = segment.nodeID, let node = model.node(withID: id) { model.open(node) }
                }
        }
    }

    private var chartDescriptor: SunburstChartDescriptor {
        let folder = model.currentFolder
        let items = (folder?.children ?? []).filter { $0.allocatedSize > 0 }.map { (model.title(for: $0), Double($0.allocatedSize)) }
        let title = folder.map(model.title(for:)) ?? ""
        let summary = String(localized: L10n.Chart.summary(
            name: title,
            size: Formatting.bytes(folder?.allocatedSize ?? 0),
            largest: items.first?.0 ?? ""
        ))
        return SunburstChartDescriptor(title: title, summary: summary, items: items)
    }
}

/// The chart center: the focused item's name, size, and share, always visible as text.
private struct SunburstCenter: View {
    let model: LocationScanModel
    let holeDiameter: CGFloat

    var body: some View {
        if let node = model.focusNode {
            VStack(spacing: Spacing.xxSmall) {
                if model.canGoUp, let parent = model.path.dropLast().last, node.id == model.currentFolder?.id {
                    Label { Text(model.title(for: parent)) } icon: { Image(systemName: "arrow.up") }
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
                Text(model.title(for: node))
                    .font(Typography.chartCenterName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(Formatting.bytes(displayedSize(for: node)))
                    .font(Typography.chartCenterValue)
                if let caption = caption(for: node) {
                    Text(caption)
                        .font(Typography.chartCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: holeDiameter * 0.8)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(model.canGoUp ? Text(L10n.Chart.goUp(model.path.dropLast().last.map(model.title(for:)) ?? "")) : Text(model.title(for: node)))
        }
    }

    private func displayedSize(for node: FileNode) -> Int64 {
        model.isScanning && node.id == model.tree?.id ? model.progress.allocatedSize : node.allocatedSize
    }

    private func caption(for node: FileNode) -> String? {
        if node.id == model.tree?.id {
            if model.isScanning { return String(localized: L10n.Chart.measuredSoFar) }
            if let usage = model.usage { return String(localized: L10n.Chart.usedOfVolume(Formatting.bytes(usage.totalCapacity))) }
            return nil
        }
        let container = node.id == model.currentFolder?.id ? model.parent(of: node) : model.currentFolder
        guard let container, let share = model.share(of: node, in: container) else { return nil }
        return String(localized: L10n.Chart.shareOf(Formatting.percent(share), model.title(for: container)))
    }
}

/// Audio Graphs data for the chart: the current folder's items and their sizes.
private struct SunburstChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let summary: String
    let items: [(String, Double)]

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(title: String(localized: L10n.Chart.itemsAxis), categoryOrder: items.map(\.0))
        let yAxis = AXNumericDataAxisDescriptor(
            title: String(localized: L10n.Chart.sizeAxis),
            range: 0...(items.map(\.1).max() ?? 1),
            gridlinePositions: []
        ) { value in Formatting.bytes(Int64(value)) }
        let series = AXDataSeriesDescriptor(name: title, isContinuous: false, dataPoints: items.map { AXDataPoint(x: $0.0, y: $0.1) })
        return AXChartDescriptor(title: title, summary: summary, xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series])
    }
}
