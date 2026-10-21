import ReadyCheckCore
import SwiftUI

struct NextEventsView: View {
    @Bindable var model: ReadyCheckAppModel
    let now: Date
    var compact = false
    var openMain: (() -> Void)?
    @State private var showResetExplanation = false
    @State private var showPace = false

    var body: some View {
        Group {
            if compact { compactContent }
            else { expandedContent }
        }
    }

    private var compactContent: some View {
        HStack(alignment: .center, spacing: 6) {
            if let event = model.nextEvents(now: now).first {
                Button { activate(event) } label: {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: event.needsAttention ? "exclamationmark.circle" : "clock")
                            .foregroundStyle(event.needsAttention ? Color.orange : Color.secondary)
                        Text((event.date.map { dateText($0, compact: true) + " · " } ?? "") + model.localization.text(event.titleKey))
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.font(.caption2).contentShape(Rectangle())
                }.buttonStyle(.plain).help(detail(event)).accessibilityLabel(accessibilityText(event))
                    .popover(isPresented: $showResetExplanation) { resetExplanation }
            }
            if let pace = model.quotaPace(now: now) {
                Button { showPace = true } label: { Image(systemName: "chart.line.uptrend.xyaxis") }
                    .buttonStyle(.plain).font(.caption2).foregroundStyle(.secondary)
                    .help(model.localization.text("pace.basis"))
                    .accessibilityLabel(model.localization.text("pace.basis"))
                    .popover(isPresented: $showPace) {
                        let view = QuotaPaceView(pace: pace, localization: model.localization, now: now)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(view.headline).font(.headline)
                            if let comparison = view.comparison {
                                Text(comparison).font(.caption).foregroundStyle(.secondary)
                            }
                            view.explanation
                        }.padding(16).frame(width: 320)
                    }
            }
        }.frame(minHeight: 24)
    }

    private var expandedContent: some View {
        let events = model.nextEvents(now: now)
        return VStack(alignment: .leading, spacing: 8) {
            Text(model.localization.text("next.title")).font(.headline)
            ForEach(events) { event in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: event.needsAttention ? "exclamationmark.circle" : "clock")
                        .foregroundStyle(event.needsAttention || event.kind == .cardWindow ? Color.orange : Color.secondary)
                    if let date = event.date {
                        Text(dateText(date)).font(.caption.weight(.medium)).monospacedDigit().frame(width: 100, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.localization.text(event.titleKey)).font(.subheadline.weight(.semibold))
                        Text(detail(event)).font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    if event.action == .reset {
                        Button(model.localization.text(event.actionKey)) { showResetExplanation = true }
                            .font(.caption).fixedSize()
                            .popover(isPresented: $showResetExplanation) { resetExplanation }
                            .accessibilityLabel(model.localization.text(event.titleKey) + " · " + model.localization.text(event.actionKey))
                    } else {
                        Button(model.localization.text(event.actionKey)) { activate(event) }
                            .font(.caption).fixedSize()
                            .accessibilityLabel(accessibilityText(event))
                    }
                }.buttonStyle(.bordered).controlSize(.small)
                    .fixedSize(horizontal: false, vertical: true)
                if event.id != events.last?.id { Divider() }
            }
            if let pace = model.quotaPace(now: now) {
                Divider()
                QuotaPaceView(pace: pace, localization: model.localization, now: now)
            }
        }
    }

    private var resetExplanation: some View {
        Text(model.localization.text("next.resetExplanation")).font(.callout)
            .fixedSize(horizontal: false, vertical: true).padding(18).frame(width: 340)
    }

    private func activate(_ event: ReadyCheckNextEvent) {
        if event.action == .reset { showResetExplanation = true }
        else { model.openNextEvent(event); openMain?() }
    }
    private func detail(_ event: ReadyCheckNextEvent) -> String {
        var text = model.localization.text(event.detailKey)
        if let expiry = event.expiration { text += " · " + model.localization.text("card.expiry") + " " + dateText(expiry) }
        return text
    }
    private func dateText(_ date: Date, compact: Bool = false) -> String {
        if compact && Calendar.current.isDate(date, inSameDayAs: now) {
            return date.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue)).hour().minute())
        }
        return date.formatted(.dateTime.locale(Locale(identifier: model.language.rawValue)).month().day().hour().minute())
    }
    private func accessibilityText(_ event: ReadyCheckNextEvent) -> String {
        (event.date.map { dateText($0) + " · " } ?? "") + model.localization.text(event.titleKey) + " · " + detail(event) + " · " + model.localization.text(event.actionKey)
    }
}
