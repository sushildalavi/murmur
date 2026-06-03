import SwiftUI
import MurmurCore

@MainActor
struct AskView: View {
    @State private var viewModel: AskViewModel
    @FocusState private var inputFocused: Bool

    init(viewModel: AskViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasMemos {
                    ContentUnavailableView(
                        "Nothing to Ask Yet",
                        systemImage: "sparkles",
                        description: Text("Record a few memos, then ask questions about them in plain language.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let answer = viewModel.answer {
                                answerCard(answer)
                            } else {
                                prompts
                            }
                        }
                        .padding()
                    }
                    .murmurGroupedScreen()
                }
            }
            .navigationTitle("Ask")
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasMemos { inputBar }
            }
        }
    }

    // MARK: Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask your memos…", text: $viewModel.question, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit(submit)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.murmurCardBackground, in: Capsule())

            Button(action: submit) {
                Image(systemName: viewModel.isAnswering ? "stop.fill" : "arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(viewModel.canAsk ? Color.murmurAccent : Color.gray.opacity(0.5), in: Circle())
            }
            .disabled(!viewModel.canAsk)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func submit() {
        inputFocused = false
        Task { await viewModel.ask() }
    }

    // MARK: Answer

    private func answerCard(_ answer: MemoAnswerService.Answer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isAnswering {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Thinking…").foregroundStyle(.secondary)
                }
            }

            MurmurCard(spacing: 12) {
                Label(answer.usedAppleIntelligence ? "Apple Intelligence" : "On-device answer",
                      systemImage: answer.usedAppleIntelligence ? "apple.intelligence" : "cpu")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.murmurAccent)

                Text(answer.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            if !answer.sources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sources")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(answer.sources) { memo in
                        NavigationLink {
                            MemoDetailView(viewModel: MemoDetailViewModel(memo: memo))
                        } label: {
                            MurmurCard {
                                HStack {
                                    MurmurMemoRow(memo: memo, snippet: memo.transcriptText)
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var prompts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask anything about your memos")
                .font(.title3.weight(.semibold))
            Text("Answers are generated entirely on device from your own recordings — retrieved by meaning, not just keywords.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                examplePrompt("What did I say I need to follow up on?")
                examplePrompt("Summarize my decisions about the release.")
                examplePrompt("What were the action items from this week?")
            }
            .padding(.top, 4)
        }
    }

    private func examplePrompt(_ text: String) -> some View {
        Button {
            viewModel.question = text
            submit()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "text.bubble")
                    .foregroundStyle(Color.murmurAccent)
                Text(text)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .font(.subheadline)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.murmurCardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
