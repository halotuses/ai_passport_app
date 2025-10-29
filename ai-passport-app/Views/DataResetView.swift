import SwiftUI

struct DataResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressManager: ProgressManager

    @State private var showResetConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    @State private var units = ResetHierarchyLoader.loadUnits()
    @State private var expandedUnitIds: Set<String> = []
    @State private var isProblemSectionExpanded = true
    @State private var isProgressSectionExpanded = false
    @State private var isBookmarkSectionExpanded = false

    @State private var isProblemDataEnabled = false
    @State private var selectedChapters: Set<ProgressChapterIdentifier> = []
    @State private var isProgressFiltersEnabled = false
    @State private var selectedStatuses: Set<QuestionStatus> = []
    @State private var shouldDeleteBookmarks = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                infoCard

                selectionCard

                resetSection
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(subtlePaperBackground.ignoresSafeArea())
        .navigationTitle("データリセット")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "リセットを実行しますか？",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除を実行", role: .destructive) { performDataReset() }
            Button("キャンセル", role: .cancel) { }

        } message: {
            Text("選択したデータは完全に削除されます。この操作は取り消せません。")
        }
        .alert("エラー", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }


        .onAppear {
            synchronizeSelectionsWithAvailableUnits()
        }
        .onChange(of: units) { _ in
            synchronizeSelectionsWithAvailableUnits()
        }
        .onChange(of: selectedChapters) { _ in
            if isProblemDataEnabled && selectedChapters.isEmpty {
                isProblemDataEnabled = false
            }
        }
        .onChange(of: isProblemDataEnabled) { newValue in
            if newValue && selectedChapters.isEmpty {
                selectedChapters = allChapterSelections
            }
        }
        .onChange(of: isProgressFiltersEnabled) { newValue in
            if newValue && selectedStatuses.isEmpty {
                selectedStatuses = Set(QuestionStatus.allCases)
            }
        }
    }
}
    
