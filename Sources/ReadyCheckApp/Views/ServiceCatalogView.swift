import SwiftUI
import ReadyCheckCore

struct ServiceCatalogEntry: Identifiable {
    let id: String
    let name: String
    let aliases: String
    let batch: Int
    let supported: Bool
    let summaryZH: String
    let summaryEN: String
}

enum ServiceCatalog {
    static let entries: [ServiceCatalogEntry] = [
        .init(id: "codex", name: "Codex", aliases: "OpenAI", batch: 1, supported: true, summaryZH: "订阅额度、Token 与重置卡", summaryEN: "Subscription quota, tokens and reset cards"),
        .init(id: "claude", name: "Claude", aliases: "Anthropic Claude Code", batch: 1, supported: false, summaryZH: "订阅额度与 API 统计需分别验证", summaryEN: "Subscription quota and API reporting require separate verification"),
        .init(id: "gemini", name: "Gemini", aliases: "Google 谷歌", batch: 1, supported: false, summaryZH: "CLI 与应用配额需分别验证", summaryEN: "CLI and app quota require separate verification"),
        .init(id: "deepseek", name: "DeepSeek", aliases: "深度求索", batch: 1, supported: true, summaryZH: "官方 API 余额", summaryEN: "Official API balance"),
        .init(id: "cursor", name: "Cursor", aliases: "", batch: 1, supported: false, summaryZH: "套餐用量与账单周期待验证", summaryEN: "Plan usage and billing period require verification"),
        .init(id: "copilot", name: "GitHub Copilot", aliases: "GitHub 微软", batch: 2, supported: false, summaryZH: "套餐与用量统计待验证", summaryEN: "Plan and usage reporting require verification"),
        .init(id: "bailian", name: "通义／百炼 Coding Plan", aliases: "Alibaba Qwen 阿里 千问 Bailian", batch: 2, supported: false, summaryZH: "Coding Plan 用量待验证", summaryEN: "Coding Plan usage requires verification"),
        .init(id: "glm", name: "智谱 GLM Coding Plan", aliases: "z.ai zai BigModel Zhipu", batch: 2, supported: false, summaryZH: "按地域区分的套餐额度待验证", summaryEN: "Region-specific plan quota requires verification"),
        .init(id: "kimi", name: "Kimi Code", aliases: "月之暗面 Moonshot", batch: 2, supported: false, summaryZH: "编程订阅额度待验证", summaryEN: "Coding subscription quota requires verification"),
        .init(id: "minimax", name: "MiniMax Coding Plan", aliases: "稀宇", batch: 2, supported: false, summaryZH: "编程套餐额度待验证", summaryEN: "Coding plan quota requires verification")
    ]

    static func filtered(query: String, batch: Int) -> [ServiceCatalogEntry] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return entries.filter { entry in
            (batch == 0 || entry.batch == batch) && (term.isEmpty || "\(entry.name) \(entry.aliases)".localizedCaseInsensitiveContains(term))
        }
    }
}

struct ServiceCatalogView: View {
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @Binding var query: String
    @Binding var batch: Int
    @Binding var scrollOffset: CGFloat
    let openConnectionSettings: (ServiceSettingsTarget) -> Void
    @State private var selected: ServiceCatalogEntry?
    private func text(_ zh: String, _ en: String) -> String { language == .zhCN ? zh : en }
    private func name(_ entry: ServiceCatalogEntry) -> String {
        guard language != .zhCN else { return entry.name }
        switch entry.id {
        case "bailian": return "Alibaba / Bailian Coding Plan"
        case "glm": return "GLM Coding Plan"
        default: return entry.name
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(text("管理连接", "Manage connections")).font(.title2.weight(.semibold))
                Spacer()
                Button(text("关闭", "Close")) { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Divider()
            if let selected {
                detail(selected)
            } else {
                catalog
            }
        }
        .padding(24)
        .frame(width: 660, height: 580)
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text("目标服务分两批接入；待接入的服务不会显示虚构数据。", "Target services are planned in two batches. Unavailable services do not show invented data."))
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                TextField(text("搜索服务", "Search services"), text: $query)
                    .textFieldStyle(.roundedBorder)
                Picker(text("开发批次", "Development batch"), selection: $batch) {
                    Text(text("全部服务", "All services")).tag(0)
                    Text(text("第一批", "First batch")).tag(1)
                    Text(text("第二批", "Second batch")).tag(2)
                }.labelsHidden().frame(width: 150)
            }
            let results = ServiceCatalog.filtered(query: query, batch: batch)
            Text(text("\(results.count) 个服务 · 按开发批次排序", "\(results.count) services · Ordered by batch"))
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            if results.isEmpty {
                VStack(spacing: 8) {
                    Text(text("没有找到匹配的服务", "No matching services"))
                    Button(text("清除筛选", "Clear filters")) { query = ""; batch = 0 }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { entry in
                            Button {
                                if entry.supported {
                                    dismiss()
                                    openConnectionSettings(entry.id == "deepseek" ? .deepSeek : .codex)
                                } else { selected = entry }
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(name(entry)).font(.headline)
                                        Text(text(entry.summaryZH, entry.summaryEN)).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(entry.supported ? text("已支持", "Supported") : text("待接入", "Planned"))
                                            .font(.caption).foregroundStyle(.secondary)
                                        Text((entry.supported ? text("管理连接", "Manage connection") : text("查看接入", "View details")) + "  ›").foregroundStyle(.tint)
                                    }
                                }.padding(.vertical, 12).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .background(MainScrollPosition(identity: "catalog", offset: $scrollOffset))
                }
            }
        }.frame(maxHeight: .infinity, alignment: .top)
    }

    private func detail(_ entry: ServiceCatalogEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(text("‹ 返回服务目录", "‹ Back to services")) { selected = nil }.buttonStyle(.link)
            Text(name(entry)).font(.title2.weight(.semibold))
            Text(entry.supported ? text("已支持", "Supported") : text("待接入 · 读取方式与权限尚待验证", "Planned · Source and permissions not yet verified"))
                .font(.callout).foregroundStyle(.secondary)
            Text(text(entry.summaryZH, entry.summaryEN))
            if entry.supported {
                Text(entry.id == "deepseek" ? text("只读取官方 API 余额；不将余额变化当作费用。", "Reads the official API balance only; balance changes are not necessarily expenses.") : text("保留现有 Codex 连接、用量和重置卡功能。", "Existing Codex connection, usage and reset-card features are retained."))
                    .foregroundStyle(.secondary)
                Button(text("打开连接设置", "Open connection settings")) { dismiss(); openConnectionSettings(entry.id == "deepseek" ? .deepSeek : .codex) }
                    .buttonStyle(.borderedProminent)
            } else {
                Text(text("正式接入前需分别核实账号范围、权限和可读取字段。", "Account scope, permissions and available fields must be verified before integration."))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
