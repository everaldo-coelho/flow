import SwiftUI

/// Starts at two hours; longer saved estimates retain their full range.
struct TimeEstimateControl: View {
    @Binding var minutes: Int
    @State private var expanded = false
    private var limit: Int { expanded || minutes > 120 ? 240 : 120 }
    private func duration(_ value: Int) -> String {
        if value == 0 { return "0" }
        if value < 60 { return "\(value) min" }
        return value % 60 == 0 ? "\(value / 60)h" : "\(value / 60)h \(value % 60) min"
    }
    @ObservedObject private var language = FlowLanguageSettings.shared
    private var heading: String { language.code == "pt-BR" ? "Estimativa de tempo" : language.code == "es" ? "Tiempo estimado" : "Estimated time" }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(heading).font(.headline)
                Spacer()
                Text(duration(minutes)).font(.headline.monospacedDigit()).foregroundStyle(Color.accentColor)
            }
            VStack(spacing: 5) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.accentColor.opacity(0.12))
                        Capsule().fill(Color.accentColor)
                            .frame(width: max(5, geometry.size.width * min(1, CGFloat(minutes) / CGFloat(limit))))
                        HStack(spacing: 0) {
                            ForEach(0..<8) { index in
                                    Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .overlay(alignment: .trailing) { Rectangle().fill(Color.primary.opacity(0.16)).frame(width: 1) }
                            }
                        }
                    }.clipShape(Capsule()).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            minutes = max(5, min(limit, Int((value.location.x / max(1, geometry.size.width) * CGFloat(limit / 5)).rounded()) * 5))
                        })
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(heading)
                        .accessibilityValue(FlowL.format("%@ minutes", String(minutes)))
                        .accessibilityAdjustableAction { direction in
                            switch direction { case .increment: minutes = min(limit, (minutes / 5 + 1) * 5); case .decrement: minutes = max(5, ((minutes - 1) / 5) * 5); @unknown default: break }
                        }
                }.frame(height: 32)
                HStack { ForEach(0..<5) { tick in
                    if tick > 0 { Spacer() }
                    Text(duration(tick * limit / 4)).font(.flowCaption.monospacedDigit()).foregroundStyle(.secondary)
                }}.accessibilityHidden(true)
            }
            if minutes >= 120 && limit == 120 {
                Button {
                    expanded = true
                } label: {
                    Label(language.code == "pt-BR" ? "Adicionar mais tempo" : language.code == "es" ? "Añadir más tiempo" : "Add more time", systemImage: "plus")
                }.buttonStyle(FlowGlassButtonStyle())
            }
            HStack(spacing: 6) {
                ForEach([5, 15, 25, 45, 60], id: \.self) { value in
                    Button { minutes = value } label: {
                        Text(value >= 60 ? duration(value) : "\(value)").font(.flowCaption.monospacedDigit().weight(.medium))
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                            .background(Color.accentColor.opacity(minutes == value ? 0.25 : 0.07), in: RoundedRectangle(cornerRadius: 7))
                    }.buttonStyle(.plain)
                        .accessibilityLabel(FlowL.format("%@ minutes", String(value)))
                        .accessibilityAddTraits(minutes == value ? .isSelected : [])
                }
            }
        }.padding(.vertical, 8)
    }
}