private extension DataResetView {
    var infoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.themeIncorrect, Color.themeSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("学習データのリセット")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.themeTextPrimary)

                    Text("選択した回答履歴や進捗状況、ブックマークを削除できます。削除されたデータは元に戻せません。")
                        .font(.body)
                        .foregroundColor(.themeTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.25))

            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("必要な項目だけを選択してリセットできます。")
                        .foregroundColor(.themeTextPrimary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.themeSecondary)
                }

                Label {
                    Text("実行する前に内容を確認し、十分ご注意ください。")
                        .foregroundColor(.themeTextPrimary)
                } icon: {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .font(.subheadline)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.4), radius: 18, x: 0, y: 12)
    }

    var selectionCard: some View {
          VStack(alignment: .leading, spacing: 24) {
              Text("削除するデータを選択")
                  .font(.headline)
                  .foregroundColor(.themeTextPrimary)

              VStack(spacing: 16) {
                  problemDataSection

                  Divider()
                      .overlay(Color.white.opacity(0.2))

                  progressSection

                  Divider()
                      .overlay(Color.white.opacity(0.2))

                  bookmarkSection
              }
          }
          .padding(24)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
              RoundedRectangle(cornerRadius: 24, style: .continuous)
                  .fill(
                      LinearGradient(
                          colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt.opacity(0.92)],
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing
                      )
                  )
          )
          .overlay(
              RoundedRectangle(cornerRadius: 24, style: .continuous)
                  .stroke(Color.white.opacity(0.22), lineWidth: 1)
          )
          .shadow(color: Color.themeShadowSoft.opacity(0.32), radius: 14, x: 0, y: 10)
      }

      var problemDataSection: some View {
          DisclosureGroup(isExpanded: $isProblemSectionExpanded) {
              VStack(alignment: .leading, spacing: 14) {
                  if isProblemDataEnabled {
                      ForEach(units) { unit in
                          unitSection(for: unit)
                      }

                      Toggle(isOn: selectAllBinding) {
                          VStack(alignment: .leading, spacing: 2) {
                              Text("全選択")
                                  .font(.subheadline.weight(.semibold))
                                  .foregroundColor(.themeTextPrimary)
                              Text("すべての章と単元を対象に含めます")
                                  .font(.caption)
                                  .foregroundColor(.themeTextSecondary)
                          }
                      }
                      .toggleStyle(CheckboxToggleStyle())
                      .padding(.leading, 4)
                  } else {
                      Text("チェックを入れると、章や単元ごとに削除対象を選べます。")
                          .font(.footnote)
                          .foregroundColor(.themeTextSecondary)
                          .padding(.leading, 4)
                  }
              }
              .padding(.top, 6)
          } label: {
              HStack(spacing: 12) {
                  CheckboxLabel(
                      isOn: isProblemDataEnabled,
                      title: "問題データ",
                      subtitle: "章や単元ごとに学習履歴を削除"
                  ) {
                      toggleProblemData()
                  }

                  Spacer(minLength: 8)

                  ChevronButton(isExpanded: isProblemSectionExpanded) {
                      withAnimation(.easeInOut) {
                          isProblemSectionExpanded.toggle()
                      }
                  }
              }
              .contentShape(Rectangle())
          }
      }

      var progressSection: some View {
          DisclosureGroup(isExpanded: $isProgressSectionExpanded) {
              VStack(alignment: .leading, spacing: 12) {
                  if isProgressFiltersEnabled {
                      ForEach(ProgressStatusOption.allCases) { option in
                          Toggle(isOn: Binding(
                              get: { selectedStatuses.contains(option.status) },
                              set: { isOn in
                                  updateStatusSelection(for: option.status, isOn: isOn)
                              }
                          )) {
                              VStack(alignment: .leading, spacing: 2) {
                                  Text(option.title)
                                      .font(.subheadline.weight(.semibold))
                                      .foregroundColor(.themeTextPrimary)
                                  Text(option.subtitle)
                                      .font(.caption)
                                      .foregroundColor(.themeTextSecondary)
                              }
                          }
                          .toggleStyle(CheckboxToggleStyle())
                      }
                  } else {
                      Text("正解・不正解・未回答など、進捗の状態を個別に削除できます。")
                          .font(.footnote)
                          .foregroundColor(.themeTextSecondary)
                          .padding(.leading, 4)
                  }
              }
              .padding(.top, 6)
          } label: {
              HStack(spacing: 12) {
                  CheckboxLabel(
                      isOn: isProgressFiltersEnabled,
                      title: "進捗ごと",
                      subtitle: "正解・不正解・未回答を選択"
                  ) {
                      toggleProgressFilters()
                  }

                  Spacer(minLength: 8)

                  ChevronButton(isExpanded: isProgressSectionExpanded) {
                      withAnimation(.easeInOut) {
                          isProgressSectionExpanded.toggle()
                      }
                  }
              }
              .contentShape(Rectangle())
          }
      }

      var bookmarkSection: some View {
          DisclosureGroup(isExpanded: $isBookmarkSectionExpanded) {
              Text("保存しているすべてのブックマークを削除します。")
                  .font(.footnote)
                  .foregroundColor(.themeTextSecondary)
                  .padding(.top, 6)
                  .padding(.leading, 4)
          } label: {
              HStack(spacing: 12) {
                  CheckboxLabel(
                      isOn: shouldDeleteBookmarks,
                      title: "ブックマーク",
                      subtitle: "保存した問題を削除"
                  ) {
                      shouldDeleteBookmarks.toggle()
                  }

                  Spacer(minLength: 8)

                  ChevronButton(isExpanded: isBookmarkSectionExpanded) {
                      withAnimation(.easeInOut) {
                          isBookmarkSectionExpanded.toggle()
                      }
                  }
              }
              .contentShape(Rectangle())
          }
      }

      var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { showResetConfirmation = true }) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("学習データをリセット")
                            .font(.headline)
                        Text("選択した項目を削除します")
                            .font(.subheadline)
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.themeIncorrect,
                                    Color.themeIncorrect.opacity(0.85),
                                    Color.themeIncorrect.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.themeIncorrect.opacity(0.28), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(!canPerformReset || isProcessing)
            .opacity((!canPerformReset || isProcessing) ? 0.75 : 1.0)

            VStack(alignment: .leading, spacing: 8) {
                Text("※ この操作は取り消せません")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.themeIncorrect)

                Text("リセット後は、削除した学習データを復元できません。実行前に選択内容を再度ご確認ください。")
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var selectAllBinding: Binding<Bool> {
        Binding(
            get: {
                let available = allChapterSelections
                guard !available.isEmpty else { return false }
                return selectedChapters.isSuperset(of: available)
            },
            set: { isOn in
                if isOn {
                    selectedChapters = allChapterSelections
                } else {
                    selectedChapters.removeAll()
                }
            }
        )
    }

    func unitSection(for unit: ResetHierarchyLoader.Unit) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expandedUnitIds.contains(unit.id) },
            set: { isExpanded in
                withAnimation(.easeInOut) {
                    if isExpanded {
                        expandedUnitIds.insert(unit.id)
                    } else {
                        expandedUnitIds.remove(unit.id)
                    }
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(unit.chapters) { chapter in
                    Toggle(isOn: Binding(
                        get: {
                            let identifier = ProgressChapterIdentifier(unitId: unit.id, chapterId: chapter.id)
                            return selectedChapters.contains(identifier)
                        },
                        set: { isOn in
                            let identifier = ProgressChapterIdentifier(unitId: unit.id, chapterId: chapter.id)
                            if isOn {
                                selectedChapters.insert(identifier)
                            } else {
                                selectedChapters.remove(identifier)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chapter.title.isEmpty ? chapter.id : chapter.title)
                                .font(.subheadline)
                                .foregroundColor(.themeTextPrimary)
                            Text(chapter.id)
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary)
                        }
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.leading, 32)
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 12) {
                TriStateCheckbox(
                    state: unitCheckboxState(for: unit),
                    title: unit.title.isEmpty ? unit.id : unit.title,
                    subtitle: unit.id
                ) {
                    toggleUnitSelection(unit)
                }

                Spacer(minLength: 8)

                ChevronButton(isExpanded: expandedUnitIds.contains(unit.id)) {
                    let isExpanded = expandedUnitIds.contains(unit.id)
                    withAnimation(.easeInOut) {
                        if isExpanded {
                            expandedUnitIds.remove(unit.id)
                        } else {
                            expandedUnitIds.insert(unit.id)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }

    func unitCheckboxState(for unit: ResetHierarchyLoader.Unit) -> TriStateCheckbox.State {
        let identifiers = Set(unit.chapters.map { ProgressChapterIdentifier(unitId: unit.id, chapterId: $0.id) })
        let intersectionCount = identifiers.intersection(selectedChapters).count

        if intersectionCount == 0 {
            return .off
        } else if intersectionCount == identifiers.count {
            return .on
        } else {
            return .indeterminate
        }
    }

    func toggleUnitSelection(_ unit: ResetHierarchyLoader.Unit) {
        let identifiers = Set(unit.chapters.map { ProgressChapterIdentifier(unitId: unit.id, chapterId: $0.id) })
        let currentCount = identifiers.intersection(selectedChapters).count

        if currentCount == identifiers.count {
            selectedChapters.subtract(identifiers)
        } else {
            selectedChapters.formUnion(identifiers)
        }
    }

    func toggleProblemData() {
        withAnimation(.easeInOut) {
            isProblemDataEnabled.toggle()
            if isProblemDataEnabled {
                if selectedChapters.isEmpty {
                    selectedChapters = allChapterSelections
                }
            } else {
                selectedChapters.removeAll()
            }
        }
    }

    func toggleProgressFilters() {
        withAnimation(.easeInOut) {
            isProgressFiltersEnabled.toggle()
            if isProgressFiltersEnabled {
                if selectedStatuses.isEmpty {
                    selectedStatuses = Set(QuestionStatus.allCases)
                }
            } else {
                selectedStatuses.removeAll()
            }
        }
    }

    func updateStatusSelection(for status: QuestionStatus, isOn: Bool) {
        if isOn {
            selectedStatuses.insert(status)
        } else {
            selectedStatuses.remove(status)
            if selectedStatuses.isEmpty {
                isProgressFiltersEnabled = false
            }
        }
    }

    var canPerformReset: Bool {
        let chapters = isProblemDataEnabled ? selectedChapters.intersection(allChapterSelections) : Set<ProgressChapterIdentifier>()
        let hasChapterSelection = !chapters.isEmpty
        let hasProgressSelection = isProgressFiltersEnabled && !selectedStatuses.isEmpty
        return hasChapterSelection || hasProgressSelection || shouldDeleteBookmarks
    }

    var allChapterSelections: Set<ProgressChapterIdentifier> {
        Set(
            units.flatMap { unit in
                unit.chapters.map { chapter in
                    ProgressChapterIdentifier(unitId: unit.id, chapterId: chapter.id)
                }
            }
        )
    }

    func synchronizeSelectionsWithAvailableUnits() {
        let available = allChapterSelections
        if available.isEmpty {
            selectedChapters.removeAll()
            isProblemDataEnabled = false
        } else {
            let filtered = selectedChapters.intersection(available)
            if filtered != selectedChapters {
                selectedChapters = filtered
            }
            if isProblemDataEnabled && selectedChapters.isEmpty {
                isProblemDataEnabled = false
            }
        }
    }

    func performDataReset() {
        guard !isProcessing else { return }
        isProcessing = true

        let available = allChapterSelections
        let chaptersToDelete: Set<ProgressChapterIdentifier>
        if isProblemDataEnabled {
            chaptersToDelete = selectedChapters.intersection(available)
        } else {
            chaptersToDelete = []
        }

        var statusesToDelete: Set<QuestionStatus> = []
        if isProgressFiltersEnabled {
            statusesToDelete = selectedStatuses.isEmpty ? Set(QuestionStatus.allCases) : selectedStatuses
        }

        let shouldDeleteProgress = !chaptersToDelete.isEmpty || isProgressFiltersEnabled

        do {
            if shouldDeleteProgress {
                try progressManager.repository.deleteProgress(
                    for: chaptersToDelete,
                    statuses: statusesToDelete
                )
            }

            if shouldDeleteBookmarks {
                try progressManager.repository.deleteAllBookmarks()
            }

            progressManager.homeProgressViewModel.refresh()
            isProcessing = false
            dismiss()
        } catch {
            errorMessage = "データのリセットに失敗しました。\n\(error.localizedDescription)"
            isProcessing = false
            showErrorAlert = true
        }
    }

    var subtlePaperBackground: some View {
        LinearGradient(
            colors: [
                Color.themeBase,
                Color.themeBase.opacity(0.98),
                Color.themeSurfaceElevated.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Color.white
                .opacity(0.04)
        )
    }
}
// MARK: - Support Views

private struct CheckboxLabel: View {
    let isOn: Bool
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isOn ? Color.themeMain : Color.themeTextSecondary.opacity(0.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeTextPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ChevronButton: View {
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.down")
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.themeTextSecondary.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TriStateCheckbox: View {
    enum State {
        case on
        case off
        case indeterminate
    }

    let state: State
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: imageName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(foregroundColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeTextPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var imageName: String {
        switch state {
        case .on:
            return "checkmark.square.fill"
        case .off:
            return "square"
        case .indeterminate:
            return "minus.square.fill"
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .on:
            return Color.themeMain
        case .off:
            return Color.themeTextSecondary.opacity(0.6)
        case .indeterminate:
            return Color.themeSecondary
        }
    }
}

private struct ProgressStatusOption: Identifiable {
    let id = UUID()
    let status: QuestionStatus
    let title: String
    let subtitle: String

    static let allCases: [ProgressStatusOption] = [
        ProgressStatusOption(
            status: .correct,
            title: "正解データのみ削除",
            subtitle: "正解済みの履歴をリセット"
        ),
        ProgressStatusOption(
            status: .incorrect,
            title: "不正解データのみ削除",
            subtitle: "間違えた問題の履歴をリセット"
        ),
        ProgressStatusOption(
            status: .unanswered,
            title: "未回答データのみ削除",
            subtitle: "未回答として保存されている履歴をリセット"
        )
    ]
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(configuration.isOn ? Color.themeMain : Color.themeTextSecondary.opacity(0.6))

                configuration.label
                    .foregroundColor(.themeTextPrimary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ResetHierarchyLoader {
    struct Unit: Identifiable, Equatable {
        let id: String
        let title: String
        let chapters: [ChapterMetadata]
    }

    private static let decoder = JSONDecoder()

    static func loadUnits(bundle: Bundle = .main) -> [Unit] {
        guard let metadataData = data(forResourcePath: "quizzes/metadata/quizzes_metadata.json", bundle: bundle),
              let metadata = try? decoder.decode(QuizMetadataMap.self, from: metadataData) else {
            return []
        }

        return metadata
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { unitId, info -> Unit in
                let chapters: [ChapterMetadata]
                if let chapterData = data(forResourcePath: info.file, bundle: bundle),
                   let chapterList = try? decoder.decode(ChapterList.self, from: chapterData) {
                    chapters = chapterList.chapters
                } else {
                    chapters = []
                }
                return Unit(id: unitId, title: info.title, chapters: chapters)
            }
    }

    private static func data(forResourcePath path: String, bundle: Bundle) -> Data? {
        let cleanedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = cleanedPath.split(separator: "/")
        guard let fileComponent = components.last else { return nil }
        let directoryComponents = components.dropLast()

        let fileParts = fileComponent.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard fileParts.count == 2 else { return nil }

        let resourceName = String(fileParts[0])
        let fileExtension = String(fileParts[1])
        let subdirectory = directoryComponents.joined(separator: "/")

        let candidateBundles: [Bundle]
        if bundle === Bundle.main {
            candidateBundles = [bundle, Bundle(for: BundleToken.self)]
        } else {
            candidateBundles = [bundle]
        }

        for candidate in candidateBundles {
            if let url = candidate.url(forResource: resourceName, withExtension: fileExtension, subdirectory: subdirectory) {
                if let data = try? Data(contentsOf: url) {
                    return data
                }
            }
        }

        return nil
    }

    private final class BundleToken {}
}
#Preview {
    NavigationStack {
        DataResetView()
            .environmentObject(ProgressManager())
    }
}
