//
//  TriviaModalView.swift
//  X-cavators
//
//  Trivia mini-game shown when player cannot afford rover repair
//

import SwiftUI

struct TriviaModalView: View {
    let questions: [TriviaQuestion]     // Exactly 2, pre-selected
    let onSuccess: () -> Void           // Called when both questions answered correctly
    let onDismiss: () -> Void           // Back to repair modal / try again

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var sessionFailed: Bool = false
    @State private var showNextButton: Bool = false
    @State private var hintRevealed: Bool = false

    private let mintAccent = Color(red: 0.2, green: 0.8, blue: 0.7)

    private var currentQuestion: TriviaQuestion {
        questions[currentQuestionIndex]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                headerView

                if sessionFailed {
                    failureView
                } else {
                    questionView
                }
            }
            .padding(30)
            .frame(maxWidth: 450)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(mintAccent, lineWidth: 3)
                    )
            )
            .shadow(color: mintAccent.opacity(0.5), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(mintAccent)

            Text("TRIVIA REPAIR")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(mintAccent)

            if !sessionFailed {
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 8) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        Circle()
                            .fill(index < currentQuestionIndex ? mintAccent :
                                  (index == currentQuestionIndex ? mintAccent.opacity(0.8) : Color.white.opacity(0.3)))
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 20) {
            Text(currentQuestion.question)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )

            // Hint button (only before answering, only if question has a hint)
            if selectedAnswerIndex == nil, let hint = currentQuestion.hint {
                if hintRevealed {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        Text(hint)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.yellow.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            hintRevealed = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 14))
                            Text("Show Hint")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.yellow.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(0..<currentQuestion.options.count, id: \.self) { index in
                    answerButton(for: index)
                }
            }

            // Fun fact shown after a correct answer
            if let selected = selectedAnswerIndex,
               selected == currentQuestion.correctAnswerIndex,
               let fact = currentQuestion.funFact {
                Text(fact)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(mintAccent.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(mintAccent.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Next/Finish button appears after correct answer
            if showNextButton {
                Button(action: advanceOrFinish) {
                    Text(currentQuestionIndex < questions.count - 1 ? "NEXT QUESTION" : "CLAIM FREE REPAIR")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(mintAccent)
                        .cornerRadius(12)
                }
                .transition(.opacity)
            }

            // Back button shown before answering
            if selectedAnswerIndex == nil {
                Button(action: onDismiss) {
                    Text("BACK TO REPAIR")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
            }
        }
    }

    // MARK: - Failure View

    private var failureView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Incorrect Answer")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.red)

            Text("The correct answer was:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text(currentQuestion.correctAnswer)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        )
                )

            if let fact = currentQuestion.funFact {
                Text(fact)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.07))
                    )
            }

            Button(action: onDismiss) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("TRY AGAIN")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(mintAccent)
                .cornerRadius(12)
            }

            Button(action: onDismiss) {
                Text("BACK TO REPAIR")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .underline()
            }
        }
    }

    // MARK: - Answer Button

    private func answerButton(for index: Int) -> some View {
        let hasAnswered = selectedAnswerIndex != nil
        let isSelected = selectedAnswerIndex == index
        let isCorrect = index == currentQuestion.correctAnswerIndex

        let bgColor: Color = {
            if !hasAnswered { return Color.white.opacity(0.08) }
            if isCorrect { return Color.green.opacity(0.3) }
            if isSelected { return Color.red.opacity(0.3) }
            return Color.white.opacity(0.04)
        }()

        let borderColor: Color = {
            if !hasAnswered { return mintAccent.opacity(0.4) }
            if isCorrect { return .green }
            if isSelected { return .red }
            return .clear
        }()

        let textColor: Color = {
            if !hasAnswered { return .white }
            if isCorrect { return .green }
            if isSelected { return .red }
            return .white.opacity(0.35)
        }()

        let letters = ["A", "B", "C", "D"]

        return Button(action: {
            guard selectedAnswerIndex == nil else { return }
            selectedAnswerIndex = index
            if index == currentQuestion.correctAnswerIndex {
                withAnimation(.easeIn(duration: 0.3)) {
                    showNextButton = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { sessionFailed = true }
                }
            }
        }) {
            HStack {
                Text(letters[index])
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            hasAnswered && isCorrect ? Color.green.opacity(0.4) :
                            (hasAnswered && isSelected ? Color.red.opacity(0.4) : mintAccent.opacity(0.2))
                        )
                    )

                Text(currentQuestion.options[index])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if hasAnswered && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                }
                if hasAnswered && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(bgColor)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
            .cornerRadius(10)
        }
        .disabled(hasAnswered)
        .animation(.easeInOut(duration: 0.25), value: selectedAnswerIndex)
    }

    // MARK: - Actions

    private func advanceOrFinish() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentQuestionIndex += 1
                selectedAnswerIndex = nil
                showNextButton = false
                hintRevealed = false
            }
        } else {
            onSuccess()
        }
    }
}
